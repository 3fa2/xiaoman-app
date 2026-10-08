import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../../domain/models/media.dart';
import '../../domain/models/note.dart';
import '../shared/widgets.dart';

/// 回收站（v5.3 日记 / v5.4 备忘）：软删除的内容在这里，
/// 可恢复或彻底删除；超过 30 天的条目在 App 启动时自动清理。
class DiaryRecycleBinScreen extends ConsumerStatefulWidget {
  const DiaryRecycleBinScreen({super.key});

  @override
  ConsumerState<DiaryRecycleBinScreen> createState() =>
      _DiaryRecycleBinScreenState();
}

class _DiaryRecycleBinScreenState extends ConsumerState<DiaryRecycleBinScreen> {
  int _tab = 0; // 0=日记 1=备忘

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('回收站')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, 0,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('日记')),
                ButtonSegment(value: 1, label: Text('备忘')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: _tab == 0
                ? const _DiaryTrashList()
                : const _NoteTrashList(),
          ),
        ],
      ),
    );
  }
}

class _DiaryTrashList extends ConsumerWidget {
  const _DiaryTrashList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Diary>>(
      stream: ref.watch(diaryRepoProvider).watchDeleted(),
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
            icon: PhosphorIconsRegular.trash,
            title: '回收站是空的',
            hint: '删掉的日记会在这里保留 30 天',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: _DiaryTrashCard(diary: list[i]),
          ),
        );
      },
    );
  }
}

class _DiaryTrashCard extends ConsumerWidget {
  const _DiaryTrashCard({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final d = DateTime(
      diary.dateDay ~/ 10000, (diary.dateDay ~/ 100) % 100, diary.dateDay % 100,
    );
    final deletedAt = diary.deletedAt;
    final daysLeft = deletedAt == null
        ? null
        : 30 - DateTime.now().difference(deletedAt).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diary.title.isEmpty
                        ? (diary.summary.isEmpty
                            ? DateFormat('M月d日', 'zh_CN').format(d)
                            : diary.summary)
                        : diary.title,
                    style: AppType.body.copyWith(color: p.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '记于 ${DateFormat('yyyy年M月d日', 'zh_CN').format(d)}'
                    '${daysLeft == null ? '' : ' · $daysLeft 天后自动清除'}',
                    style: AppType.caption.copyWith(
                      color: p.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(diaryRepoProvider).restoreDiary(diary.id),
              child: const Text('恢复'),
            ),
            IconButton(
              tooltip: '彻底删除',
              onPressed: () async {
                final ok = await showConfirmSheet(
                  context,
                  title: '彻底删除？',
                  message: '这篇日记和它的照片/视频将无法找回',
                );
                if (!ok) return;
                // 级联清媒体文件（软删除时保留了）
                final items = await ref
                    .read(mediaRepoProvider)
                    .listFor(MediaOwner.diary, diary.id);
                for (final m in items) {
                  await ref.read(mediaRepoProvider).remove(m.id);
                }
                await ref.read(diaryRepoProvider).purgeDiary(diary.id);
              },
              icon: PhosphorIcon(
                PhosphorIconsRegular.trash,
                size: 18,
                color: p.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTrashList extends ConsumerWidget {
  const _NoteTrashList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Note>>(
      stream: ref.watch(noteRepoProvider).watchDeletedNotes(),
      builder: (context, snap) {
        final list = snap.data ?? const <Note>[];
        if (snap.connectionState == ConnectionState.waiting && list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: SkeletonList(),
          );
        }
        if (list.isEmpty) {
          return const EmptyState(
            icon: PhosphorIconsRegular.trash,
            title: '备忘回收站是空的',
            hint: '删掉的笔记会在这里保留 30 天',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: _NoteTrashCard(note: list[i]),
          ),
        );
      },
    );
  }
}

class _NoteTrashCard extends ConsumerWidget {
  const _NoteTrashCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final deletedAt = note.deletedAt;
    final daysLeft = deletedAt == null
        ? null
        : 30 - DateTime.now().difference(deletedAt).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? note.summary : note.title,
                    style: AppType.body.copyWith(color: p.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '删于 ${DateFormat('M月d日 HH:mm', 'zh_CN').format(deletedAt!)}'
                    ' · $daysLeft 天后自动清除',
                    style: AppType.caption.copyWith(
                      color: p.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => ref.read(noteRepoProvider).restoreNote(note.id),
              child: const Text('恢复'),
            ),
            IconButton(
              tooltip: '彻底删除',
              onPressed: () async {
                final ok = await showConfirmSheet(
                  context,
                  title: '彻底删除？',
                  message: '这条笔记和它的清单子项将无法找回',
                );
                if (!ok) return;
                await ref.read(noteRepoProvider).purgeNote(note.id);
              },
              icon: PhosphorIcon(
                PhosphorIconsRegular.trash,
                size: 18,
                color: p.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
