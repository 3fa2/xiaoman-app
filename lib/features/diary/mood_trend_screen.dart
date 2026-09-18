import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../shared/widgets.dart';

/// 心情趋势：最近 30 天心情折线（fl_chart）+ 心情分布。
/// 色彩边界：心情色只出现在数据点/分布条上，骨架全灰阶。
class MoodTrendScreen extends ConsumerWidget {
  const MoodTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final toDay = now.year * 10000 + now.month * 100 + now.day;
    final from = now.subtract(const Duration(days: 30));
    final fromDay = from.year * 10000 + from.month * 100 + from.day;

    return Scaffold(
      appBar: AppBar(title: const Text('心情趋势')),
      body: FutureBuilder<List<(Diary, Mood?)>>(
        future: ref.read(diaryRepoProvider).watchWithMoodRange(fromDay, toDay),
        builder: (context, snap) {
          final data = snap.data ?? const <(Diary, Mood?)>[];
          final recorded = data
              .where((e) => e.$2 != null)
              .toList()
            ..sort((a, b) => a.$1.dateDay.compareTo(b.$1.dateDay));
          if (recorded.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsRegular.chartLineUp,
              title: '最近 30 天还没记过心情',
              hint: '在首页打卡心情后，这里会画出趋势',
            );
          }
          final moodNames = {for (final m in recorded) m.$2!.name: m.$2!};
          final distribution = <String, int>{};
          for (final r in recorded) {
            distribution[r.$2!.name] = (distribution[r.$2!.name] ?? 0) + 1;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
            ),
            children: [
              const SectionHeader('最近 30 天'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPad),
                  child: SizedBox(
                    height: 180,
                    // RepaintBoundary：图表独立重绘（性能纪律 #4）
                    child: RepaintBoundary(
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: moodNames.length.toDouble(),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: p.outlineVariant,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots
                                  .map(
                                    (s) => LineTooltipItem(
                                      recorded[s.x.toInt()].$2!.name,
                                      AppType.label.copyWith(
                                        color: p.onSurface,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < recorded.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    (moodNames.keys
                                            .toList()
                                            .indexOf(recorded[i].$2!.name) +
                                        1)
                                        .toDouble(),
                                  ),
                              ],
                              isCurved: false,
                              barWidth: 2,
                              color: p.primary,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, _, __, ___) =>
                                    FlDotCirclePainter(
                                  radius: 3,
                                  color: MoodPalette.colorOf(
                                    recorded[spot.x.toInt()].$2!.hue,
                                    dark: dark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.block),
              const SectionHeader('分布'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPad),
                  child: Column(
                    children: [
                      for (final e in distribution.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s4,
                          ),
                          child: Row(
                            children: [
                              MoodDot(
                                color: MoodPalette.colorOf(
                                  moodNames[e.key]!.hue,
                                  dark: dark,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  e.key,
                                  style: AppType.label.copyWith(
                                    color: p.onSurface,
                                  ),
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
                                      end: e.value / recorded.length,
                                    ),
                                    duration: const Duration(milliseconds: 250),
                                    curve: MotionCurve.standard,
                                    builder: (context, v, _) => LinearProgressIndicator(
                                      value: v,
                                      minHeight: 8,
                                      backgroundColor: p.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(
                                        MoodPalette.colorOf(
                                          moodNames[e.key]!.hue,
                                          dark: dark,
                                        ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
