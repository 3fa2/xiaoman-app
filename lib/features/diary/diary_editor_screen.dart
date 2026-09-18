import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../../domain/models/media.dart';
import '../../domain/services/autosave_controller.dart';
import '../shared/widgets.dart';

/// 日记编辑器（P0-1 自动保存重做）。
///
/// 四条纪律（详细方案 §5.1）：
/// ① PopScope 退出守卫：保存中不许走，dirty 先 flush 再 pop
/// ② 生命周期兜底：inactive/paused 立即落库（不再依赖 dispose）
/// ③ dispose 只做清理，不发起新写入
/// ④ UI 只反映真实状态：saved/saving/dirty/error，绝不撒谎
class DiaryEditorScreen extends ConsumerStatefulWidget {
  const DiaryEditorScreen({super.key, required this.diaryId});

  final int? diaryId;

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen>
    with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _speech = SpeechToText();
  bool _listening = false;
  bool _ready = false;
  int? _moodId;
  MediaOwner get _ownerType => MediaOwner.diary;

  late final AutosaveController _controller;
  VideoPlayerController? _previewPlayer;
  int? _savedId;

  /// 实体 id：编辑已有 → 固定；新建 → 首存后回填
  int? get _entityId => widget.diaryId ?? _savedId;

  /// 导入媒体前确保实体已存在（新建且还没首存时，先落一条占位记录）
  Future<int> _ensureEntityId() async {
    if (_entityId != null) return _entityId!;
    final repo = ref.read(diaryRepoProvider);
    final id = await repo.save(
      id: null, title: _title.text, content: _content.text, extra: _moodId,
    );
    _controller.loadBaseline(
      entityId: id,
      title: _title.text,
      content: _content.text,
      extra: _moodId,
    );
    _savedId = id;
    return id;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AutosaveController(
      repo: ref.read(diaryRepoProvider),
      draftOwnerType: _ownerType,
      onSaved: (id) => _savedId = id,
    );
    _controller.addListener(_onSaveStatus);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(diaryRepoProvider);
    final id = widget.diaryId;
    if (id != null) {
      final diary = await repo.getById(id);
      if (diary == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      _title.text = diary.title;
      _content.text = diary.content;
      _moodId = diary.moodId;
      _controller.loadBaseline(
        entityId: diary.id,
        title: diary.title,
        content: diary.content,
        extra: diary.moodId,
      );
    } else {
      // 草稿兜底（MoeMemos 模式）：新建时有残留草稿则提示恢复
      final draft = await repo.findDraft(ownerType: _ownerType, ownerId: -1);
      _controller.loadBaseline(
        entityId: null, title: '', content: '', extra: null,
      );
      if (draft != null && mounted) {
        _promptRestoreDraft(draft);
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  void _promptRestoreDraft(Draft draft) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '发现未保存的草稿',
              style: AppType.headline.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              '上次退出时有一篇没写完的日记，恢复它吗？',
              style: AppType.body.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            FilledButton(
              onPressed: () {
                _restoreDraft(draft.payload);
                Navigator.pop(ctx);
              },
              child: const Text('恢复'),
            ),
            TextButton(
              onPressed: () {
                ref.read(diaryRepoProvider).clearDraft(
                      ownerType: _ownerType,
                      ownerId: -1,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('不要了'),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreDraft(String payload) {
    final title = RegExp(r'"title":"(.*?)"').firstMatch(payload)?.group(1);
    final content =
        RegExp(r'"content":"(.*?)"').firstMatch(payload)?.group(1);
    final extra =
        RegExp(r'"extra":(null|\d+)').firstMatch(payload)?.group(1);
    _title.text = (title ?? '').replaceAll(r'\n', '\n');
    _content.text = (content ?? '').replaceAll(r'\n', '\n');
    _moodId = extra == null || extra == 'null' ? null : int.tryParse(extra);
    _controller.loadBaseline(
      entityId: null, title: _title.text, content: _content.text, extra: null,
    );
    setState(() {});
  }

  void _onSaveStatus() {
    if (mounted) setState(() {});
  }

  // ---- 生命周期兜底（Markor 做法）----
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.flush(
        title: _title.text, content: _content.text, extra: _moodId,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onSaveStatus);
    _controller.dispose();
    _previewPlayer?.dispose();
    _speech.stop();
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  // ---- 保存状态 → UI 映射 ----
  SaveStatusUi get _uiStatus {
    switch (_controller.status) {
      case SaveStatus.idle:
        return SaveStatusUi.idle;
      case SaveStatus.dirty:
        return SaveStatusUi.dirty;
      case SaveStatus.saving:
        return SaveStatusUi.saving;
      case SaveStatus.saved:
        return SaveStatusUi.saved;
      case SaveStatus.error:
        return SaveStatusUi.error;
    }
  }

  Future<void> _onPopInvoked(bool didPop, _) async {
    if (didPop) return;
    await _controller.flush(
      title: _title.text, content: _content.text, extra: _moodId,
    );
    if (mounted) Navigator.of(context).pop();
  }

  // ---- 媒体导入 ----
  Future<void> _pickMedia() async {
    final ownerId = await _ensureEntityId();
    setState(() {}); // 刷新媒体流 owner
    final assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 9,
        requestType: RequestType.common,
      ),
    );
    if (assets == null || assets.isEmpty) return;
    final repo = ref.read(mediaRepoProvider);
    for (final asset in assets) {
      final file = await asset.originFile;
      if (file == null) continue;
      if (asset.type == AssetType.image) {
        final live = await repo.resolveLivePhoto(file.path);
        if (live != null) {
          final cover = await repo.copyInto(
            live.coverImagePath, MediaOwner.diary, ownerId,
          );
          final video = await repo.copyInto(
            live.videoPath, MediaOwner.diary, ownerId,
          );
          await repo.attach(
            MediaItem(
              id: 0,
              ownerType: MediaOwner.diary,
              ownerId: ownerId,
              kind: MediaKind.livePhoto,
              coverPath: cover,
              videoPath: video,
              thumbPath: null,
              sortOrder: 0,
              width: asset.width,
              height: asset.height,
              durationMs: null,
              createdAt: DateTime.now(),
            ),
          );
          continue;
        }
        final copied = await repo.copyInto(
          file.path, MediaOwner.diary, ownerId,
        );
        await repo.attach(
          MediaItem(
            id: 0,
            ownerType: MediaOwner.diary,
            ownerId: ownerId,
            kind: MediaKind.image,
            coverPath: copied,
            videoPath: null,
            thumbPath: null,
            sortOrder: 0,
            width: asset.width,
            height: asset.height,
            durationMs: null,
            createdAt: DateTime.now(),
          ),
        );
      } else if (asset.type == AssetType.video) {
        final copied = await repo.copyInto(
          file.path, MediaOwner.diary, ownerId,
        );
        final thumb = await VideoThumbnail.thumbnailFile(
          video: copied,
          imageFormat: ImageFormat.JPEG,
          quality: 60,
        );
        await repo.attach(
          MediaItem(
            id: 0,
            ownerType: MediaOwner.diary,
            ownerId: ownerId,
            kind: MediaKind.video,
            coverPath: null,
            videoPath: copied,
            thumbPath: thumb,
            sortOrder: 0,
            width: asset.width,
            height: asset.height,
            durationMs: asset.duration * 1000,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  // ---- 实况照片播放（长按直接播自己的 mp4）----
  Future<void> _playLivePhoto(MediaItem item) async {
    final old = _previewPlayer;
    final player = VideoPlayerController.file(File(item.videoPath!));
    _previewPlayer = player;
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

  // ---- 语音输入 ----
  Future<void> _toggleSpeech() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize();
    if (!ok) return;
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'zh_CN',
      onResult: (result) {
        final text = result.recognizedWords;
        if (text.isNotEmpty) {
          _content.text += (_content.text.isEmpty ? '' : '') + text;
          _controller.onChanged(
            title: _title.text, content: _content.text, extra: _moodId,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final moods = ref.watch(diaryRepoProvider).watchMoods();
    final mediaStream = _entityId == null
        ? null
        : ref.watch(mediaRepoProvider).watchFor(MediaOwner.diary, _entityId!);

    return PopScope(
      canPop: _controller.status != SaveStatus.saving,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: SaveStatusPill(
            status: _uiStatus,
            lastSavedAt: _controller.lastSavedAt,
            error: _controller.error,
            onRetry: () {
              _controller.saveNow(
                title: _title.text, content: _content.text, extra: _moodId,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('完成'),
            ),
          ],
        ),
        body: !_ready
            ? const SkeletonList()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
                      ),
                      children: [
                        TextField(
                          controller: _title,
                          style: AppType.title.copyWith(color: p.onSurface),
                          decoration: const InputDecoration(
                            labelText: '标题',
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => _controller.onChanged(
                            title: v, content: _content.text, extra: _moodId,
                          ),
                        ),
                        _MoodRow(
                          moods: moods,
                          moodId: _moodId,
                          onPick: (id) {
                            setState(() => _moodId = id);
                            _controller.onChanged(
                              title: _title.text,
                              content: _content.text,
                              extra: id,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.withinBlock),
                        TextField(
                          controller: _content,
                          style: AppType.bodyLoose.copyWith(color: p.onSurface),
                          maxLines: null,
                          minLines: 8,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            labelText: '正文',
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => _controller.onChanged(
                            title: _title.text, content: v, extra: _moodId,
                          ),
                        ),
                        StreamBuilder<List<MediaItem>>(
                          stream: mediaStream ?? const Stream.empty(),
                          builder: (context, snap) {
                            final items = snap.data ?? const <MediaItem>[];
                            if (items.isEmpty) return const SizedBox.shrink();
                            return _MediaGrid(
                              items: items,
                              onPlayLive: _playLivePhoto,
                              onDelete: (m) async {
                                await ref.read(mediaRepoProvider).remove(m.id);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _EditorToolbar(
                    listening: _listening,
                    onPickMedia: _pickMedia,
                    onToggleSpeech: _toggleSpeech,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.moods,
    required this.moodId,
    required this.onPick,
  });

  final Stream<List<Mood>> moods;
  final int? moodId;
  final ValueChanged<int?> onPick;

  Future<void> _sheet(BuildContext context) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => StreamBuilder<List<Mood>>(
        stream: moods,
        builder: (context, snap) {
          final list = snap.data ?? const <Mood>[];
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '今天的心情',
                  style: AppType.headline.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s16),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final m in list)
                      _MoodPickChip(
                        mood: m,
                        selected: moodId == m.id,
                        dark: dark,
                        onTap: () {
                          onPick(moodId == m.id ? null : m.id);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    return StreamBuilder<List<Mood>>(
      stream: moods,
      builder: (context, snap) {
        final current =
            (snap.data ?? const <Mood>[]).where((m) => m.id == moodId).firstOrNull;
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadii.rMd),
          onTap: () => _sheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsRegular.smiley,
                  size: 20,
                  color: p.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  current == null ? '记个心情' : current.name,
                  style: AppType.label.copyWith(
                    color: current == null
                        ? p.onSurfaceVariant
                        : (dark ? p.onSurface : p.primary),
                  ),
                ),
                if (current != null) ...[
                  const SizedBox(width: AppSpacing.s8),
                  MoodDot(
                    color: MoodPalette.colorOf(current.hue, dark: dark),
                  ),
                ],
                const Spacer(),
                PhosphorIcon(
                  PhosphorIconsRegular.caretDown,
                  size: 16,
                  color: p.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoodPickChip extends StatelessWidget {
  const _MoodPickChip({
    required this.mood,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.12 : 1,
        duration: MotionDuration.base,
        curve: MotionCurve.standard,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: selected ? p.primaryContainer : p.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.rSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MoodDot(color: MoodPalette.colorOf(mood.hue, dark: dark)),
              const SizedBox(width: AppSpacing.s8),
              Text(
                mood.name,
                style: AppType.label.copyWith(
                  color: selected
                      ? (dark ? p.onSurface : p.primary)
                      : p.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.items,
    required this.onPlayLive,
    required this.onDelete,
  });

  final List<MediaItem> items;
  final ValueChanged<MediaItem> onPlayLive;
  final ValueChanged<MediaItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: [
          for (final m in items)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.rMd),
                  child: m.kind == MediaKind.video && m.thumbPath != null
                      ? Image.file(
                          File(m.thumbPath!),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          // 性能纪律 #7：按显示尺寸解码，不把原视频帧拖进内存
                          cacheWidth: 96,
                          cacheHeight: 96,
                        )
                      : Image.file(
                          File(m.coverPath!),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                          cacheHeight: 96,
                        ),
                ),
                if (m.kind == MediaKind.livePhoto)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s4, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(AppRadii.rSm),
                      ),
                      child: Text(
                        '实况',
                        style: AppType.caption.copyWith(
                          color:
                              Theme.of(context).colorScheme.onInverseSurface,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: -8,
                  top: -8,
                  child: IconButton(
                    icon: PhosphorIcon(
                      PhosphorIconsFill.xCircle,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => onDelete(m),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.listening,
    required this.onPickMedia,
    required this.onToggleSpeech,
  });

  final bool listening;
  final VoidCallback onPickMedia;
  final VoidCallback onToggleSpeech;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPickMedia,
            icon: PhosphorIcon(
              PhosphorIconsRegular.imagesSquare,
              color: p.onSurfaceVariant,
            ),
          ),
          IconButton(
            onPressed: onToggleSpeech,
            icon: PhosphorIcon(
              listening
                  ? PhosphorIconsFill.microphone
                  : PhosphorIconsRegular.microphone,
              color: listening ? p.primary : p.onSurfaceVariant,
            ),
          ),
          if (listening)
            Text('听写中…', style: AppType.caption.copyWith(color: p.primary)),
        ],
      ),
    );
  }
}
