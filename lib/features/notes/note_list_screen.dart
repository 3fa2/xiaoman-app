import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/note.dart';
import '../../domain/repositories/repositories.dart';
import '../shared/widgets.dart';

/// 该笔记本下的笔记列表 + 置顶 + 搜索入口。
class NoteListScreen extends ConsumerStatefulWidget {
  const NoteListScreen({super.key, required this.notebookId});

  final int notebookId;

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen> {
  bool _searchMode = false;
  String _query = '';
  List<Note>? _searchResults;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final repo = ref.watch(noteRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchMode
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜笔记',
                  border: InputBorder.none,
                  filled: false,
                ),
                style: AppType.body.copyWith(color: p.onSurface),
                onChanged: (v) async {
                  setState(() => _query = v);
                  if (v.isEmpty) return;
                  final r = await repo.searchNotes(v);
                  if (mounted) setState(() => _searchResults = r);
                },
              )
            : const Text('备忘'),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _searchMode = !_searchMode;
              _query = '';
              _searchResults = null;
            }),
            icon: PhosphorIcon(
              _searchMode
                  ? PhosphorIconsRegular.x
                  : PhosphorIconsRegular.magnifyingGlass,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.openNoteEditor(notebookId: widget.notebookId),
        child: PhosphorIcon(
          PhosphorIconsRegular.plus,
          color: p.onPrimary,
          weight: 1.5,
        ),
      ),
      body: _searchMode ? _searchBody() : _listBody(repo),
    );
  }

  Widget _searchBody() {
    if (_query.isEmpty) {
      return const EmptyState(
        icon: PhosphorIconsRegular.magnifyingGlass,
        title: '输入关键词搜索',
        hint: '搜标题、正文和标签',
      );
    }
    if (_searchResults == null) return const SkeletonList();
    if (_searchResults!.isEmpty) {
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
      itemCount: _searchResults!.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        child: _NoteTile(note: _searchResults![i]),
      ),
    );
  }

  Widget _listBody(NoteRepository repo) {
    return StreamBuilder<List<Note>>(
      stream: repo.watchNotes(widget.notebookId),
      builder: (context, snap) {
        final list = snap.data ?? const <Note>[];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: SkeletonList(),
          );
        }
        if (list.isEmpty) {
          return const EmptyState(
            icon: PhosphorIconsRegular.sticker,
            title: '还没有笔记',
            hint: '点右下角加号记一条',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => StaggeredEntrance(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: _NoteTile(note: list[i]),
            ),
          ),
        );
      },
    );
  }
}

class _NoteTile extends ConsumerWidget {
  const _NoteTile({required this.note});

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
                  if (note.pinned) ...[
                    PhosphorIcon(
                      PhosphorIconsFill.pushPin,
                      size: 14,
                      color: p.primary,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                  ],
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? note.summary : note.title,
                      style: AppType.headline.copyWith(color: p.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref
                        .read(noteRepoProvider)
                        .setPinned(noteId: note.id, pinned: !note.pinned),
                    child: PhosphorIcon(
                      note.pinned
                          ? PhosphorIconsFill.pushPin
                          : PhosphorIconsRegular.pushPin,
                      size: 18,
                      color: note.pinned ? p.primary : p.onSurfaceVariant,
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
