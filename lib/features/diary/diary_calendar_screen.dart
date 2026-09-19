import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../shared/widgets.dart';

/// 日历月视图：有日记的日子带心情色点 + 下方当日列表。
/// 骨架无彩色：日历全部灰阶，心情点只出现在日期格子内。
class DiaryCalendarScreen extends ConsumerStatefulWidget {
  const DiaryCalendarScreen({super.key});

  @override
  ConsumerState<DiaryCalendarScreen> createState() =>
      _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends ConsumerState<DiaryCalendarScreen> {
  DateTime _focused = DateTime.now();
  int _selectedDay = _dayOf(DateTime.now());

  static int _dayOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final month = _focused.year * 100 + _focused.month;
    final diaries = ref.watch(diaryRepoProvider).watchByMonth(month);
    final dayList = ref.watch(diaryRepoProvider).watchByDate(_selectedDay);
    final moods = ref.watch(diaryRepoProvider).watchMoods();

    return Scaffold(
      appBar: AppBar(
        title: const Text('日记'),
        actions: [
          IconButton(
            onPressed: () => context.openMoodTrend(),
            icon: PhosphorIcon(
              PhosphorIconsRegular.chartLineUp,
              color: p.onSurfaceVariant,
            ),
          ),
          IconButton(
            onPressed: () => context.openDiarySearch(),
            icon: PhosphorIcon(
              PhosphorIconsRegular.magnifyingGlass,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.openDiaryEditor(),
        child: PhosphorIcon(
          PhosphorIconsRegular.plus,
          color: p.onPrimary,
          weight: 1.5,
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: StreamBuilder<List<Mood>>(
              stream: moods,
              builder: (context, moodSnap) {
                final moodMap = {
                  for (final m in (moodSnap.data ?? const <Mood>[])) m.id: m,
                };
                return StreamBuilder<List<Diary>>(
                  stream: diaries,
                  builder: (context, snap) {
                    final list = snap.data ?? const <Diary>[];
                    final moodByDay = <int, Mood?>{
                      for (final d in list)
                        d.dateDay: d.moodId == null ? null : moodMap[d.moodId!],
                    };
                    return TableCalendar<int>(
                      firstDay: DateTime(2000),
                      lastDay: DateTime(2100),
                      focusedDay: _focused,
                      selectedDayPredicate: (d) => _dayOf(d) == _selectedDay,
                      onPageChanged: (f) => setState(() => _focused = f),
                       onDaySelected: (selected, focused) => setState(() {
                         _selectedDay = _dayOf(selected);
                         _focused = focused;
                       }),
                       // 中文星期标签（“周一”式两字）默认 16.0 高度装不下会垂直裁切，加高到 30。
                       daysOfWeekHeight: 30,
                       headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle:
                            AppType.headline.copyWith(color: p.onSurface),
                        leftChevronIcon: PhosphorIcon(
                          PhosphorIconsRegular.caretLeft,
                          size: 18,
                          color: p.onSurfaceVariant,
                        ),
                        rightChevronIcon: PhosphorIcon(
                          PhosphorIconsRegular.caretRight,
                          size: 18,
                          color: p.onSurfaceVariant,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        selectedDecoration: BoxDecoration(
                          color: p.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: p.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: AppType.body.copyWith(
                          color: dark ? p.onSurface : p.primary,
                        ),
                        todayTextStyle:
                            AppType.body.copyWith(color: p.onSurface),
                        defaultTextStyle:
                            AppType.body.copyWith(color: p.onSurface),
                        weekendTextStyle:
                            AppType.body.copyWith(color: p.onSurface),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final mood = moodByDay[_dayOf(date)];
                          if (mood == null) return null;
                          return Positioned(
                            bottom: 4,
                            child: MoodDot(
                              color: MoodPalette.colorOf(mood.hue, dark: dark),
                              size: 6,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.block),
          const SectionHeader('当天'),
          Expanded(
            child: StreamBuilder<List<Diary>>(
              stream: dayList,
              builder: (context, snap) {
                final list = snap.data ?? const <Diary>[];
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: PhosphorIconsRegular.notebook,
                    title: '这一天还没有日记',
                    hint: '点右下角的加号写一篇',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, 0, AppSpacing.page, AppSpacing.listBottom,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: _DiaryCard(diary: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        onTap: () => context.openDiaryDetail(diary.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                diary.title.isEmpty ? diary.summary : diary.title,
                style: AppType.headline.copyWith(color: p.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (diary.summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Text(
                  diary.summary,
                  style: AppType.body.copyWith(color: p.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
