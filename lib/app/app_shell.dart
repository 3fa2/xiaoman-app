import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design/motion.dart';

/// 底部导航 4 tab：首页 / 日记 / 备忘 / 日程。
/// Tab 切换 = Fade-Through（平级 tab 无方向关系，横滑是错误隐喻且与返回手势冲突）。
/// branches 由 StatefulShellRoute.indexedStack 保活，转场期间内容子树零重建。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = <(String, IconData, IconData)>[
    ('首页', PhosphorIconsRegular.house, PhosphorIconsFill.house),
    ('日记', PhosphorIconsRegular.notebook, PhosphorIconsFill.notebook),
    ('备忘', PhosphorIconsRegular.sticker, PhosphorIconsFill.sticker),
    ('日程', PhosphorIconsRegular.calendarBlank, PhosphorIconsFill.calendarBlank),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: MotionDuration.page,
        transitionBuilder: (child, animation, secondaryAnimation) =>
            FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(shell.currentIndex),
          child: shell,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: PhosphorIcon(_tabs[i].$2, size: 24, color: p.onSurfaceVariant),
              selectedIcon: PhosphorIcon(
                _tabs[i].$3,
                size: 24,
                color: p.primary,
                weight: 1.5,
              ),
              label: _tabs[i].$1,
            ),
        ],
      ),
    );
  }
}
