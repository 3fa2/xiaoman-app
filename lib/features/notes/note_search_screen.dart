import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/note.dart';
import '../shared/widgets.dart';

/// 全局笔记搜索：跨笔记本搜标题/正文/标签（FTS5 + LIKE 回退）。
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
      body: _body(),
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
        child: _NoteResultTile(note: _results![i]),
      ),
    );
  }
}

class _NoteResultTile extends ConsumerWidget {
  const _NoteResultTile({required this.note});

  final Note note;

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
                    child: Text(
                      note.title.isEmpty ? note.summary : note.title,
                      style: AppType.headline.copyWith(color: p.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (note.summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Text(
                  note.summary,
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
