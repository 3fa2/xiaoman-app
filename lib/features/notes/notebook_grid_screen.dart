import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/note.dart';
import '../shared/widgets.dart';

/// 笔记本网格：自定义颜色 + 新建/重命名/删除。
/// 颜色边界：笔记本色只在卡片色条与色点里出现，不外溢。
class NotebookGridScreen extends ConsumerStatefulWidget {
  const NotebookGridScreen({super.key});

  @override
  ConsumerState<NotebookGridScreen> createState() =>
      _NotebookGridScreenState();
}

class _NotebookGridScreenState extends ConsumerState<NotebookGridScreen> {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('备忘'),
        actions: [
          IconButton(
            onPressed: () => context.openNoteSearch(),
            tooltip: '搜索所有笔记',
            icon: PhosphorIcon(
              PhosphorIconsRegular.magnifyingGlass,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      floatingActionButton: AppFab(
        icon: PhosphorIconsRegular.folderPlus,
        tooltip: '新建笔记本',
        onPressed: () => _editNotebook(context, null),
      ),
      body: StreamBuilder<List<Notebook>>(
        stream: ref.watch(noteRepoProvider).watchNotebooks(),
        builder: (context, snap) {
          final list = snap.data ?? const <Notebook>[];
          if (list.isEmpty) {
            return EmptyState(
              icon: PhosphorIconsRegular.sticker,
              title: '还没有笔记本',
              hint: '笔记本用来分类收纳，可以选颜色区分',
              actionLabel: '新建笔记本',
              onAction: () => _editNotebook(context, null),
              // 快捷示例：一键创建常用笔记本，别让用户对着空白发呆
              examples: [
                (
                  '建「灵感」',
                  () => ref
                      .read(noteRepoProvider)
                      .saveNotebook(id: null, name: '灵感', colorIndex: 1),
                ),
                (
                  '建「待办」',
                  () => ref
                      .read(noteRepoProvider)
                      .saveNotebook(id: null, name: '待办', colorIndex: 2),
                ),
                (
                  '建「读书笔记」',
                  () => ref
                      .read(noteRepoProvider)
                      .saveNotebook(id: null, name: '读书笔记', colorIndex: 3),
                ),
              ],
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.s12,
              crossAxisSpacing: AppSpacing.s12,
              childAspectRatio: 1.45,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final nb = list[i];
              final color = NotebookPalette.resolve(nb.colorIndex, dark: dark);
              return StaggeredEntrance(
                index: i,
                child: PressableScale(
                  onTap: () => context.openNoteList(nb.id),
                  onLongPress: () => _notebookActions(context, nb),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MoodDot(color: color, size: 10),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _notebookActions(context, nb),
                                child: PhosphorIcon(
                                  PhosphorIconsRegular.dotsThree,
                                  size: 18,
                                  color: p.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            nb.name,
                            style: AppType.headline.copyWith(color: p.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          StreamBuilder<int>(
                            stream:
                                ref.read(noteRepoProvider).watchNoteCount(nb.id),
                            builder: (context, cnt) => Text(
                              '${cnt.data ?? 0} 条',
                              style: AppType.caption.copyWith(
                                color: p.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _notebookActions(BuildContext context, Notebook nb) {
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
                _editNotebook(context, nb);
              },
            ),
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.trash,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                '删除笔记本',
                style: AppType.body.copyWith(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showConfirmSheet(
                  context,
                  title: '删除「${nb.name}」？',
                  message: '里面所有笔记都会一起删除，找不回来',
                );
                if (ok) {
                  await ref.read(noteRepoProvider).deleteNotebook(nb.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNotebook(BuildContext context, Notebook? nb) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: nb?.name ?? '');
    var colorIndex = nb?.colorIndex ?? 0;
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
                nb == null ? '新建笔记本' : '编辑笔记本',
                style: AppType.headline.copyWith(color: p.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              TextField(
                controller: nameCtrl,
                autofocus: nb == null,
                decoration: const InputDecoration(labelText: '名称'),
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
                              ? Border.all(
                                  color: p.primary,
                                  width: 2.5,
                                )
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
        .read(noteRepoProvider)
        .saveNotebook(id: nb?.id, name: name, colorIndex: colorIndex);
  }
}
