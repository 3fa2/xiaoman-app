import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../../domain/models/media.dart';
import '../shared/widgets.dart';

/// 日记详情：只读展示 + 实况长按播放 + 编辑/删除。
/// Hero：列表卡片 → 详情头块（tag = diary-cover-{id}）。
class DiaryDetailScreen extends ConsumerStatefulWidget {
  const DiaryDetailScreen({super.key, required this.diaryId});

  final int diaryId;

  @override
  ConsumerState<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends ConsumerState<DiaryDetailScreen> {
  VideoPlayerController? _player;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _play(MediaItem item) async {
    final old = _player;
    final player = VideoPlayerController.file(File(item.videoPath!));
    _player = player;
    await player.initialize();
    await player.setLooping(true);
    await player.play();
    if (mounted) {
      setState(() {});
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (ctx) => AspectRatio(
          aspectRatio: player.value.aspectRatio,
          child: VideoPlayer(player),
        ),
      );
    }
    old?.dispose();
    await player.pause();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final diary = ref.read(diaryRepoProvider).getById(widget.diaryId);
    final media = ref
        .read(mediaRepoProvider)
        .listFor(MediaOwner.diary, widget.diaryId);
    final moodsFuture = ref.read(diaryRepoProvider).watchMoods().first;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => context.openDiaryEditor(widget.diaryId),
            icon: PhosphorIcon(
              PhosphorIconsRegular.pencilSimple,
              color: p.onSurfaceVariant,
            ),
          ),
          IconButton(
            onPressed: () async {
              final ok = await showConfirmSheet(
                context,
                title: '删除这篇日记？',
                message: '删除后找不回来',
              );
              if (!ok || !context.mounted) return;
              // 级联删媒体文件
              final items = await ref.read(mediaRepoProvider).listFor(
                    MediaOwner.diary,
                    widget.diaryId,
                  );
              for (final m in items) {
                await ref.read(mediaRepoProvider).remove(m.id);
              }
              await ref.read(diaryRepoProvider).delete(widget.diaryId);
              if (context.mounted) context.pop();
            },
            icon: PhosphorIcon(
              PhosphorIconsRegular.trash,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: diary,
        builder: (context, snap) {
          final d = snap.data;
          if (d == null) return const SkeletonList(itemCount: 2);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
            ),
            children: [
              Hero(
                tag: 'diary-cover-${d.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    d.title.isEmpty ? '无题' : d.title,
                    style: AppType.display.copyWith(color: p.onSurface),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  Text(
                    DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(
                      DateTime(
                        d.dateDay ~/ 10000,
                        (d.dateDay ~/ 100) % 100,
                        d.dateDay % 100,
                      ),
                    ),
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  const Spacer(),
                  FutureBuilder<List<Mood>>(
                    future: moodsFuture,
                    builder: (context, moodSnap) {
                      final mood = (moodSnap.data ?? const <Mood>[])
                          .where((m) => m.id == d.moodId)
                          .firstOrNull;
                      if (mood == null) return const SizedBox.shrink();
                      return MoodDot(
                        color: MoodPalette.colorOf(mood.hue, dark: dark),
                        label: mood.name,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              if (d.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: Wrap(
                    spacing: AppSpacing.s4,
                    children: [
                      for (final t in d.tags)
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
                ),
              if (d.content.isNotEmpty)
                Text(
                  d.content,
                  style: AppType.bodyLoose.copyWith(color: p.onSurface),
                ),
              const SizedBox(height: AppSpacing.s16),
              FutureBuilder<List<MediaItem>>(
                future: media,
                builder: (context, mediaSnap) {
                  final items = mediaSnap.data ?? const <MediaItem>[];
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final m in items)
                        GestureDetector(
                          onLongPress: m.kind == MediaKind.livePhoto
                              ? () => _play(m)
                              : null,
                          onTap: m.kind == MediaKind.video
                              ? () => _play(m)
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.rMd),
                            child: m.kind == MediaKind.video &&
                                    m.thumbPath != null
                                ? Image.file(
                                    File(m.thumbPath!),
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    cacheWidth: 110,
                                    cacheHeight: 110,
                                  )
                                : Image.file(
                                    File(m.coverPath!),
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    cacheWidth: 110,
                                    cacheHeight: 110,
                                  ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Text(
                '实况照片长按播放',
                style: AppType.caption.copyWith(color: p.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}
