import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../../domain/models/media.dart';
import '../shared/widgets.dart';

/// 日记回收站（v5.3）：软删除的日记在这里，可恢复或彻底删除；
/// 超过 30 天的条目在 App 启动时自动清理（含媒体文件）。
class DiaryRecycleBinScreen extends ConsumerWidget {
  const DiaryRecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleted = ref.watch(diaryRepoProvider).watchDeleted();

    return Scaffold(
      appBar: AppBar(title: const Text('回收站')),
      body: StreamBuilder<List<Diary>>(
        stream: deleted,
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
              child: _TrashCard(diary: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TrashCard extends ConsumerWidget {
  const _TrashCard({required this.diary});

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
                        ? (diary.summary.isEmpty ? DateFormat('M月d日', 'zh_CN').format(d) : diary.summary)
                        : diary.title,
                    style: AppType.body.copyWith(color: p.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '记于 ${DateFormat('yyyy年M月d日', 'zh_CN').format(d)}'
                    '${daysLeft == null ? '' : ' · $daysLeft 天后自动清除'}',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
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
