import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  /// 播放视频/实况：文件缺失回退全屏图片；
  /// controller 由预览页自管（侧滑返回走标准转场，不再黑屏）。
  Future<void> _play(MediaItem item) async {
    final videoPath = item.videoPath;
    if (videoPath == null || !File(videoPath).existsSync()) {
      if (item.coverPath != null) {
        await showFullscreenImage(context, item.coverPath!);
      }
      return;
    }
    await showFullscreenVideo(context, videoPath, coverPath: item.coverPath);
  }

  /// 媒体缩略图：路径缺失/加载失败时给占位框，绝不 File(null) 崩
  Widget _mediaThumb(MediaItem m, ColorScheme p) {
    final path = m.thumbPath ?? m.coverPath;
    Widget fallback() => Container(
          width: 110,
          height: 110,
          color: p.surfaceContainerHighest,
          alignment: Alignment.center,
          child: PhosphorIcon(
            PhosphorIconsRegular.filmStrip,
            size: 24,
            color: p.onSurfaceVariant,
          ),
        );
    if (path == null) return fallback();
    return Image.file(
      File(path),
      width: 110,
      height: 110,
      fit: BoxFit.cover,
      cacheWidth: 110,
      cacheHeight: 110,
      errorBuilder: (_, __, ___) => fallback(),
    );
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
          // null（日记不存在/已删）给空态兜底，不能永远停在骨架屏
          if (snap.connectionState != ConnectionState.done) {
            return const SkeletonList(itemCount: 2);
          }
          if (d == null) {
            return const EmptyState(
              icon: PhosphorIconsRegular.notebook,
              title: '这篇日记不存在或已被删除',
              hint: '回到列表看看其他日记吧',
            );
          }
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
                                    child: _mediaThumb(m, p),
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
