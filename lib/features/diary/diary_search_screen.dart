import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../shared/widgets.dart';

/// 日记全部/搜索：FTS5 全文检索 + 按心情筛选。
class DiarySearchScreen extends ConsumerStatefulWidget {
  const DiarySearchScreen({super.key});

  @override
  ConsumerState<DiarySearchScreen> createState() => _DiarySearchScreenState();
}

class _DiarySearchScreenState extends ConsumerState<DiarySearchScreen> {
  String _query = '';
  int? _moodFilter;
  String? _tagFilter;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    void setTag(String? t) => setState(() => _tagFilter = t);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜正文、标题（3 字以上全文检索）',
            border: InputBorder.none,
            filled: false,
          ),
          style: AppType.body.copyWith(color: p.onSurface),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: StreamBuilder<List<Mood>>(
              stream: ref.read(diaryRepoProvider).watchMoods(),
              builder: (context, snap) {
                final moods = snap.data ?? const <Mood>[];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.s8),
                      child: FilterChip(
                        label: const Text('全部'),
                        selected: _moodFilter == null,
                        onSelected: (_) =>
                            setState(() => _moodFilter = null),
                      ),
                    ),
                    for (final m in moods)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.s8),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MoodDot(
                                color: MoodPalette.colorOf(m.hue, dark: dark),
                              ),
                              const SizedBox(width: AppSpacing.s4),
                              Text(m.name),
                            ],
                          ),
                          selected: _moodFilter == m.id,
                          onSelected: (_) =>
                              setState(() => _moodFilter = m.id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _AllDiaries(
                    moodFilter: _moodFilter,
                    tagFilter: _tagFilter,
                    onTagFilter: setTag,
                  )
                : _SearchResults(
                    query: _query,
                    moodFilter: _moodFilter,
                    tagFilter: _tagFilter,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiaryTile extends StatelessWidget {
  const _DiaryTile({required this.diary});

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

class _AllDiaries extends ConsumerWidget {
  const _AllDiaries({
    required this.moodFilter,
    this.tagFilter,
    this.onTagFilter,
  });

  final int? moodFilter;
  final String? tagFilter;
  final ValueChanged<String?>? onTagFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Diary>>(
      stream: ref.watch(diaryRepoProvider).watchAll(),
      builder: (context, snap) {
        final all = snap.data ?? const <Diary>[];
        // 从全部日记里提取已用标签，供过滤
        final usedTags = <String>{};
        for (final d in all) {
          usedTags.addAll(d.tags);
        }
        final tagList = usedTags.toList()..sort();
        final list = all
            .where(
              (d) =>
                  (moodFilter == null || d.moodId == moodFilter) &&
                  (tagFilter == null || d.tags.contains(tagFilter)),
            )
            .toList();
        return Column(
          children: [
            if (tagList.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  children: [
                    for (final t in tagList)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.s8),
                        child: FilterChip(
                          label: Text(t),
                          selected: tagFilter == t,
                          onSelected: (_) =>
                              onTagFilter?.call(tagFilter == t ? null : t),
                        ),
                      ),
                  ],
                ),
              ),
            if (list.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  title: '没有匹配的日记',
                  hint: '换个心情或标签筛一筛',
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, AppSpacing.s8, AppSpacing.page,
                    AppSpacing.listBottom,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => StaggeredEntrance(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: _DiaryTile(diary: list[i]),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchResults extends ConsumerStatefulWidget {
  const _SearchResults({
    required this.query,
    required this.moodFilter,
    this.tagFilter,
  });

  final String query;
  final int? moodFilter;
  final String? tagFilter;

  @override
  ConsumerState<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<_SearchResults> {
  List<Diary>? _results;
  int _seq = 0; // 请求序号：慢查询返回晚于新查询时丢弃过期结果

  @override
  void didUpdateWidget(covariant _SearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _results = null;
      _run();
    }
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final q = widget.query;
    if (q.isEmpty) return;
    final seq = ++_seq;
    final r = await ref.read(diaryRepoProvider).search(q);
    if (!mounted || seq != _seq) return;
    setState(() => _results = r);
  }

  @override
  Widget build(BuildContext context) {
    if (_results == null) return const SkeletonList();
    final list = _results!
        .where(
          (d) =>
              (widget.moodFilter == null || d.moodId == widget.moodFilter) &&
              (widget.tagFilter == null ||
                  d.tags.contains(widget.tagFilter)),
        )
        .toList();
    if (list.isEmpty) {
      return const EmptyState(
        icon: PhosphorIconsRegular.magnifyingGlass,
        title: '没搜到相关内容',
        hint: '试试更短的关键词',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        child: _DiaryTile(diary: list[i]),
      ),
    );
  }
}
