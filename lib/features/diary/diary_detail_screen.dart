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

  /// 播放视频/实况。视频文件缺失或初始化失败时回退全屏图片，点击必有反馈。
  Future<void> _play(MediaItem item) async {
    final videoPath = item.videoPath;
    if (videoPath == null || !File(videoPath).existsSync()) {
      if (item.coverPath != null) {
        await showFullscreenImage(context, item.coverPath!);
      }
      return;
    }
    final old = _player;
    final player = VideoPlayerController.file(File(videoPath));
    _player = player;
    try {
      await player.initialize();
    } catch (_) {
      old?.dispose();
      _player = null;
      if (item.coverPath != null && mounted) {
        await showFullscreenImage(context, item.coverPath!);
      }
      return;
    }
    await player.setLooping(true);
    await player.play();
    if (mounted) {
      setState(() {});
      // 全屏黑底沉浸式，点任意处关闭
      await showFullscreenVideo(context, player);
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
              // 无标题：用日期作头部，不再显示「无题」
              Hero(
                tag: 'diary-cover-${d.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    d.title.isEmpty
                        ? DateFormat('M月d日 EEEE', 'zh_CN').format(
                            DateTime(
                              d.dateDay ~/ 10000,
                              (d.dateDay ~/ 100) % 100,
                              d.dateDay % 100,
                            ),
                          )
                        : d.title,
                    style: AppType.display.copyWith(color: p.onSurface),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  // 有标题才显示日期行（无标题时日期已在头部）
                  if (d.title.isNotEmpty)
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
                  final hasLive = items.any(
                    (m) => m.kind == MediaKind.livePhoto,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        children: [
                          for (final m in items)
                            GestureDetector(
                              // 实况/视频都能点按或长按播放；普通图片全屏看
                              onTap: m.kind == MediaKind.image
                                  ? (m.coverPath != null
                                      ? () => showFullscreenImage(
                                          context, m.coverPath!)
                                      : null)
                                  : () => _play(m),
                              onLongPress: m.kind == MediaKind.image
                                  ? null
                                  : () => _play(m),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.rMd),
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
                                  if (m.kind == MediaKind.livePhoto)
                                    Positioned(
                                      right: AppSpacing.s4,
                                      bottom: AppSpacing.s4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.s4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.rSm,
                                          ),
                                        ),
                                        child: Text(
                                          '实况',
                                          style: AppType.caption.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (hasLive)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s8),
                          child: Text(
                            '实况照片点按/长按播放，图片点开可双指缩放',
                            style: AppType.caption.copyWith(
                              color: p.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
