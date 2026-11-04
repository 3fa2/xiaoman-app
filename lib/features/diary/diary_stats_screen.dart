import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../../domain/services/stats_service.dart';
import '../shared/widgets.dart';

/// 记录统计（v5.8）：连续打卡 / 累计数据 / 热力图 / 心情分布 / 月度篇数。
/// 与心情趋势互补：趋势看最近 30 天心情走势，这里看全量记录总览。
/// 入口：心情趋势页 AppBar 的统计图标。
class DiaryStatsScreen extends ConsumerWidget {
  const DiaryStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('记录统计')),
      body: StreamBuilder<List<Diary>>(
        stream: ref.watch(diaryRepoProvider).watchAll(),
        builder: (context, snap) {
          final diaries = snap.data ?? const <Diary>[];
          if (snap.connectionState == ConnectionState.waiting && diaries.isEmpty) {
            return const SkeletonList();
          }
          if (diaries.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsRegular.chartBar,
              title: '还没有记录',
              hint: '写下第一篇日记，这里会亮起来',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
            ),
            children: [
              _HeadlineStats(diaries: diaries),
              const SizedBox(height: AppSpacing.s12),
              const SectionHeader('最近半年'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPad),
                  child: _Heatmap(diaries: diaries),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              const SectionHeader('心情分布'),
              _MoodDistribution(diaries: diaries),
              const SizedBox(height: AppSpacing.s12),
              const SectionHeader('今年每月'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPad),
                  child: _MonthlyBars(diaries: diaries),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '共 ${diaries.length} 篇 · 统计含全部未删除记录',
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(color: p.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---- 统计核心在 domain/services/stats_service.dart（纯函数，提醒文案共用）----

class _HeadlineStats extends StatelessWidget {
  const _HeadlineStats({required this.diaries});

  final List<Diary> diaries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final streak = streakDays(diaries, today);
    final longest = longestStreak(diaries);
    final chars = diaries.fold<int>(
      0, (n, d) => n + d.title.length + d.content.length,
    );

    String charsLabel(int n) => n >= 10000
        ? '${(n / 10000).toStringAsFixed(1)} 万'
        : '$n';

    // 2×2 等高网格：小屏一行四卡必截断，两行两列每卡固定高度、内容居中，
    // 四卡基线对齐（此前右列 Column 自适应高度导致参差）
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsRegular.fire,
                value: '$streak 天',
                label: '连续记录',
                highlight: streak > 0,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsRegular.notebook,
                value: '${diaries.length} 篇',
                label: '累计日记',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsRegular.textAa,
                value: charsLabel(chars),
                label: '累计字数',
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsRegular.calendarCheck,
                value: '$longest 天',
                label: '最长连续',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  /// 统一卡高：四卡完全等高，图标/数值/标签垂直居中
  static const _cardHeight = 104.0;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: highlight ? p.primaryContainer : null,
      child: SizedBox(
        height: _cardHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                icon,
                size: 18,
                color: highlight ? p.onPrimaryContainer : p.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                value,
                style: AppType.headline.copyWith(
                  color: highlight ? p.onPrimaryContainer : p.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                label,
                style: AppType.caption.copyWith(
                  color: highlight ? p.onPrimaryContainer : p.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// GitHub 式打卡热力图：最近 26 周，行=周几，列=周；有日记的心情色、
/// 无日记的浅灰；有心情的天取第一篇带心情日记的心情
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.diaries});

  final List<Diary> diaries;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    // dateDay -> 当天日记（取心情：第一篇带心情的）
    final byDay = <int, int?>{};
    final daySet = <int>{};
    for (final d in diaries) {
      daySet.add(d.dateDay);
      if (!byDay.containsKey(d.dateDay) || byDay[d.dateDay] == null) {
        byDay[d.dateDay] = d.moodId;
      }
    }

    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    // 结尾对齐到本周日（国内习惯周一为一周之首）
    final weekDay = today0.weekday; // 1=周一
    final end = today0.add(Duration(days: 7 - weekDay));
    const weeks = 26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // 默认露出最近一周（右侧）
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var w = weeks; w >= 1; w--)
                Column(
                  children: [
                    for (var dow = 0; dow < 7; dow++)
                      Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: _heatCell(
                          context,
                          p,
                          end.subtract(Duration(days: (w - 1) * 7 + (6 - dow))),
                          byDay,
                          daySet,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '每格一天 · 有日记亮心情色 · 右侧为本周',
          style: AppType.caption.copyWith(color: p.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _heatCell(
    BuildContext context,
    ColorScheme p,
    DateTime day,
    Map<int, int?> byDay,
    Set<int> daySet,
  ) {
    final key = day.year * 10000 + day.month * 100 + day.day;
    final future = day.isAfter(DateTime.now());
    if (future) return const SizedBox(width: 12, height: 12);
    Color color;
    if (daySet.contains(key)) {
      final moodId = byDay[key];
      color = p.primary;
      if (moodId != null) {
        // 心情色弱化为容器感：主色透明底 + 心情色边不行（热力图要色块），
        // 直接心情色 55% 透明度叠主色即可区分"有心情"
        color = p.primary.withAlpha(150);
      }
    } else {
      // 空格子：onSurfaceVariant 低透明度——surfaceContainerHighest 在深色
      // 卡片上几乎不可见（真机截图确认），这里要"隐约可见的网格"
      color = p.onSurfaceVariant.withAlpha(38);
    }
    final isToday = key ==
        DateTime.now().year * 10000 +
            DateTime.now().month * 100 +
            DateTime.now().day;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.rSm),
        border: isToday
            ? Border.all(color: p.primary, width: 1.2)
            // 无记录格加同色系细边，深浅模式都可辨识
            : daySet.contains(key)
                ? null
                : Border.all(color: p.outlineVariant.withAlpha(90)),
      ),
    );
  }
}

/// 全量心情分布（占比条，复用趋势页的视觉语言）
class _MoodDistribution extends ConsumerWidget {
  const _MoodDistribution({required this.diaries});

  final List<Diary> diaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<Mood>>(
      stream: ref.watch(diaryRepoProvider).watchMoods(),
      builder: (context, snap) {
        final moods = {
          for (final m in (snap.data ?? const <Mood>[])) m.id: m,
        };
        final counts = <int, int>{};
        for (final d in diaries) {
          if (d.moodId != null) counts[d.moodId!] = (counts[d.moodId!] ?? 0) + 1;
        }
        final withMood = counts.values.fold<int>(0, (a, b) => a + b);
        final entries = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (entries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPad),
              child: Text(
                '还没有打过心情',
                style: AppType.body.copyWith(color: p.onSurfaceVariant),
              ),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPad),
            child: Column(
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                    child: Row(
                      children: [
                        MoodDot(
                          color: moods[e.key] != null
                              ? MoodPalette.colorOf(
                                  moods[e.key]!.hue, dark: dark)
                              : p.outline,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        SizedBox(
                          width: 56,
                          child: Text(
                            moods[e.key]?.name ?? '已删心情',
                            style: AppType.label.copyWith(color: p.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadii.rSm),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: e.value / (withMood == 0 ? 1 : withMood),
                              ),
                              duration: const Duration(milliseconds: 250),
                              curve: MotionCurve.standard,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                value: v,
                                minHeight: 8,
                                backgroundColor: p.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  moods[e.key] != null
                                      ? MoodPalette.colorOf(
                                          moods[e.key]!.hue, dark: dark)
                                      : p.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          '${e.value}',
                          style: AppType.caption.copyWith(
                            color: p.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 今年 1-12 月篇数迷你条形
class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.diaries});

  final List<Diary> diaries;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final year = DateTime.now().year;
    final perMonth = List<int>.filled(12, 0);
    for (final d in diaries) {
      if (d.dateDay ~/ 10000 == year) {
        perMonth[(d.dateDay ~/ 100) % 100 - 1]++;
      }
    }
    final max = perMonth.fold<int>(1, (a, b) => a > b ? a : b);
    final nowMonth = DateTime.now().month;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var m = 1; m <= 12; m++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 72,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: perMonth[m - 1] / max),
                      duration: const Duration(milliseconds: 250),
                      curve: MotionCurve.standard,
                      builder: (context, v, _) => FractionallySizedBox(
                        heightFactor: v.clamp(perMonth[m - 1] > 0 ? 0.06 : 0, 1),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: m == nowMonth
                                ? p.primary
                                : p.primary.withAlpha(90),
                            borderRadius:
                                BorderRadius.circular(AppRadii.rSm),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '$m',
                  style: AppType.caption.copyWith(
                    color: m == nowMonth ? p.primary : p.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
