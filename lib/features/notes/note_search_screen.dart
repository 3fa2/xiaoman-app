import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/note.dart';
import '../shared/widgets.dart';

/// 全局笔记搜索：跨笔记本搜标题/正文/标签（FTS5 + LIKE 回退）+ 历史 + 高亮。
/// 入口在备忘主页 AppBar 的放大镜。
class NoteSearchScreen extends ConsumerStatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  ConsumerState<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends ConsumerState<NoteSearchScreen> {
  String _query = '';
  List<Note>? _results;
  int _seq = 0; // 请求序号：慢查询返回晚于新查询时丢弃过期结果
  List<String> _history = const [];

  static const _historyKey = 'note_search_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    // 退出时记最后一次查询（按击键记录会存下一串输入前缀）
    final q = _query.trim();
    if (q.isNotEmpty) {
      final next = [q, ..._history.where((h) => h != q)].take(8).toList();
      unawaited(
        ref.read(settingsRepoProvider).set(_historyKey, jsonEncode(next)),
      );
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final raw = await ref.read(settingsRepoProvider).get(_historyKey);
    if (!mounted) return;
    setState(() {
      _history = (jsonDecode(raw ?? '[]') as List).cast<String>();
    });
  }

  Future<void> _removeHistory(String h) async {
    setState(() => _history = _history.where((x) => x != h).toList());
    await ref.read(settingsRepoProvider).set(_historyKey, jsonEncode(_history));
  }

  void _run(String v) async {
    setState(() => _query = v);
    if (v.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    final seq = ++_seq;
    final r = await ref.read(noteRepoProvider).searchNotes(v);
    if (!mounted || seq != _seq) return;
    setState(() => _results = r);
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜所有笔记的标题、正文、标签',
            border: InputBorder.none,
            filled: false,
          ),
          style: AppType.body.copyWith(color: p.onSurface),
          onChanged: _run,
        ),
      ),
      body: Column(
        children: [
          if (_query.trim().isEmpty && _history.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                children: [
                  for (final h in _history)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.s8),
                      child: InputChip(
                        label: Text(h),
                        onDeleted: () => _removeHistory(h),
                        onPressed: () => _run(h),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    // trim 后判断：纯空格输入不当"有关键词"，否则 _results 恒 null 卡骨架屏
    if (_query.trim().isEmpty) {
      return const EmptyState(
        icon: PhosphorIconsRegular.magnifyingGlass,
        title: '输入关键词搜索',
        hint: '跨所有笔记本，搜标题、正文和标签',
      );
    }
    if (_results == null) return const SkeletonList();
    if (_results!.isEmpty) {
      return const EmptyState(
        icon: PhosphorIconsRegular.magnifyingGlass,
        title: '没搜到',
        hint: '换个词试试',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
      ),
      itemCount: _results!.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        child: _NoteResultTile(note: _results![i], query: _query),
      ),
    );
  }
}

class _NoteResultTile extends ConsumerWidget {
  const _NoteResultTile({required this.note, this.query = ''});

  final Note note;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        onTap: () => context.openNoteEditor(
          noteId: note.id,
          notebookId: note.notebookId,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: HighlightText(
                      text: note.title.isEmpty ? note.summary : note.title,
                      query: query,
                      style: AppType.headline.copyWith(color: p.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (note.summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                HighlightText(
                  text: note.summary,
                  query: query,
                  style: AppType.body.copyWith(color: p.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: AppSpacing.s4,
                  children: [
                    for (final t in note.tags)
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
      ),
    );
  }
}
