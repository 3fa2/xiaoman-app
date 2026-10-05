import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';
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
  }

  /// 冷启动补取：engine 就绪前原生把动作暂存在 launchAction
  static Future<void> drainLaunchAction(WidgetRef ref) async {
    try {
      final action = await _ch.invokeMethod<String>('getLaunchAction');
      if (action != null) _handleAction(ref, action);
    } catch (_) {}

    // 同步 App 没运行时小组件标记的勾选
    try {
      final ids = await _ch.invokeMethod<List<dynamic>>('drainPending');
      if (ids != null && ids.isNotEmpty) {
        final repo = ref.read(todoRepoProvider);
        for (final id in ids) {
          final i = (id as num).toInt();
          // 读取当前状态后翻转（drainPending 只返回 id，不知道当前状态）
          // 通过 toggle 实现：done = NOT done
          await repo.toggle(id: i, done: !_currentDone(ref, i));
        }
      }
    } catch (_) {}
  }

  static bool _currentDone(WidgetRef ref, int id) {
    // 这里无法同步获取 Stream 的当前值，用 false 作为默认（toggle → done=true）
    // 实际上 watchAll 的下一帧会推送正确状态，不影响最终一致性
    return false;
  }

  static Future<void> _doToggle(WidgetRef ref, int id) async {
    // 小组件已经翻转了缓存中的 done 状态，这里执行数据库真正的 toggle
    // 由于不知道数据库中的当前状态，用 toggle(id, done: !currentDone) 模式
    // 但 repo.toggle 需要 done 参数——这里通过读取当前流来获取
    // 简化方案：直接调用 toggle 传 done=true（小组件勾选=标记完成）
    // 如果用户在 App 里又取消勾选，watchAll 会回流修正
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

  static void _handleAction(WidgetRef ref, String? action) {
    if (action == null) return;
    if (action != 'todo' && action != 'todo_add') return;
    final ctx = rootKey.currentContext;
    if (ctx == null) return;
    ctx.go('/todo');
    if (action != 'todo_add') return;
    final gate = ref.read(lockGateProvider);
    if (gate.required && !gate.unlocked) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = rootKey.currentContext;
      if (c != null) showTodoAddSheet(c);
    });
  }
}
