import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';
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
      }
    });
    _sub?.cancel();
    _sub = ref.read(todoRepoProvider).watchAll().distinct().listen((todos) {
      _pushTodos(todos);
      // 待办变化 → 提醒全量重建
      unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());
    });
    // v5.3：今日日程小组件——订阅今天的日程变化（含 regenerate 插入实例）
    final now = DateTime.now();
    final todayDay = now.year * 10000 + now.month * 100 + now.day;
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
      if (action != null) _handleAction(ref, action);
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
          .map((t) => {'id': t.id, 'title': t.title, 'done': false})
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
    }
  }
}
