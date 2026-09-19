import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../../domain/models/schedule.dart';
import '../../domain/services/rrule_service.dart';
import '../shared/widgets.dart';

/// 首页：今日时间块（接下来 3 条）+ 今日心情打卡 + 最近 3 篇日记 + 快捷新建。
/// 骨架无彩色：页面只有灰阶，彩色只在心情点/日程块内。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayDay = today.year * 10000 + today.month * 100 + today.day;
    final blocks = ref.watch(scheduleRepoProvider).watchDay(todayDay);
    final diaries = ref.watch(diaryRepoProvider).watchAll();
    final moods = ref.watch(diaryRepoProvider).watchMoods();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('M月d日 EEEE', 'zh_CN').format(today),
          style: AppType.title.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.openSettings(),
            icon: PhosphorIcon(
              PhosphorIconsRegular.gear,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.listBottom),
        children: [
          SectionHeader(
            '今日日程',
            action: TextActionButton(
              label: '全部',
              onPressed: () => context.go('/schedule'),
            ),
          ),
          _NextBlocks(stream: blocks),
          const SizedBox(height: AppSpacing.block),
          const SectionHeader('今日心情'),
          _MoodCheckin(moods: moods, diaries: diaries),
          const SizedBox(height: AppSpacing.block),
          SectionHeader(
            '最近日记',
            action: TextActionButton(
              label: '全部',
              onPressed: () => context.openDiarySearch(),
            ),
          ),
          _RecentDiaries(stream: diaries, moods: moods),
        ],
      ),
    );
  }
}

class _NextBlocks extends StatelessWidget {
  const _NextBlocks({required this.stream});

  final Stream<List<ScheduleInstance>> stream;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return StreamBuilder<List<ScheduleInstance>>(
      stream: stream,
      builder: (context, snap) {
        final now = DateTime.now();
        final nowMinutes = now.hour * 60 + now.minute;
        final todayDay =
            now.year * 10000 + now.month * 100 + now.day;
        final upcoming = (snap.data ?? const <ScheduleInstance>[])
            .where(
              (b) =>
                  b.status == BlockStatus.pending &&
                  b.endMinutes >= nowMinutes &&
                  b.dateDay == todayDay,
            )
            .toList();
        if (upcoming.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPad),
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.calendarBlank,
                      color: p.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        '今天没有接下来的安排',
                        style: AppType.body.copyWith(color: p.onSurfaceVariant),
                      ),
                    ),
                    TextActionButton(
                      label: '去日程',
                      onPressed: () => context.go('/schedule'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < upcoming.length; i++)
              StaggeredEntrance(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, 0, AppSpacing.page, AppSpacing.s8,
                  ),
                  child: _BlockRow(block: upcoming[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.block});

  final ScheduleInstance block;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final color = SchedulePalette.of(block.colorIndex, dark: dark);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        onTap: () => context.openScheduleEdit(instanceId: block.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.rSm),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: AppType.headline.copyWith(color: p.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatMinutes(block.startMinutes),
                      style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodCheckin extends ConsumerWidget {
  const _MoodCheckin({required this.moods, required this.diaries});

  final Stream<List<Mood>> moods;
  final Stream<List<Diary>> diaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<Mood>>(
      stream: moods,
      builder: (context, moodSnap) {
        final moods = moodSnap.data ?? const <Mood>[];
        return StreamBuilder<List<Diary>>(
          stream: diaries,
          builder: (context, snap) {
            final all = snap.data ?? const <Diary>[];
            final today = DateTime.now();
            final todayDay =
                today.year * 10000 + today.month * 100 + today.day;
            final todays = all.where((d) => d.dateDay == todayDay).toList();
            // 同日多篇：取最新创建且带心情的一篇作为"当日心情"（否则打卡态不稳定）
            final withMood = todays.where((d) => d.moodId != null).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final current =
                withMood.isEmpty ? null : withMood.first.moodId;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MoodWeekStrip(
                    diaries: all,
                    moods: moods,
                    dark: dark,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final m in moods)
                        _MoodChip(
                          mood: m,
                          selected: current == m.id,
                          dark: dark,
                          onTap: () async {
                            final diaryId =
                                todays.isEmpty ? null : todays.first.id;
                            final repo = ref.read(diaryRepoProvider);
                            if (diaryId == null) {
                              // 今日无日记：先建一条，只记心情
                              final id = await repo.save(
                                id: null,
                                title: '',
                                content: '',
                                extra: m.id,
                              );
                              await repo.setMood(diaryId: id, moodId: m.id);
                            } else {
                              await repo.setMood(
                                diaryId: diaryId,
                                moodId: current == m.id ? null : m.id,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 近 7 天心情点带：有记录的天填色，没记录的空心；今天是主色描边。
class _MoodWeekStrip extends StatelessWidget {
  const _MoodWeekStrip({
    required this.diaries,
    required this.moods,
    required this.dark,
  });

  final List<Diary> diaries;
  final List<Mood> moods;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final moodMap = {for (final m in moods) m.id: m};
    final now = DateTime.now();
    const cn = ['一', '二', '三', '四', '五', '六', '日'];
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 6; i >= 0; i--)
            Builder(builder: (context) {
              final d = now.subtract(Duration(days: i));
              final day = d.year * 10000 + d.month * 100 + d.day;
              final dayDiaries =
                  diaries.where((x) => x.dateDay == day).toList();
              // 同日多篇：取最新创建且带心情的，作为该天的心情点
              final withMood = dayDiaries
                  .where((x) => x.moodId != null)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final moodId = withMood.isEmpty ? null : withMood.first.moodId;
              final mood = moodId == null ? null : moodMap[moodId];
              final isToday = i == 0;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mood == null
                            ? Colors.transparent
                            : MoodPalette.colorOf(mood.hue, dark: dark),
                        border: Border.all(
                          color: mood == null
                              ? p.outline
                              : (isToday ? p.primary : Colors.transparent),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      isToday ? '今天' : cn[d.weekday - 1],
                      style: AppType.caption.copyWith(
                        color: isToday ? p.primary : p.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final color = MoodPalette.colorOf(mood.hue, dark: dark);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionDuration.base,
        curve: MotionCurve.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? p.primaryContainer : p.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.rSm),
          // 选中态用心情色描边，打卡结果一眼可见
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoodDot(color: color, size: selected ? 10 : 8),
            const SizedBox(width: AppSpacing.s8),
            Text(
              mood.name,
              style: AppType.label.copyWith(
                color: selected
                    ? (dark ? p.onSurface : p.primary)
                    : p.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: AppSpacing.s4),
              PhosphorIcon(
                PhosphorIconsFill.check,
                size: 12,
                color: dark ? p.onSurface : p.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentDiaries extends StatelessWidget {
  const _RecentDiaries({required this.stream, required this.moods});

  final Stream<List<Diary>> stream;
  final Stream<List<Mood>> moods;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    return StreamBuilder<List<Mood>>(
      stream: moods,
      builder: (context, moodSnap) {
        final moodMap = {
          for (final m in (moodSnap.data ?? const <Mood>[])) m.id: m,
        };
        return StreamBuilder<List<Diary>>(
          stream: stream,
          builder: (context, snap) {
            final list = (snap.data ?? const <Diary>[]).take(3).toList();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPad),
                    child: Column(
                      children: [
                        Text(
                          '还没有日记',
                          style: AppType.headline.copyWith(color: p.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          '记下今天的一天吧',
                          style: AppType.body.copyWith(color: p.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        FilledButton.icon(
                          onPressed: () => context.openDiaryEditor(),
                          icon: PhosphorIcon(
                            PhosphorIconsRegular.penNib,
                            size: 18,
                            color: p.onPrimary,
                          ),
                          label: const Text('写一篇'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < list.length; i++)
                  StaggeredEntrance(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page, 0, AppSpacing.page, AppSpacing.s8,
                      ),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.rLg),
                          onTap: () => context.openDiaryDetail(list[i].id),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.cardPad),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        list[i].title.isEmpty
                                            ? list[i].summary
                                            : list[i].title,
                                        style: AppType.headline
                                            .copyWith(color: p.onSurface),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (list[i].moodId != null &&
                                        moodMap[list[i].moodId!] != null) ...[
                                      const SizedBox(width: AppSpacing.s8),
                                      MoodDot(
                                        color: MoodPalette.colorOf(
                                          moodMap[list[i].moodId!]!.hue,
                                          dark: dark,
                                        ),
                                      ),
                                    ],
                                    Text(
                                      DateFormat('M月d日').format(
                                        DateTime(
                                          list[i].dateDay ~/ 10000,
                                          (list[i].dateDay ~/ 100) % 100,
                                          list[i].dateDay % 100,
                                        ),
                                      ),
                                      style: AppType.caption
                                          .copyWith(color: p.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                                if (list[i].title.isNotEmpty &&
                                    list[i].summary.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    list[i].summary,
                                    style: AppType.body
                                        .copyWith(color: p.onSurfaceVariant),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

