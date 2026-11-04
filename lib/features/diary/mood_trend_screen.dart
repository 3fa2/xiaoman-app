import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../shared/widgets.dart';

/// 心情趋势（v5.6 重做）：折线图横向滑动/点按刷选，
/// 数据点磁吸吸附（自动对齐最近记录），顶部滚动计数器实时联动。
/// 色彩边界：心情色只出现在数据点/分布条上，骨架全灰阶。
class MoodTrendScreen extends ConsumerStatefulWidget {
  const MoodTrendScreen({super.key});

  @override
  ConsumerState<MoodTrendScreen> createState() => _MoodTrendScreenState();
}

class _MoodTrendScreenState extends ConsumerState<MoodTrendScreen> {
  int? _selIndex; // 刷选选中的记录下标（null = 跟随最新一条）

  // 查询只发一次：此前 future 在 build 里创建，每次刷选 tick 都重发 SQL
  late final Future<List<(Diary, Mood?)>> _data;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final toDay = now.year * 10000 + now.month * 100 + now.day;
    final from = now.subtract(const Duration(days: 30));
    final fromDay = from.year * 10000 + from.month * 100 + from.day;
    _data = ref.read(diaryRepoProvider).watchWithMoodRange(fromDay, toDay);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('心情趋势'),
        actions: [
          IconButton(
            tooltip: '记录统计',
            onPressed: () => context.openDiaryStats(),
            icon: PhosphorIcon(
              PhosphorIconsRegular.chartBar,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<(Diary, Mood?)>>(
        future: _data,
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

          // 选中下标（磁吸后恒有效）；默认最新一条
          final eff = (_selIndex ?? recorded.length - 1)
              .clamp(0, recorded.length - 1);
          final selDiary = recorded[eff].$1;
          final selMood = recorded[eff].$2!;

          // 心情名 → y 序号（按首次出现顺序，保持稳定）
          final moodNames = <String, Mood>{};
          for (final r in recorded) {
            moodNames.putIfAbsent(r.$2!.name, () => r.$2!);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
            ),
            children: [
              const SectionHeader('最近 30 天'),
              // 顶部：滚动计数器 + 选中记录信息（刷选实时联动）
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPad),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RollingCounter(
                        value: eff + 1,
                        style: AppType.display.copyWith(
                          fontSize: 46,
                          color: p.primary,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.s8, bottom: AppSpacing.s4,
                        ),
                        child: Text(
                          '/ ${recorded.length} 篇',
                          style: AppType.caption.copyWith(
                            color: p.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: MotionDuration.fast,
                        switchInCurve: MotionCurve.standard,
                        switchOutCurve: MotionCurve.standard,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: anim.drive(Tween(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            )),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(eff),
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${selDiary.dateDay ~/ 10000}年'
                              '${(selDiary.dateDay ~/ 100) % 100}月'
                              '${selDiary.dateDay % 100}日',
                              style: AppType.label.copyWith(
                                color: p.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            MoodChip(mood: selMood, dense: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPad),
                  child: SizedBox(
                    height: 200,
                    // RepaintBoundary：图表独立重绘（性能纪律 #4）
                    child: RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final w = box.maxWidth;
                          final n = recorded.length;
                          void selectDx(double dx) {
                            final idx =
                                ((dx / w) * (n - 1)).round().clamp(0, n - 1);
                            if (idx != (_selIndex ?? n - 1)) {
                              setState(() => _selIndex = idx);
                            }
                          }

                          final barData = LineChartBarData(
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
                                radius: spot.x.toInt() == eff ? 6.5 : 3.2,
                                color: MoodPalette.colorOf(
                                  recorded[spot.x.toInt()].$2!.hue,
                                  dark: dark,
                                ),
                                strokeColor: spot.x.toInt() == eff
                                    ? p.primary
                                    : Colors.transparent,
                                strokeWidth: spot.x.toInt() == eff ? 2 : 0,
                              ),
                            ),
                          );
                          // 折线自绘制入场：maxX 从 0 生长到 n-1，点随线出现
                          // （减弱动态：跳过生长直接到位）
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(n),
                            tween: Tween(begin: 0, end: 1),
                            duration: isReduceMotion(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 900),
                            curve: MotionCurve.standard,
                            builder: (context, t, _) {
                              final maxX = n == 1 ? 1.0 : (n - 1) * t;
                              final showTip = eff <= maxX + 0.001;
                              return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (d) => selectDx(d.localPosition.dx),
                            onHorizontalDragStart:
                                (d) => selectDx(d.localPosition.dx),
                            onHorizontalDragUpdate:
                                (d) => selectDx(d.localPosition.dx),
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: maxX,
                                minY: 0,
                                maxY: moodNames.length.toDouble() + 0.4,
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
                                  // 触摸由外层 GestureDetector 统一做磁吸刷选
                                  handleBuiltInTouches: false,
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (_) => p.inverseSurface,
                                    getTooltipItems: (spots) => spots
                                        .map((s) => LineTooltipItem(
                                              '${recorded[s.x.toInt()].$1.dateDay % 100}日'
                                              ' ${recorded[s.x.toInt()].$2!.name}',
                                              AppType.label.copyWith(
                                                color: p.onInverseSurface,
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                showingTooltipIndicators: [
                                  if (showTip)
                                    ShowingTooltipIndicators([
                                      LineBarSpot(
                                        barData,
                                        0,
                                        barData.spots[eff],
                                      ),
                                    ]),
                                ],
                                lineBarsData: [
                                  barData,
                                ],
                              ),
                            ),
                          );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.block),
              const SectionHeader('分布'),
              _DistributionCard(recorded: recorded, dark: dark),
            ],
          );
        },
      ),
    );
  }
}

/// 心情分布（原逻辑抽出）：条形 + 计数
class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.recorded, required this.dark});

  final List<(Diary, Mood?)> recorded;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final moodNames = {for (final m in recorded) m.$2!.name: m.$2!};
    final distribution = <String, int>{};
    for (final r in recorded) {
      distribution[r.$2!.name] = (distribution[r.$2!.name] ?? 0) + 1;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        child: Column(
          children: [
            for (final e in distribution.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
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
                        style: AppType.label.copyWith(color: p.onSurface),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.rSm),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: e.value / recorded.length),
                          duration: isReduceMotion(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 250),
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
    );
  }
}
