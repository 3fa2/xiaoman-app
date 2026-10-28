import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';
import '../domain/models/diary.dart';
import '../domain/models/schedule.dart';
import '../domain/models/todo.dart';
import '../features/todo/todo_add_sheet.dart';
import 'router.dart';

/// 桌面小组件同步桥（v5.0.3，channel：trinity/widget）。
///
/// 数据流（替代 v5.0.0 的 SQLite 直读方案）：
/// 1. 订阅待办数据变化 → 通过 channel 推送 JSON 到原生 SharedPreferences
/// 2. 接收小组件勾选回调 → 执行真正的 toggle → 数据变化回流自动推新数据
/// 3. App 启动时 drainPending → 同步 App 没运行时小组件标记的勾选
/// 4. 接收小组件入口动作：[+] → 待办页并弹添加框；整块 → 待办页
class WidgetSync {
  static const _ch = MethodChannel('trinity/widget');
  static StreamSubscription<dynamic>? _sub;
  static StreamSubscription<dynamic>? _schedSub;
  static StreamSubscription<dynamic>? _diarySub;
  static Timer? _dayRollover;
  static int _schedDay = 0;

  /// main bootstrap 里挂一次：订阅数据 + 注册原生回调
  static void attach(WidgetRef ref) {
    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openAction':
          _handleAction(ref, call.arguments as String?);
          break;
        case 'widgetToggle':
          // 小组件勾选回调：执行真正的 toggle
          final id = call.arguments as int?;
          if (id != null) {
            await _doToggle(ref, id);
          }
          break;
        case 'moodPick':
          // v5.8：心情打卡小组件回调（App 在运行时原生直接推 id）
          final moodId = (call.arguments as num?)?.toInt();
          if (moodId != null && moodId > 0) {
            await _applyMoodPick(ref, moodId);
            await _afterMoodSync(ref);
          }
          break;
      }
    });
    _sub?.cancel();
    _sub = ref.read(todoRepoProvider).watchAll().distinct().listen((todos) {
      _pushTodos(todos);
      // 待办变化 → 提醒全量重建
      unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());
    });
    // v5.8：心情打卡小组件——订阅日记变化，把「今天的心情」推给原生
    _diarySub?.cancel();
    _diarySub = ref
        .read(diaryRepoProvider)
        .watchAll()
        .distinct()
        .listen(_pushTodayMood);
    // v5.3：今日日程小组件——订阅今天的日程变化（含 regenerate 插入实例）
    final now = DateTime.now();
    _resubscribeSchedule(
      ref,
      now.year * 10000 + now.month * 100 + now.day,
    );
    // 进程跨天存活时换订阅目标（否则一直看昨天，小组件整天显示「—」）；
    // 5 分钟粒度：跨天重订阅最多延迟几分钟，代价可忽略
    _dayRollover?.cancel();
    _dayRollover = Timer.periodic(const Duration(minutes: 5), (_) {
      final n = DateTime.now();
      final today = n.year * 10000 + n.month * 100 + n.day;
      if (today != _schedDay) {
        _resubscribeSchedule(ref, today);
        // v5.8：跨天后重推今天的心情（原生缓存按日期自动失效，这里补渲染）
        unawaited(_pushTodayMoodSnapshot(ref));
      }
    });
  }

  static void _resubscribeSchedule(WidgetRef ref, int todayDay) {
    _schedDay = todayDay;
    _schedSub?.cancel();
    _schedSub = ref
        .read(scheduleRepoProvider)
        .watchDay(todayDay)
        .distinct()
        .listen((blocks) => _pushSchedule(blocks, todayDay));
  }

  /// 冷启动补取：engine 就绪前原生把动作暂存在 launchAction
  static Future<void> drainLaunchAction(WidgetRef ref) async {
    try {
      final action = await _ch.invokeMethod<String>('getLaunchAction');
      // await：深链导航里查库失败要能被这里的 catch 兜住（此前 Future 被丢弃）
      if (action != null) await _handleAction(ref, action);
    } catch (_) {}

    // 同步 App 没运行时小组件标记的勾选。
    // pending 队列只记「翻转为完成」的 id（勾了又取消的已被原生侧移除），
    // 所以统一落为 done=true；重复/不存在的 id 幂等无害。
    try {
      final ids = await _ch.invokeMethod<List<dynamic>>('drainPending');
      if (ids != null && ids.isNotEmpty) {
        final repo = ref.read(todoRepoProvider);
        for (final id in ids) {
          await repo.toggle(id: (id as num).toInt(), done: true);
        }
      }
    } catch (_) {}

    // v5.8：同步 App 没运行时小组件的心情打卡（逐条落库后统一回推权威值）
    try {
      final moods = await _ch.invokeMethod<List<dynamic>>('drainPendingMoods');
      if (moods != null && moods.isNotEmpty) {
        for (final m in moods) {
          final moodId = (m as num?)?.toInt() ?? 0;
          if (moodId > 0) await _applyMoodPick(ref, moodId);
        }
        await _afterMoodSync(ref);
      }
    } catch (_) {}
  }

  static Future<void> _doToggle(WidgetRef ref, int id) async {
    // 小组件只显示未完成列表，勾选必为「标记完成」；
    // 若之后在 App 内取消勾选，watchAll 回流会自动修正小组件
    await ref.read(todoRepoProvider).toggle(id: id, done: true);
  }

  static void _pushTodos(List<Todo> todos) {
    // 只推未完成的（小组件只显示未完成列表，截断 8 条）；
    // count 单独推真实未完成总数——否则 9 条以上时小组件大数字永远显示 8
    final open = todos.where((t) => !t.done).toList();
    final json = jsonEncode(
      open
          .take(8)
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'done': false,
                // v5.8：截止日 yyyymmdd（无期限传 0，原生视为 null）
                'dueDay': t.dueDay ?? 0,
              })
          .toList(),
    );
    _ch.invokeMethod<void>('updateTodos', {
      'todos': json,
      'count': open.length,
    }).catchError((_) {});
  }

  /// v5.3：推今日日程给小组件（接下来 3 条 + 剩余数）
  static void _pushSchedule(List<ScheduleInstance> blocks, int todayDay) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final upcoming = blocks
        .where((b) => b.status == BlockStatus.pending && b.endMinutes >= nowMinutes)
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final json = jsonEncode(
      upcoming
          .take(3)
          .map((b) => {
                'time':
                    '${(b.startMinutes ~/ 60).toString().padLeft(2, '0')}:${(b.startMinutes % 60).toString().padLeft(2, '0')}',
                'title': b.title,
                'done': false,
              })
          .toList(),
    );
    _ch.invokeMethod<void>('updateSchedule', {
      'schedule': json,
      'remaining': upcoming.length,
      'dateDay': todayDay,
    }).catchError((_) {});
  }

  /// v5.8：把「今天的心情」推给心情打卡小组件。
  /// 复用 home 的读取语义：当天最新创建且带心情的一篇作为当日心情；没有则推 -1。
  static void _pushTodayMood(List<Diary> diaries) {
    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;
    final withMood = diaries
        .where((d) => d.dateDay == today && d.moodId != null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final moodId = withMood.isEmpty ? -1 : withMood.first.moodId!;
    _ch.invokeMethod<void>('updateMood', {'moodId': moodId}).catchError((_) {});
  }

  /// v5.8：一次性取全量日记再推今天的心情（跨天兜底 / 打卡落库后回推用）
  static Future<void> _pushTodayMoodSnapshot(WidgetRef ref) async {
    try {
      final diaries = await ref.read(diaryRepoProvider).watchAll().first;
      _pushTodayMood(diaries);
    } catch (_) {}
  }

  /// v5.8：小组件打卡落库。语义：给今天最新一篇「没有心情」的日记打上该心情；
  /// 今天没有这种日记则新建一条只有心情的日记（与 home 的写入兜底同方向）。
  static Future<void> _applyMoodPick(WidgetRef ref, int moodId) async {
    final repo = ref.read(diaryRepoProvider);
    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;
    final diaries = await repo.watchAll().first;
    final todays = diaries.where((d) => d.dateDay == today).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // 写入目标必须与展示/回推一致（同 home 的教训 v5.0.4）：
    // 读取语义 = 今天最新一篇带心情的日记。这里优先改它的心情，
    // 其次是最新一篇无心情的，都没有才新建——否则回推的权威值
    // 仍算出旧日记的心情，小组件圆点圈会「弹回去」像没反应。
    final withMood = todays.where((d) => d.moodId != null).toList();
    final noMood = todays.where((d) => d.moodId == null).toList();
    final int diaryId;
    if (withMood.isNotEmpty) {
      diaryId = withMood.first.id;
    } else if (noMood.isNotEmpty) {
      diaryId = noMood.first.id;
    } else {
      diaryId = await repo.save(
          id: null, title: '', content: '', extra: null, dateDay: today);
    }
    await repo.setMood(diaryId: diaryId, moodId: moodId);
    // 原生侧 todayMoodId 的权威值以 Flutter 推送为准（顺带触发原生刷新）
    _ch.invokeMethod<void>('updateMood', {'moodId': moodId}).catchError((_) {});
  }

  /// v5.8：打卡落库后的统一收尾：重推今天的心情 + 提醒全量重建（已写日记文案）
  static Future<void> _afterMoodSync(WidgetRef ref) async {
    await _pushTodayMoodSnapshot(ref);
    try {
      await ref.read(reminderWarningsProvider.notifier).syncNow();
    } catch (_) {}
  }

  static Future<void> _handleAction(WidgetRef ref, String? action) async {
    if (action == null) return;
    final ctx = rootKey.currentContext;
    if (ctx == null) return;
    switch (action) {
      case 'todo':
      case 'todo_add':
        ctx.go('/todo');
        if (action != 'todo_add') return;
        final gate = ref.read(lockGateProvider);
        if (gate.required && !gate.unlocked) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final c = rootKey.currentContext;
          if (c != null) showTodoAddSheet(c);
        });
      case 'diary':
        // 写日记提醒/快捷方式：直达编辑器（锁屏时只到日记页，解锁后再操作）；
        // 今天已有日记 → 只到日记页，不再重复弹编辑器。
        // 用 go 而非 push：root context 上 push shell 子路由会渲染空白页
        final gate = ref.read(lockGateProvider);
        if (gate.required && !gate.unlocked) {
          ctx.go('/diary');
          return;
        }
        final now = DateTime.now();
        final todayDay = now.year * 10000 + now.month * 100 + now.day;
        final todays =
            await ref.read(diaryRepoProvider).watchByDate(todayDay).first;
        if (todays.isNotEmpty) {
          ctx.go('/diary');
          return;
        }
        ctx.go('/diary/edit');
      case 'schedule':
        ctx.go('/schedule');
      default:
        // v5.8：心情打卡小组件（动作串形如 mood_3，moodId 从字符串解析）；
        // 常规路径走 channel 的 moodPick 回调，这里兜住 openAction 字符串形态。
        // 与 widgetToggle 同级信任：不设锁屏门槛。
        if (action.startsWith('mood_')) {
          final moodId = int.tryParse(action.substring(5));
          if (moodId != null && moodId > 0) {
            await _applyMoodPick(ref, moodId);
            await _afterMoodSync(ref);
          }
        }
    }
  }
}
