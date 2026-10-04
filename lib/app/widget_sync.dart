import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';
import '../features/todo/todo_add_sheet.dart';
import 'router.dart';

/// 桌面小组件同步桥（v5.0，channel：trinity/widget）。
///
/// 1. 订阅待办数据变化 → 通知原生刷新全部小组件实例
///    （原生勾选直写数据库会触发 drift 表触发器回流到这里，distinct 防死循环）
/// 2. 接收小组件入口动作：点 [+] → 待办页并弹添加框；点整块 → 待办页
///    热启动由原生直接 invoke；冷启动在 bootstrap 末尾 getLaunchAction 补取
class WidgetSync {
  static const _ch = MethodChannel('trinity/widget');
  static StreamSubscription<dynamic>? _sub;

  /// main bootstrap 里挂一次：订阅数据 + 注册原生回调
  static void attach(WidgetRef ref) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'openAction') {
        _handleAction(ref, call.arguments as String?);
      }
    });
    _sub?.cancel();
    _sub = ref.read(todoRepoProvider).watchAll().distinct().listen((_) {
      _refresh();
      // 待办变化 → 提醒全量重建（勾掉/删掉到期项，闹钟同步取消）
      unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());
    });
  }

  static void _refresh() {
    _ch.invokeMethod<void>('refresh').catchError((Object e) {
      // 原生侧异常不影响 App 数据
    });
  }

  /// 冷启动补取：engine 就绪前原生把动作暂存在 launchAction
  static Future<void> drainLaunchAction(WidgetRef ref) async {
    try {
      final action = await _ch.invokeMethod<String>('getLaunchAction');
      if (action != null) _handleAction(ref, action);
    } catch (_) {
      // 通道不可用（桌面/测试环境）：忽略
    }
  }

  static void _handleAction(WidgetRef ref, String? action) {
    if (action == null) return;
    if (action != 'todo' && action != 'todo_add') return;
    final ctx = rootKey.currentContext;
    if (ctx == null) return;
    ctx.go('/todo');
    if (action != 'todo_add') return;
    // 锁屏中：只导航不弹框（解锁后用户自己点 + 也顺手）
    final gate = ref.read(lockGateProvider);
    if (gate.required && !gate.unlocked) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = rootKey.currentContext;
      if (c != null) showTodoAddSheet(c);
    });
  }
}
