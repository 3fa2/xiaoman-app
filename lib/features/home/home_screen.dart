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
import '../../domain/models/todo.dart';
import '../../domain/services/rrule_service.dart';
import '../shared/widgets.dart';

/// 首页 · S2 Bento（v5.0.1）：全宽心情卡 + 左「今日日记」右「日程/待办」不等高网格。
/// 骨架无彩色：卡片只灰阶，彩色只在心情点/日程块内（v4 设计三铁律）。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayDay = today.year * 10000 + today.month * 100 + today.day;
    final blocks = ref.watch(scheduleRepoProvider).watchDay(todayDay);
    final diaries = ref.watch(diaryRepoProvider).watchAll();
    final moods = ref.watch(diaryRepoProvider).watchMoods();
    final todos = ref.watch(todoRepoProvider).watchAll();

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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
        ),
        children: [
          // ① 此刻心情（全宽卡）
          _MoodBento(moods: moods, diaries: diaries),
          const SizedBox(height: AppSpacing.s12),
          // ② 不等高网格：左「今日日记」高卡 + 右「日程/待办」竖排
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _TodayDiariesBento(stream: diaries, moods: moods),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(child: _ScheduleBento(stream: blocks)),
                      const SizedBox(height: AppSpacing.s12),
                      Expanded(child: _TodoBento(stream: todos)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 卡片容器（bento 网格内统一无 margin）
class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pad = Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      child: child,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: onTap == null
          ? pad
          : InkWell(
              borderRadius: BorderRadius.circular(AppRadii.rLg),
              onTap: onTap,
              child: pad,
            ),
    );
  }
}

/// 卡片标题行：标题 + 右侧补充（计数/动作）
class _CardHead extends StatelessWidget {
  const _CardHead({
    required this.title,
    this.sub,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.s12),
  });
  final String title;
  final String? sub;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            title,
            style: AppType.headline.copyWith(color: p.onSurface),
          ),
          if (sub != null) ...[
            const SizedBox(width: AppSpacing.s8),
            Text(
              sub!,
              style: AppType.caption.copyWith(color: p.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────── ① 此刻心情卡 ───────────────────────────

class _MoodBento extends ConsumerWidget {
  const _MoodBento({required this.moods, required this.diaries});

  final Stream<List<Mood>> moods;
  final Stream<List<Diary>> diaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BentoCard(
      child: _MoodCheckin(moods: moods, diaries: diaries),
    );
  }
}

/// 心情打卡（原首页组件，去掉外 Padding 以适配卡片内布局）
class _MoodCheckin extends ConsumerStatefulWidget {
  const _MoodCheckin({required this.moods, required this.diaries});

  final Stream<List<Mood>> moods;
  final Stream<List<Diary>> diaries;

  @override
  ConsumerState<_MoodCheckin> createState() => _MoodCheckinState();
}

class _MoodCheckinState extends ConsumerState<_MoodCheckin> {
  /// 0=今天, 1=昨天（可补昨天的心情）
  int _dayOffset = 0;

  int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<Mood>>(
      stream: widget.moods,
      builder: (context, moodSnap) {
        final moods = moodSnap.data ?? const <Mood>[];
        return StreamBuilder<List<Diary>>(
          stream: widget.diaries,
          builder: (context, snap) {
            final all = snap.data ?? const <Diary>[];
            final now = DateTime.now();
            final targetDate = now.subtract(Duration(days: _dayOffset));
            final targetDay = _dayKey(targetDate);
            final targetDiaries =
                all.where((d) => d.dateDay == targetDay).toList();
            // 同日多篇：取最新创建且带心情的一篇作为"当日心情"
            final withMood = targetDiaries
                .where((d) => d.moodId != null)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final current =
                withMood.isEmpty ? null : withMood.first.moodId;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHead(
                  title: '此刻心情',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DayToggle(
                        label: '今天',
                        selected: _dayOffset == 0,
                        onTap: () => setState(() => _dayOffset = 0),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      _DayToggle(
                        label: '昨天',
                        selected: _dayOffset == 1,
                        onTap: () => setState(() => _dayOffset = 1),
                      ),
                    ],
                  ),
                ),
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
                          // 写入目标必须与上方读取目标一致（最新创建且带心情的一篇），
                          // 否则同日多篇时点心情会写进旧日记、界面看起来"没反应"
                          final target = withMood.isNotEmpty
                              ? withMood.first
                              : (targetDiaries.isEmpty
                                  ? null
                                  : targetDiaries.first);
                          final repo = ref.read(diaryRepoProvider);
                          if (target == null) {
                            // 当日无日记：先建一条，只记心情
                            final id = await repo.save(
                              id: null,
                              title: '',
                              content: '',
                              extra: m.id,
                            );
                            await repo.setMood(diaryId: id, moodId: m.id);
                          } else {
                            await repo.setMood(
                              diaryId: target.id,
                              moodId: current == m.id ? null : m.id,
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 今天/昨天切换小按钮
class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionDuration.fast,
        curve: MotionCurve.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.rSm),
        ),
        child: Text(
          label,
          style: AppType.label.copyWith(
            color: selected ? p.onPrimary : p.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
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

// ─────────────────────────── ② 今日日记卡 ───────────────────────────

class _TodayDiariesBento extends StatelessWidget {
  const _TodayDiariesBento({required this.stream, required this.moods});

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
            final now = DateTime.now();
            final todayDay = now.year * 10000 + now.month * 100 + now.day;
            final list = (snap.data ?? const <Diary>[])
                .where((d) => d.dateDay == todayDay)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final shown = list.take(4).toList();

            return _BentoCard(
              onTap: shown.isEmpty ? () => context.openDiaryEditor() : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHead(
                    title: '今日日记',
                    sub: list.isEmpty ? null : '${list.length} 篇',
                    trailing: TextActionButton(
                      label: '全部',
                      onPressed: () => context.openDiarySearch(),
                    ),
                  ),
                  if (shown.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.penNib,
                              size: 22,
                              color: p.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              '今天还没记',
                              style: AppType.body
                                  .copyWith(color: p.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              '点这里写一篇',
                              style: AppType.caption
                                  .copyWith(color: p.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < shown.length; i++) ...[
                      _DiaryLine(
                        diary: shown[i],
                        moodColor: shown[i].moodId != null &&
                                moodMap[shown[i].moodId!] != null
                            ? MoodPalette.colorOf(
                                moodMap[shown[i].moodId!]!.hue,
                                dark: dark,
                              )
                            : null,
                      ),
                      if (i != shown.length - 1)
                        const Divider(height: 1, indent: 0),
                    ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 今日日记卡内单行
class _DiaryLine extends StatelessWidget {
  const _DiaryLine({required this.diary, required this.moodColor});
  final Diary diary;
  final Color? moodColor;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final created = diary.createdAt;
    final sameDay = created.year == now.year &&
        created.month == now.month &&
        created.day == now.day;
    return InkWell(
      onTap: () => context.openDiaryDetail(diary.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            if (moodColor != null) ...[
              MoodDot(color: moodColor!),
              const SizedBox(width: AppSpacing.s8),
            ],
            Expanded(
              child: Text(
                diary.title.isEmpty ? diary.summary : diary.title,
                style: AppType.body.copyWith(
                  color: p.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              sameDay
                  ? DateFormat('HH:mm').format(created)
                  : DateFormat('M月d日').format(created),
              style: AppType.caption.copyWith(color: p.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── ③ 今日日程卡 ───────────────────────────

class _ScheduleBento extends StatelessWidget {
  const _ScheduleBento({required this.stream});

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
        final list = (snap.data ?? const <ScheduleInstance>[]).where(
          (b) =>
              b.status == BlockStatus.pending &&
              b.dateDay == todayDay &&
              b.endMinutes >= nowMinutes,
        ).toList();
        final next = list.isEmpty
            ? null
            : list.reduce((a, b) =>
                a.startMinutes <= b.startMinutes ? a : b);

        return _BentoCard(
          onTap: () => context.push('/schedule'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHead(title: '今日日程', padding: EdgeInsets.zero),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${list.length}',
                    style: AppType.display.copyWith(
                      color: p.primary,
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '项待办',
                      style: AppType.caption.copyWith(
                        color: p.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                next == null
                    ? '今天没有安排了'
                    : '下一项 ${formatMinutes(next.startMinutes)}',
                style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── ④ 待办卡 ───────────────────────────

class _TodoBento extends StatelessWidget {
  const _TodoBento({required this.stream});

  final Stream<List<Todo>> stream;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return StreamBuilder<List<Todo>>(
      stream: stream,
      builder: (context, snap) {
        final open = (snap.data ?? const <Todo>[])
            .where((t) => !t.done)
            .toList();
        final shown = open.take(2).toList();

        return _BentoCard(
          onTap: () => context.go('/todo'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHead(title: '待办', padding: EdgeInsets.zero),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${open.length}',
                    style: AppType.display.copyWith(
                      color: p.primary,
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '未完成',
                      style: AppType.caption.copyWith(
                        color: p.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                shown.isEmpty
                    ? '全部完成'
                    : shown.map((t) => t.title).join(' · '),
                style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}