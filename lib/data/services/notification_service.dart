import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/schedule.dart';
import '../../domain/repositories/repositories.dart';

/// 日程提醒服务（P0-2）。
///
/// 三层可靠性设计：
/// 1. 插件层：zonedSchedule 排精确闹钟（exactAllowWhileIdle）
/// 2. 原生持久层：MethodChannel 把计划同步到 Android SharedPreferences，
///    BootReceiver 在 重启/更新/时间变更/时区变更/日期变更 后重建
/// 3. App 启动层：syncAll() 重建全部未来提醒（uhabits #1509 社区公认兜底）
///
/// 失败必须可见：返回 warnings 列表给 UI 展示"提醒未生效"，不静默。
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _channel = MethodChannel('trinity/alarms');
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    // 时区跟随系统，不写死 Asia/Shanghai
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_systemTimeZoneId()));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
    _inited = true;
  }

  /// 读系统时区 id。中国大陆用 Asia/Shanghai；其他区域按 offset 匹配时区库。
  static String _systemTimeZoneId() {
    final now = DateTime.now();
    final offsetMinutes = now.timeZoneOffset.inMinutes;
    if (offsetMinutes == 480) return 'Asia/Shanghai';
    for (final name in tz.timeZoneDatabase.locations.keys) {
      final loc = tz.getLocation(name);
      final t = tz.TZDateTime.from(now, loc);
      if (t.timeZoneOffset == now.timeZoneOffset) return name;
    }
    return 'UTC';
  }

  Future<bool> canExact() async {
    try {
      return await _channel.invokeMethod<bool>('canExact') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 重建未来 14 天全部提醒。返回警告（UI 显示"提醒未生效"）。
  Future<List<String>> syncAll(ScheduleRepository repo) async {
    final warnings = <String>[];
    if (!_inited) await init();

    // 先清空插件层已排定的全部通知：删除/跳过的日程到点不再弹（幽灵通知）
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // 初次安装无已排通知时个别设备抛异常，忽略
    }

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 15));
    final fromDay = from.year * 10000 + from.month * 100 + from.day;
    final toDay = to.year * 10000 + to.month * 100 + to.day;

    final instances = await _rangeInstances(repo, fromDay, toDay);
    final pending = instances
        .where(
          (i) =>
              i.status == BlockStatus.pending &&
              i.remindAt != null &&
              i.remindAt!.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));

    final exactOk = await canExact();
    if (!exactOk) {
      warnings.add('未授予精确闹钟权限，提醒可能延迟（设置页可跳转授权）');
    }

    // 插件层 + 原生持久层双写
    final nativePayloads = <Map<String, dynamic>>[];
    for (final i in pending.take(64)) {
      final epochMs = i.remindAt!.millisecondsSinceEpoch;
      try {
        await _plugin.zonedSchedule(
          i.id,
          i.title,
          '${_hm(i.startMinutes)} · ${i.title}',
          tz.TZDateTime.from(
            DateTime.fromMillisecondsSinceEpoch(epochMs),
            tz.local,
          ),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'trinity_schedule',
              '日程提醒',
              channelDescription: '日程时间块提醒',
              importance: Importance.max,
              priority: Priority.high,
              fullScreenIntent: true,
            ),
          ),
          androidScheduleMode: exactOk
              ? AndroidScheduleMode.exactAllowWhileIdle
              // 降级：宁可延迟不可崩溃；UI 明确提示
              : AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        warnings.add('「${i.title}」提醒排定失败：$e');
      }
      nativePayloads.add({
        'id': i.id,
        'title': i.title,
        'body': '${_hm(i.startMinutes)} · ${i.title}',
        'epochMs': epochMs,
      });
    }

    try {
      await _channel.invokeMethod('setAll', {'alarms': nativePayloads});
    } on PlatformException catch (e) {
      warnings.add('提醒持久化失败（重启后不会自动恢复）：${e.code}');
    }
    return warnings;
  }

  Future<List<ScheduleInstance>> _rangeInstances(
    ScheduleRepository repo,
    int fromDay,
    int toDay,
  ) async {
    // repo 是 Stream 接口，这里用一次性查询封装
    final completer = Completer<List<ScheduleInstance>>();
    late StreamSubscription sub;
    sub = repo.watchRange(fromDay, toDay).listen((list) {
      if (!completer.isCompleted) completer.complete(list);
    });
    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  static String _hm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 立即发一条测试通知（设置页验证通知渠道）
  Future<void> testNow() async {
    if (!_inited) await init();
    await _plugin.show(
      999999,
      '三位一体 · 测试提醒',
      '如果你看到这条通知，说明日程提醒渠道正常',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trinity_schedule', '日程提醒',
          channelDescription: '日程时间块提醒',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
