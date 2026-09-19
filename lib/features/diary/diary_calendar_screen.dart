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
        onPressed: () => context.openDiaryEditor(null, _notebookFilter),
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
                      return const EmptyState(
                        icon: PhosphorIconsRegular.notebook,
                        title: '这一天还没有日记',
                        hint: '点右下角的笔写下今天，也可以插照片、记心情',
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    // 无标题无正文（纯图片日记）时的占位文案
    final headText = diary.title.isNotEmpty
        ? diary.title
        : (diary.summary.isNotEmpty ? diary.summary : '图片日记');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        onTap: () => context.openDiaryDetail(diary.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          child: Row(
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
                              color: headText == '图片日记'
                                  ? p.onSurfaceVariant
                                  : p.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mood != null) ...[
                          const SizedBox(width: AppSpacing.s8),
                          MoodDot(
                            color: MoodPalette.colorOf(mood!.hue, dark: dark),
                            label: mood!.name,
                          ),
                        ],
                      ],
                    ),
                    if (diary.title.isNotEmpty && diary.summary.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        diary.summary,
                        style: AppType.body.copyWith(color: p.onSurfaceVariant),
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
                                borderRadius: BorderRadius.circular(AppRadii.rSm),
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
              // 媒体缩略图（第一张）：纯图片日记的主要内容
              FutureBuilder<List<MediaItem>>(
                future: ref
                    .read(mediaRepoProvider)
                    .listFor(MediaOwner.diary, diary.id),
                builder: (context, snap) {
                  final items = snap.data ?? const <MediaItem>[];
                  if (items.isEmpty) return const SizedBox.shrink();
                  final m = items.first;
                  final path = m.thumbPath ?? m.coverPath;
                  if (path == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.s8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.rSm),
                      child: Image.file(
                        File(path),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        cacheWidth: 56,
                        cacheHeight: 56,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
