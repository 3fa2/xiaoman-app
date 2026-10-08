import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../../domain/models/media.dart';
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

  /// 当前日记本过滤：null = 所有日记，-1 = 未归本，>0 = 具体本
  int? _notebookFilter;
  String _filterName = '所有日记';

  static int _dayOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final listMode = ref.watch(diaryViewModeProvider);
    final month = _focused.year * 100 + _focused.month;
    final diaries =
        ref.watch(diaryRepoProvider).watchByMonthIn(month, _notebookFilter);
    final dayList =
        ref.watch(diaryRepoProvider).watchByDateIn(_selectedDay, _notebookFilter);
    final moods = ref.watch(diaryRepoProvider).watchMoods();

    return Scaffold(
      appBar: AppBar(
        title: Text(_filterName),
        actions: [
          // 日历/时间线切换
          IconButton(
            onPressed: () => ref.read(diaryViewModeProvider.notifier).state =
                !listMode,
            tooltip: listMode ? '日历视图' : '时间线视图',
            icon: PhosphorIcon(
              listMode
                  ? PhosphorIconsRegular.calendarBlank
                  : PhosphorIconsRegular.listDashes,
              color: p.onSurfaceVariant,
            ),
          ),
          // 统计入口带文字，不再让用户猜图标是干嘛的
          TextButton.icon(
            onPressed: () => context.openMoodTrend(),
            icon: PhosphorIcon(
              PhosphorIconsRegular.chartLineUp,
              size: 18,
              color: p.primary,
            ),
            label: Text(
              '心情统计',
              style: AppType.label.copyWith(color: p.primary),
            ),
          ),
          IconButton(
            onPressed: () => context.openDiarySearch(),
            tooltip: '搜索日记',
            icon: PhosphorIcon(
              PhosphorIconsRegular.magnifyingGlass,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, dark),
      floatingActionButton: AppFab(
        icon: PhosphorIconsRegular.notePencil,
        tooltip: '写日记',
        // 日历模式写选中的那天（选了过去某天即补记）；时间线模式写今天
        onPressed: () {
          final n = DateTime.now();
          final today = n.year * 10000 + n.month * 100 + n.day;
          context.openDiaryEditor(
            null,
            _notebookFilter,
            listMode ? today : _selectedDay,
          );
        },
      ),
      body: listMode
          ? _buildTimeline(p, dark)
          : Column(
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
                    // 按天分组：有日记就标记点（有心情用心情色，无心情用灰点）
                    final diariesByDay = <int, List<Diary>>{};
                    final moodByDay = <int, Mood?>{};
                    for (final d in list) {
                      diariesByDay.putIfAbsent(d.dateDay, () => []).add(d);
                      if (d.moodId != null && moodByDay[d.dateDay] == null) {
                        moodByDay[d.dateDay] = moodMap[d.moodId!];
                      }
                    }
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
                        // 选中日高亮：primary 实底圆 + 白字，对比拉满一眼可见
                        selectedDecoration: BoxDecoration(
                          color: p.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: p.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.primary, width: 1.5),
                        ),
                        selectedTextStyle:
                            AppType.body.copyWith(color: p.onPrimary),
                        todayTextStyle:
                            AppType.body.copyWith(color: p.onSurface),
                        defaultTextStyle:
                            AppType.body.copyWith(color: p.onSurface),
                        weekendTextStyle:
                            AppType.body.copyWith(color: p.onSurface),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final day = _dayOf(date);
                          final diaries = diariesByDay[day];
                          if (diaries == null || diaries.isEmpty) return null;
                          // 有日记就显示点：有心情→心情色点，无心情→灰色小点
                          final mood = moodByDay[day];
                          return Positioned(
                            bottom: 4,
                            child: MoodDot(
                              color: mood != null
                                  ? MoodPalette.colorOf(mood.hue, dark: dark)
                                  : p.onSurfaceVariant,
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
            child: StreamBuilder<List<Mood>>(
              stream: moods,
              builder: (context, moodSnap) {
                final moodMap = {
                  for (final m in (moodSnap.data ?? const <Mood>[])) m.id: m,
                };
                return StreamBuilder<List<Diary>>(
                  stream: dayList,
                  builder: (context, snap) {
                    final list = snap.data ?? const <Diary>[];
                    if (list.isEmpty) {
                      return EmptyState(
                        icon: PhosphorIconsRegular.notebook,
                        title: '这一天还没有日记',
                        hint: '点右下角的笔写下今天，也可以插照片、记心情',
                        actionLabel: '补记这一天的日记',
                        onAction: () => context.openDiaryEditor(
                          null, _notebookFilter, _selectedDay,
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page, 0, AppSpacing.page, AppSpacing.listBottom,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: _DiaryCard(
                          diary: list[i],
                          mood: list[i].moodId == null
                              ? null
                              : moodMap[list[i].moodId!],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- 时间线列表模式（v5.3）：按月分组的全部日记 ----
  Widget _buildTimeline(ColorScheme p, bool dark) {
    return StreamBuilder<List<Diary>>(
      stream: ref.watch(diaryRepoProvider).watchAll(),
      builder: (context, snap) {
        final list = snap.data ?? const <Diary>[];
        if (snap.connectionState == ConnectionState.waiting && list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: SkeletonList(),
          );
        }
        if (list.isEmpty) {
          return const EmptyState(
            icon: PhosphorIconsRegular.notebook,
            title: '还没有日记',
            hint: '点右下角的笔写下第一篇',
          );
        }
        return StreamBuilder<List<Mood>>(
          stream: ref.watch(diaryRepoProvider).watchMoods(),
          builder: (context, moodSnap) {
            final moodMap = {
              for (final m in (moodSnap.data ?? const <Mood>[])) m.id: m,
            };
            // watchAll 已按 dateDay desc；同日内保持库序（创建序）
            final groups = <int, List<Diary>>{};
            for (final d in list) {
              groups.putIfAbsent(d.dateDay ~/ 100, () => []).add(d);
            }
            final months = groups.keys.toList()..sort((a, b) => b.compareTo(a));
            final children = <Widget>[];
            for (final m in months) {
              final items = groups[m]!;
              children.add(Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  m == months.first ? AppSpacing.s8 : AppSpacing.s16,
                  AppSpacing.page,
                  AppSpacing.s8,
                ),
                child: Text(
                  '${m ~/ 100} 年 ${m % 100} 月 · ${items.length} 篇',
                  style: AppType.headline.copyWith(color: p.onSurface),
                ),
              ));
              for (final d in items) {
                children.add(Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, 0, AppSpacing.page, AppSpacing.s8,
                  ),
                  child: _DiaryCard(
                    diary: d,
                    mood: d.moodId == null ? null : moodMap[d.moodId!],
                  ),
                ));
              }
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.listBottom),
              children: children,
            );
          },
        );
      },
    );
  }

  // ---- 日记本抽屉（v4.3 自建分类）----

  void _applyFilter(int? notebookId, String name) {
    setState(() {
      _notebookFilter = notebookId;
      _filterName = name;
    });
    Navigator.of(context).pop(); // 关抽屉
  }

  Widget _buildDrawer(BuildContext context, bool dark) {
    final p = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page, AppSpacing.s16, AppSpacing.page, AppSpacing.s8,
              ),
              child: Text(
                '日记本',
                style: AppType.title.copyWith(color: p.onSurface),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<(DiaryNotebook, int)>>(
                stream: ref.watch(diaryRepoProvider).watchDiaryNotebooks(),
                builder: (context, snap) {
                  final list = snap.data ?? const <(DiaryNotebook, int)>[];
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                    ),
                    children: [
                      ListTile(
                        leading: PhosphorIcon(
                          PhosphorIconsRegular.stack,
                          color: p.primary,
                        ),
                        title: Text('所有日记'),
                        selected: _notebookFilter == null,
                        onTap: () => _applyFilter(null, '所有日记'),
                      ),
                      for (final (nb, count) in list)
                        ListTile(
                          leading: MoodDot(
                            color: NotebookPalette.resolve(
                              nb.colorIndex,
                              dark: dark,
                            ),
                            size: 10,
                          ),
                          title: Text(nb.name),
                          trailing: Text(
                            '$count',
                            style: AppType.caption.copyWith(
                              color: p.onSurfaceVariant,
                            ),
                          ),
                          selected: _notebookFilter == nb.id,
                          onTap: () => _applyFilter(nb.id, nb.name),
                          onLongPress: () =>
                              _diaryNotebookActions(context, nb),
                        ),
                      ListTile(
                        leading: PhosphorIcon(
                          PhosphorIconsRegular.plusCircle,
                          color: p.onSurfaceVariant,
                        ),
                        title: Text(
                          '新建日记本',
                          style: AppType.body.copyWith(
                            color: p.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => _editDiaryNotebook(context, null),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _diaryNotebookActions(BuildContext context, DiaryNotebook nb) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.pencilSimple),
              title: const Text('重命名 / 换色'),
              onTap: () {
                Navigator.pop(ctx);
                _editDiaryNotebook(context, nb);
              },
            ),
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.trash,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                '删除日记本',
                style: AppType.body.copyWith(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showConfirmSheet(
                  context,
                  title: '删除「${nb.name}」？',
                  message: '里面的日记不会删，会变回未归本',
                );
                if (ok) {
                  await ref
                      .read(diaryRepoProvider)
                      .deleteDiaryNotebook(nb.id);
                  if (_notebookFilter == nb.id && mounted) {
                    setState(() {
                      _notebookFilter = null;
                      _filterName = '所有日记';
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDiaryNotebook(BuildContext context, DiaryNotebook? nb) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: nb?.name ?? '');
    var colorIndex = nb?.colorIndex ?? 1;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page, 0, AppSpacing.page,
            AppSpacing.s24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                nb == null ? '新建日记本' : '编辑日记本',
                style: AppType.headline.copyWith(color: p.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              TextField(
                controller: nameCtrl,
                autofocus: nb == null,
                decoration: const InputDecoration(labelText: '名称，如：碎碎念'),
                style: AppType.body.copyWith(color: p.onSurface),
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s8,
                children: [
                  for (var i = 0; i < NotebookPalette.presets.length; i++)
                    GestureDetector(
                      onTap: () => setSheet(() => colorIndex = i),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: NotebookPalette.resolve(i, dark: dark),
                          border: colorIndex == i
                              ? Border.all(color: p.primary, width: 2.5)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    await ref
        .read(diaryRepoProvider)
        .saveDiaryNotebook(id: nb?.id, name: name, colorIndex: colorIndex);
  }
}

class _DiaryCard extends ConsumerWidget {
  const _DiaryCard({required this.diary, this.mood});

  final Diary diary;
  final Mood? mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    // 缩略图可能为 null（视频无 thumb 且无 cover），用守卫占位框代替 File(null) 崩溃
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        onTap: () => context.openDiaryDetail(diary.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          child: FutureBuilder<List<MediaItem>>(
            future: ref
                .read(mediaRepoProvider)
                .listFor(MediaOwner.diary, diary.id),
            builder: (context, snap) {
              final items = snap.data ?? const <MediaItem>[];
              final hasMedia = items.isNotEmpty;
              // 纯图片日记显示"图片日记"，纯心情打卡显示"心情打卡"
              final headText = diary.title.isNotEmpty
                  ? diary.title
                  : (diary.summary.isNotEmpty
                      ? diary.summary
                      : (hasMedia ? '图片日记' : '心情打卡'));
              final first = hasMedia ? items.first : null;
              final thumbPath = first == null
                  ? null
                  : (first.thumbPath ?? first.coverPath);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                headText,
                                style: AppType.headline.copyWith(
                                  color: headText == diary.title ||
                                          headText == diary.summary
                                      ? p.onSurface
                                      : p.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (mood != null) ...[
                              const SizedBox(width: AppSpacing.s8),
                              MoodChip(mood: mood!),
                            ],
                          ],
                        ),
                        if (diary.title.isNotEmpty &&
                            diary.summary.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            diary.summary,
                            style: AppType.body.copyWith(
                              color: p.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (diary.tags.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s8),
                          Wrap(
                            spacing: AppSpacing.s4,
                            children: [
                              for (final t in diary.tags)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.s8, vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.surfaceContainerHighest,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.rSm),
                                  ),
                                  child: Text(
                                    t,
                                    style: AppType.caption.copyWith(
                                      color: p.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasMedia)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.s8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.rSm),
                        child: thumbPath == null
                            ? Container(
                                width: 56,
                                height: 56,
                                color: p.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: PhosphorIcon(
                                  PhosphorIconsRegular.filmStrip,
                                  size: 20,
                                  color: p.onSurfaceVariant,
                                ),
                              )
                            : Image.file(
                                File(thumbPath),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                cacheWidth: 56,
                                cacheHeight: 56,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: p.surfaceContainerHighest,
                                ),
                              ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
