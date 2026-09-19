import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';

/// ============================================================
/// 公共组件库 v4（全部走 design token）
/// 状态循环：每屏必须有 空态 / 加载态 / 错误态
/// ============================================================

/// 统一悬浮按钮：全 App 唯一 FAB 形态（主题已定形），
/// 每页只换图标 + tooltip，保证「一套设计」而非「两套拼接」。
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: PhosphorIcon(
        icon,
        color: Theme.of(context).colorScheme.onPrimary,
        weight: 1.5,
        size: 26,
      ),
    );
  }
}

/// 统一区块小字动作按钮（「全部」「去日程」这类）：
/// AppType.label + primary，比默认 TextButton 字号统一、不抢标题戏。
class TextActionButton extends StatelessWidget {
  const TextActionButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4, vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppType.label.copyWith(color: p.primary),
            ),
            const SizedBox(width: AppSpacing.s4),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 12,
              color: p.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 按压反馈：scale 1→0.98，100ms，standard。
/// reduceMotion 时只保留颜色变化不做 scale（交互保留，装饰降级）。
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = isReduceMotion(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down && !reduce ? 0.98 : 1,
        duration: reduce ? Duration.zero : MotionDuration.instant,
        curve: MotionCurve.standard,
        child: widget.child,
      ),
    );
  }
}

/// 空态：Phosphor 线性图标 + 一句主文案 + 一句引导 + 可选主按钮 + 快捷示例 chips
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    this.actionLabel,
    this.onAction,
    this.examples = const [],
  });

  final IconData icon;
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 快捷示例：一键创建示例内容，降低空白页的「不知道干嘛」感。
  final List<(String, VoidCallback)> examples;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 44,
              color: p.outline,
              weight: 1.5,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              title,
              style: AppType.headline.copyWith(color: p.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              hint,
              style: AppType.body.copyWith(color: p.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                alignment: WrapAlignment.center,
                children: [
                  for (final (label, onTap) in examples)
                    ActionChip(
                      label: Text(label),
                      onPressed: onTap,
                    ),
                ],
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.s24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 加载态：骨架形状必须匹配最终布局，禁止通用圆形转圈
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.35,
    upperBound: 0.8,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _c,
      child: Column(
        children: [
          for (var i = 0; i < widget.itemCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: p.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.rLg),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 错误态：就地展示 + 可重试
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.warningCircle,
              size: 40,
              color: p.error,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(message, style: AppType.body.copyWith(color: p.onSurface)),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s16),
              OutlinedButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ],
        ),
      ),
    );
  }
}

/// 列表入场：fade + translateY(8→0)，180ms，级联 40ms/项，最多 6 项。
/// 仅首次播放（_hasAnimatedIn），翻页/滚动回来不再播。
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: MotionDuration.base,
  );
  bool _hasAnimatedIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasAnimatedIn) {
      _hasAnimatedIn = true;
      final reduce = isReduceMotion(context);
      final capped = widget.index.clamp(0, 5);
      final delay = reduce ? Duration.zero : MotionDuration.stagger * capped;
      Future.delayed(delay, () {
        if (mounted) {
          _c.duration = reduce ? const Duration(milliseconds: 1) : const Duration(milliseconds: 180);
          _c.forward(from: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = isReduceMotion(context);
    if (reduce) return widget.child;
    // 只动 transform 和 opacity；不用 Opacity widget（saveLayer 代价高）
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: MotionCurve.enter),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _c, curve: MotionCurve.enter)),
        child: widget.child,
      ),
    );
  }
}

/// 区块标题
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.page, right: AppSpacing.page, bottom: AppSpacing.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppType.headline.copyWith(color: p.onSurface),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// 保存状态 pill（P0-1：UI 只反映真实状态，绝不撒谎）
class SaveStatusPill extends StatelessWidget {
  const SaveStatusPill({
    super.key,
    required this.status,
    required this.lastSavedAt,
    required this.error,
    required this.onRetry,
  });

  final SaveStatusUi status;
  final DateTime? lastSavedAt;
  final Object? error;
  final VoidCallback onRetry;

  String get _text {
    switch (status) {
      case SaveStatusUi.saved:
        final t = lastSavedAt;
        if (t == null) return '已保存';
        final diff = DateTime.now().difference(t);
        final rel = diff.inMinutes < 1 ? '刚刚' : '${diff.inMinutes} 分钟前';
        return '已保存 $rel';
      case SaveStatusUi.saving:
        return '保存中…';
      case SaveStatusUi.dirty:
        return '编辑中，停顿 2 秒自动保存';
      case SaveStatusUi.error:
        return '保存失败，点此重试';
      case SaveStatusUi.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == SaveStatusUi.idle) return const SizedBox.shrink();
    final p = Theme.of(context).colorScheme;
    final isError = status == SaveStatusUi.error;
    return GestureDetector(
      onTap: isError ? onRetry : null,
      child: Text(
        _text,
        style: AppType.caption.copyWith(
          color: isError ? p.error : p.onSurfaceVariant,
        ),
      ),
    );
  }
}

enum SaveStatusUi { idle, dirty, saving, saved, error }

/// 心情小圆点 + 文字（列表里心情只用小圆点，不整行染色）
class MoodDot extends StatelessWidget {
  const MoodDot({super.key, required this.color, this.label, this.size = 8});

  final Color color;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (label == null) return dot;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: AppSpacing.s4),
        Text(
          label!,
          style: AppType.caption.copyWith(color: p.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// ============================================================
/// 全屏媒体预览（v4.4）
/// 从 Dialog 改为标准 PageRoute：Dialog 承受不了系统预测式返回手势
/// （侧滑会瞬间 dismiss 且视频画面生命周期错乱 → 黑屏/错误页）。
/// 页面自管 player 生命周期；转场 fade + scale（0.85→1）。
/// ============================================================

Future<void> showFullscreenImage(BuildContext context, String path) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: MotionDuration.base,
      reverseTransitionDuration: MotionDuration.fast,
      pageBuilder: (_, __, ___) => _FullscreenImagePage(path: path),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MotionCurve.standard,
          reverseCurve: MotionCurve.standard,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// 全屏黑底播放视频/实况：点击关闭；controller 由本页持有与释放，
/// 侧滑返回走标准 pop 转场，退出动画期间画面仍在（不黑屏）。
Future<void> showFullscreenVideo(
  BuildContext context,
  String videoPath, {
  String? coverPath,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: MotionDuration.base,
      reverseTransitionDuration: MotionDuration.fast,
      pageBuilder: (_, __, ___) => _FullscreenVideoPage(
        videoPath: videoPath,
        coverPath: coverPath,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MotionCurve.standard,
          reverseCurve: MotionCurve.standard,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _FullscreenImagePage extends StatefulWidget {
  const _FullscreenImagePage({required this.path});

  final String path;

  @override
  State<_FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends State<_FullscreenImagePage> {
  @override
  void initState() {
    super.initState();
    // 预解码：转场过程中图片已就绪，不黑闪
    precacheImage(FileImage(File(widget.path)), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: Image.file(
              File(widget.path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const _PreviewUnavailable(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({required this.videoPath, this.coverPath});

  final String videoPath;

  /// 转场期间先显示封面，初始化完成切视频（全程有画面）
  final String? coverPath;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.coverPath != null) {
      precacheImage(FileImage(File(widget.coverPath!)), context);
    }
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.file(File(widget.videoPath));
    try {
      await c.initialize();
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    await c.setLooping(true);
    await c.play();
    if (mounted) {
      setState(() => _controller = c);
    } else {
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: _failed
              ? const _PreviewUnavailable(message: '视频打不开')
              : c == null
                  ? (widget.coverPath != null
                      ? Image.file(
                          File(widget.coverPath!),
                          fit: BoxFit.contain,
                        )
                      : const CircularProgressIndicator(
                          color: Colors.white54,
                        ))
                  : AspectRatio(
                      aspectRatio: c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
        ),
      ),
    );
  }
}

class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable({this.message = '图片打不开'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(
          PhosphorIconsRegular.warningCircle,
          size: 32,
          color: p.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          message,
          style: AppType.label.copyWith(color: p.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 统一确认弹窗（底部弹窗形态，跟手拖拽关闭）
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '删除',
  bool destructive = true,
}) async {
  final p = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppType.headline.copyWith(color: p.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            message,
            style: AppType.body.copyWith(color: p.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s24),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: p.error)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
