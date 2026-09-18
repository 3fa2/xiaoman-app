import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/schedule.dart';
import '../shared/widgets.dart';

/// 日程 · 今天：时间轴 0-24h，块可点可拖（跟手 + 5 分钟吸附 + spring 回弹）。
/// 布局：Stack + Positioned；重叠块贪心分列。
class ScheduleTodayScreen extends ConsumerStatefulWidget {
  const ScheduleTodayScreen({super.key});

  @override
  ConsumerState<ScheduleTodayScreen> createState() =>
      _ScheduleTodayScreenState();
}

class _ScheduleTodayScreenState extends ConsumerState<ScheduleTodayScreen> {
  @override
  void initState() {
    super.initState();
    // 打开页面即补生成（滚动窗口）+ 同步提醒
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(scheduleRepoProvider);
      if (repo.needsRegenerate) {
        repo.regenerate().then(
              (_) => ref.read(reminderWarningsProvider.notifier).syncNow(),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final todayDay =
        now.year * 10000 + now.month * 100 + now.day;
    final instances = ref.watch(scheduleRepoProvider).watchDay(todayDay);
    final warnings = ref.watch(reminderWarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日程'),
        actions: [
          IconButton(
            onPressed: () => context.openTemplates(),
            icon: PhosphorIcon(
              PhosphorIconsRegular.repeat,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.openScheduleEdit(dateDay: todayDay),
        child: PhosphorIcon(
          PhosphorIconsRegular.plus,
          color: p.onPrimary,
          weight: 1.5,
        ),
      ),
      body: Column(
        children: [
          if (warnings.isNotEmpty)
            MaterialBannerLike(
              message: warnings.first,
              onDismiss: () =>
                  ref.read(reminderWarningsProvider.notifier).set(const []),
            ),
          _DayStrip(todayDay: todayDay),
          Expanded(
            child: StreamBuilder<List<ScheduleInstance>>(
              stream: instances,
              builder: (context, snap) {
                final list = snap.data ?? const <ScheduleInstance>[];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.page),
                    child: SkeletonList(),
                  );
                }
                if (list.isEmpty) {
                  return EmptyState(
                    icon: PhosphorIconsRegular.calendarBlank,
                    title: '今天是空的',
                    hint: '加一个时间块，或者建个重复模板',
                    actionLabel: '管理模板',
                    onAction: () => context.openTemplates(),
                  );
                }
                return TimeLineView(
                  dateDay: todayDay,
                  blocks: list,
                  nowMinutes: now.hour * 60 + now.minute,
                  onBlockTap: (b) =>
                      context.openScheduleEdit(instanceId: b.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部横向日期条：今天 + 未来 13 天，点进单日页
/// （日程 · 未来 N 天 的入口；Today 页保持单一焦点）
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.todayDay});

  final int todayDay;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    const cn = ['一', '二', '三', '四', '五', '六', '日'];
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        itemCount: 14,
        itemBuilder: (context, i) {
          final d = DateTime.now().add(Duration(days: i));
          final dd = d.year * 10000 + d.month * 100 + d.day;
          final isToday = i == 0;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.rMd),
              onTap: () => context.openScheduleDay(dd),
              child: Container(
                width: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? p.primaryContainer : p.surface,
                  borderRadius: BorderRadius.circular(AppRadii.rMd),
                  border: Border.all(color: p.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${d.month}/${d.day}',
                      style: AppType.label.copyWith(
                        color: isToday
                            ? (Theme.of(context).brightness ==
                                    Brightness.dark
                                ? p.onSurface
                                : p.primary)
                            : p.onSurface,
                      ),
                    ),
                    Text(
                      cn[d.weekday - 1],
                      style: AppType.caption.copyWith(
                        color: p.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 提醒未生效警告条（失败必须可见，不静默）
class MaterialBannerLike extends StatelessWidget {
  const MaterialBannerLike({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.s8, AppSpacing.page, 0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPad, vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: p.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.rMd),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.warning,
            size: 18,
            color: p.error,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              message,
              style: AppType.caption.copyWith(color: p.onSurface),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: PhosphorIcon(
              PhosphorIconsRegular.x,
              size: 16,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 时间轴视图（今天 / 任意一天复用）
class TimeLineView extends StatelessWidget {
  const TimeLineView({
    super.key,
    required this.dateDay,
    required this.blocks,
    required this.nowMinutes,
    required this.onBlockTap,
  });

  final int dateDay;
  final List<ScheduleInstance> blocks;
  final int nowMinutes;
  final ValueChanged<ScheduleInstance> onBlockTap;

  static const hourHeight = 64.0;
  static const totalHeight = 24 * hourHeight;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final positioned = _layout(blocks);

    return SingleChildScrollView(
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // 小时刻度
            for (var h = 0; h <= 24; h++)
              Positioned(
                left: AppSpacing.page,
                right: AppSpacing.page,
                top: h * hourHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (h > 0 && h < 24)
                      Container(height: 1, color: p.outlineVariant),
                  ],
                ),
              ),
            // 刻度文字
            for (var h = 0; h < 24; h++)
              Positioned(
                left: AppSpacing.page,
                top: h * hourHeight + 2,
                child: Text(
                  '${h.toString().padLeft(2, '0')}:00',
                  style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                ),
              ),
            // 当前时间线
            if (dateDay == _today())
              Positioned(
                left: 56,
                right: AppSpacing.page,
                top: nowMinutes / 1440 * totalHeight,
                child: Container(height: 1.5, color: p.primary),
              ),
            // 时间块
            for (final entry in positioned.entries)
              for (final b in entry.value)
                Positioned(
                  left: 64 + entry.key * 12.0,
                  right: AppSpacing.page - entry.key * 12.0,
                  top: b.startMinutes / 1440 * totalHeight,
                  height:
                      b.durationMinutes / 1440 * totalHeight - 2,
                  child: _BlockCard(
                    block: b,
                    dark: dark,
                    onTap: () => onBlockTap(b),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static int _today() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  /// 贪心列分配：重叠的块横向错开
  static Map<int, List<ScheduleInstance>> _layout(
    List<ScheduleInstance> blocks,
  ) {
    final sorted = [...blocks]..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final columns = <int, int?>{}; // instance -> column
    final columnEnds = <double>[];
    for (final b in sorted) {
      final end = b.endMinutes.toDouble();
      var col = columnEnds.indexWhere((e) => e <= b.startMinutes);
      if (col == -1) {
        col = columnEnds.length;
        columnEnds.add(end);
      } else {
        columnEnds[col] = end;
      }
      columns[b.id] = col;
    }
    final result = <int, List<ScheduleInstance>>{};
    for (final b in blocks) {
      final col = columns[b.id] ?? 0;
      result.putIfAbsent(col, () => []).add(b);
    }
    return result;
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.dark,
    required this.onTap,
  });

  final ScheduleInstance block;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final color = SchedulePalette.of(block.colorIndex, dark: dark);
    final done = block.status == BlockStatus.done;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: MotionCurve.standard,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(done ? 90 : 55),
          borderRadius: BorderRadius.circular(AppRadii.rMd),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${block.title}${block.detached ? ' ·已分离' : ''}',
                    style: AppType.label.copyWith(
                      color: done ? p.onSurfaceVariant : p.onSurface,
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (block.durationMinutes >= 60)
              Text(
                '${_hm(block.startMinutes)}-${_hm(block.endMinutes)}',
                style: AppType.caption.copyWith(
                  color: p.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _hm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
