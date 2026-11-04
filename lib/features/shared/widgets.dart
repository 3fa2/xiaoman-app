import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../domain/models/diary.dart';

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
            Pulse(
              child: PhosphorIcon(
                icon,
                size: 44,
                color: p.outline,
                weight: 1.5,
              ),
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
class SaveStatusPill extends StatefulWidget {
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

  @override
  State<SaveStatusPill> createState() => _SaveStatusPillState();
}

class _SaveStatusPillState extends State<SaveStatusPill> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // 「X 分钟前」随时间推进：停留页面时不再永远显示「刚刚」
    _tick = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && widget.status == SaveStatusUi.saved) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _text {
    switch (widget.status) {
      case SaveStatusUi.saved:
        final t = widget.lastSavedAt;
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
    if (widget.status == SaveStatusUi.idle) return const SizedBox.shrink();
    final p = Theme.of(context).colorScheme;
    final isError = widget.status == SaveStatusUi.error;
    return AnimatedSwitcher(
      duration: MotionDuration.fast,
      switchInCurve: MotionCurve.standard,
      switchOutCurve: MotionCurve.standard,
      transitionBuilder: (child, anim) {
        final isIn = child.key == ValueKey(widget.status);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: anim.drive(Tween(
              begin: Offset(0, isIn ? 0.5 : -0.5),
              end: Offset.zero,
            )),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        key: ValueKey(widget.status),
        onTap: isError ? widget.onRetry : null,
        child: Text(
          _text,
          style: AppType.caption.copyWith(
            color: isError ? p.error : p.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

enum SaveStatusUi { idle, dirty, saving, saved, error }

/// 滚动计数器（Odometer/Ticker）：数值变化时逐位垂直滚动到新值。
/// 用于与图表刷选、Bento 计数等需要「数字平滑联动」的场景。
class RollingCounter extends StatelessWidget {
  const RollingCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 450),
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final s = (style ?? const TextStyle(fontSize: 34, height: 1.15));
    // 减弱动态：数字直接显示，不逐位滚动
    if (isReduceMotion(context)) {
      return Text(value.toString(), style: s);
    }
    final fontSize = s.fontSize ?? 34;
    final digitW = fontSize * 0.62;
    final digitH = fontSize * (s.height ?? 1.15) * 1.08;
    final chars = value.toString().split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++)
          ClipRect(
            child: SizedBox(
              width: digitW,
              height: digitH,
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: MotionCurve.standard,
                switchOutCurve: MotionCurve.standard,
                transitionBuilder: (child, anim) {
                  final isIn = child.key == ValueKey(chars[i]);
                  return SlideTransition(
                    position: anim.drive(Tween(
                      begin: Offset(0, isIn ? 1 : -1),
                      end: Offset.zero,
                    )),
                    child: child,
                  );
                },
                child: Text(
                  chars[i],
                  key: ValueKey(chars[i]),
                  textAlign: TextAlign.center,
                  style: s,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 首次构建入场：缩放 + 淡入（详情页正文等「背景内容」跟随 Hero 容器入场）
class ScaleFadeIn extends StatelessWidget {
  const ScaleFadeIn({
    super.key,
    required this.child,
    this.begin = 0.97,
    this.duration = const Duration(milliseconds: 360),
  });

  final Widget child;
  final double begin;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // 减弱动态：直接显示，不播缩放入场
    if (isReduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: MotionCurve.standard,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.scale(scale: begin + (1 - begin) * v, child: child),
      ),
    );
  }
}

/// 延迟弹入（elasticOut）：小元素（心情点/图标/徽标）的入场，index 级联
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 50),
  });

  final Widget child;
  final int index;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _anim = CurvedAnimation(
    parent: _c,
    curve: Curves.elasticOut,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay * widget.index.clamp(0, 12), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 减弱动态：直接显示，不弹跳
    if (isReduceMotion(context)) return widget.child;
    return ScaleTransition(scale: _anim, child: widget.child);
  }
}

/// 呼吸脉冲：空态图标的轻微循环缩放，给静止页面一点生命感
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.max = 1.05});

  final Widget child;
  final double max;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
    lowerBound: 0.97,
    upperBound: widget.max,
  );

  bool _repeating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 减弱动态时停掉 repeat：否则 ticker 永不停止地空转
    final reduce = isReduceMotion(context);
    if (!reduce && !_repeating) {
      _repeating = true;
      _c.repeat(reverse: true);
    } else if (reduce && _repeating) {
      _repeating = false;
      _c
        ..stop()
        ..value = 1.0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isReduceMotion(context)) return widget.child;
    return ScaleTransition(scale: _c, child: widget.child);
  }
}

/// 撒花：待办全部完成等庆祝时刻的一次性粒子爆发（纯 CustomPaint，零依赖）。
/// 粒子轨迹由 index 确定性生成，重建安全。调色板走 design 层 ConfettiPalette。
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.size = 140, this.count = 18});

  final double size;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isReduceMotion(context)) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _ConfettiPainter(progress: _c.value, count: widget.count),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.count});

  final double progress;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxDist = size.width * 0.46;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final frac = i / count;
      final angle = frac * 2 * math.pi + 0.6;
      final speed = 0.55 + (i % 4) * 0.15;
      final dist = maxDist * speed * (1 - math.pow(1 - progress, 2).toDouble());
      final gravity = progress * progress * size.width * 0.22;
      final pos = center +
          Offset(math.cos(angle) * dist, math.sin(angle) * dist + gravity);
      final fade = (1 - progress).clamp(0, 1);
      paint.color = ConfettiPalette.colors[i % ConfettiPalette.colors.length]
          .withAlpha((fade * 255).round());
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + progress * 6);
      final r = 3.2 * (1 - progress * 0.5);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

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

/// 心情胶囊：心情色底 + 心情名，列表/详情里的醒目心情标识（替代纯小圆点）
class MoodChip extends StatelessWidget {
  const MoodChip({super.key, required this.mood, this.dense = false});

  final Mood mood;
  final bool dense; // 紧凑版（首页行内）

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = MoodPalette.colorOf(mood.hue, dark: dark);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.s8 : AppSpacing.s12,
        vertical: dense ? 2 : AppSpacing.s4 + 1,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(dark ? 58 : 36),
        borderRadius: BorderRadius.circular(AppRadii.rSm),
        border: Border.all(color: color.withAlpha(dark ? 150 : 110), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoodDot(color: color, size: dense ? 6 : 8),
          const SizedBox(width: AppSpacing.s4),
          Text(
            mood.name,
            style: (dense ? AppType.caption : AppType.label).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索结果文本：命中关键词加粗主色高亮（query 为空 = 普通文本）
class HighlightText extends StatelessWidget {
  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final q = query.trim().toLowerCase();
    if (q.isEmpty || !text.toLowerCase().contains(q)) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    final base = style ?? const TextStyle();
    final hitStyle = base.copyWith(
      color: p.primary,
      fontWeight: FontWeight.w700,
    );
    final spans = <TextSpan>[];
    var start = 0;
    final lower = text.toLowerCase();
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: hitStyle,
      ));
      start = idx + q.length;
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// ============================================================
/// 全屏媒体预览（v4.4）
/// 从 Dialog 改为标准 PageRoute：Dialog 承受不了系统预测式返回手势
/// （侧滑会瞬间 dismiss 且视频画面生命周期错乱 → 黑屏/错误页）。
/// 页面自管 player 生命周期；转场 fade + scale（0.85→1）。
/// ============================================================

/// 全屏图片按屏幕物理像素宽解码：vivo 主摄原图 1200 万像素级
/// （bitmap 50MB+），全尺寸同步解码是打开/关闭卡顿的根因；
/// 解到显示分辨率（≈1x 屏宽）后内存降至 1/3~1/2，转场全程不掉帧。
/// InteractiveViewer 放大 1.5x 内仍接近全清晰，预览场景足够。
int fullscreenImageDecodeWidth(BuildContext context) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  // 1.5x 折衷：放大仍有余量，解码量可控；封顶 4096 防 4K 屏极端值
  return (MediaQuery.sizeOf(context).width * dpr * 1.5)
      .round()
      .clamp(720, 4096);
}

/// 预解码条目（与 Image.file(cacheWidth:) 同一 cache key，预热直接命中）
ResizeImage fullscreenImageProvider(String path, int decodeWidth) =>
    ResizeImage(FileImage(File(path)), width: decodeWidth, allowUpscaling: false);

Future<void> showFullscreenImage(
  BuildContext context,
  String path, {
  String? heroTag,
}) {
  // push 前就开始解码（与 300ms 转场并行）：Hero 飞行显示的是目的路由的
  // 图片 widget，不解码完就是黑框→突现的卡顿感；预热与显示同 key 直接命中
  unawaited(precacheImage(
    fullscreenImageProvider(path, fullscreenImageDecodeWidth(context)),
    context,
  ));
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: MotionDuration.base,
      // 关闭动画给足时长：Hero 飞回缩略图的过程要看得见
      reverseTransitionDuration: MotionDuration.base,
      pageBuilder: (_, __, ___) =>
          _FullscreenImagePage(path: path, heroTag: heroTag),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MotionCurve.standard,
          reverseCurve: MotionCurve.standard,
        );
        final fade = FadeTransition(opacity: curved, child: child);
        // 带 Hero 时：图片由 Hero 飞行负责，页面只做黑幕淡入淡出
        //（避免页面级缩放和图片飞行叠加显得抖）；无 Hero 时保留缩放入场
        return heroTag == null
            ? ScaleTransition(
                scale: Tween(begin: 0.88, end: 1.0).animate(curved),
                child: fade,
              )
            : fade;
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
  const _FullscreenImagePage({required this.path, this.heroTag});

  final String path;
  final String? heroTag;

  @override
  State<_FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends State<_FullscreenImagePage> {
  late final int _decodeWidth = fullscreenImageDecodeWidth(context);

  @override
  void initState() {
    super.initState();
    // 预解码（按屏幕像素，非全尺寸）：转场中图片已就绪，不黑闪。
    // 与 showFullscreenImage 入口的预热同 key，二次命中零成本。
    precacheImage(
      fullscreenImageProvider(widget.path, _decodeWidth),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      File(widget.path),
      fit: BoxFit.contain,
      cacheWidth: _decodeWidth,
      // Hero 从缩略图树切到全屏树时不闪白重载
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const _PreviewUnavailable(),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: widget.heroTag == null
                ? image
                : Hero(tag: widget.heroTag!, child: image),
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
      // 封面按屏幕像素解码（非全尺寸）：转场期解码掉帧与图片页同根因
      precacheImage(
        fullscreenImageProvider(
          widget.coverPath!,
          fullscreenImageDecodeWidth(context),
        ),
        context,
      );
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
                          cacheWidth:
                              fullscreenImageDecodeWidth(context),
                          gaplessPlayback: true,
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
