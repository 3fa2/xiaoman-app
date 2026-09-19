import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
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
  const DiaryEditorScreen({super.key, required this.diaryId, this.notebookId});

  final int? diaryId;

  /// 从某本日记本进入新建时默认归本（null = 不归本）
  final int? notebookId;

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen>
    with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _speech = SpeechToText();
  final _tagCtrl = TextEditingController();
  bool _listening = false;
  bool _ready = false;
  int? _moodId;
  int? _notebookId; // 归属日记本
  List<String> _tags = const []; // 实体未建时暂存，建后立即落库
  MediaOwner get _ownerType => MediaOwner.diary;

  late final AutosaveController _controller;
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
    if (_tags.isNotEmpty) {
      await repo.setTags(diaryId: id, tags: _tags);
    }
    if (_notebookId != null && _notebookId! > 0) {
      await repo.setNotebook(diaryId: id, notebookId: _notebookId);
    }
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
      // 自动保存首建实体时，补写暂存的标签/归本（与 _ensureEntityId 同一套逻辑）。
      // 否则"先加标签再打字"的场景标签会丢。
      onSaved: (id) async {
        _savedId = id;
        // 补写暂存 tags/归本：失败不抢断主流程（下次保存幂等重试）
        try {
          final repo = ref.read(diaryRepoProvider);
          if (_tags.isNotEmpty) {
            await repo.setTags(diaryId: id, tags: _tags);
          }
          if (_notebookId != null && _notebookId! > 0) {
            await repo.setNotebook(diaryId: id, notebookId: _notebookId);
          }
        } catch (_) {}
      },
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
      _tags = diary.tags;
      _notebookId = diary.notebookId;
      _controller.loadBaseline(
        entityId: diary.id,
        title: diary.title,
        content: diary.content,
        extra: diary.moodId,
      );
    } else {
      _notebookId = widget.notebookId;
      // 草稿兑底（MoeMemos 模式）：新建时有残留草稿则提示恢复
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
    String? title;
    String? content;
    int? extra;
    try {
      // 首选 jsonDecode：正则会在转义引号（如正文含 \\"）处截断
      final map = jsonDecode(payload) as Map<String, dynamic>;
      title = map['title'] as String?;
      content = map['content'] as String?;
      extra = map['extra'] as int?;
    } catch (_) {
      // 兼容旧正则（极旧版本草稿）
      title = RegExp(r'"title":"(.*?)"').firstMatch(payload)?.group(1);
      content =
          RegExp(r'"content":"(.*?)"').firstMatch(payload)?.group(1);
      final e = RegExp(r'"extra":(null|\d+)').firstMatch(payload)?.group(1);
      extra = e == null || e == 'null' ? null : int.tryParse(e);
      title = title?.replaceAll(r'\n', '\n');
      content = content?.replaceAll(r'\n', '\n');
    }
    _title.text = title ?? '';
    _content.text = content ?? '';
    _moodId = extra;
    _controller.loadBaseline(
      entityId: null, title: _title.text, content: _content.text, extra: null,
    );
    setState(() {});
  }

  // ---- 归入日记本（实体已存在则立即落库；否则暂存，首存后补写）----
  Future<void> _pickNotebook(int? notebookId) async {
    setState(() => _notebookId = notebookId);
    final id = _entityId;
    if (id != null) {
      await ref
          .read(diaryRepoProvider)
          .setNotebook(diaryId: id, notebookId: notebookId);
    }
  }

  // ---- 标签（实体已存在则立即落库；否则暂存，首存后补写）----
  Future<void> _addTag(String tag) async {
    if (tag.trim().isEmpty || _tags.contains(tag.trim())) return;
    setState(() => _tags = [..._tags, tag.trim()]);
    final id = _entityId;
    if (id != null) {
      await ref.read(diaryRepoProvider).setTags(diaryId: id, tags: _tags);
    }
  }

  Future<void> _removeTag(String tag) async {
    setState(() => _tags = [..._tags]..remove(tag));
    final id = _entityId;
    if (id != null) {
      await ref.read(diaryRepoProvider).setTags(diaryId: id, tags: _tags);
    }
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
    _speech.stop();
    _title.dispose();
    _content.dispose();
    _tagCtrl.dispose();
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

  // ---- 实况照片播放（全屏页面自管 controller；视频缺失回退图片）----
  Future<void> _playLivePhoto(MediaItem item) async {
    final videoPath = item.videoPath;
    if (videoPath == null || !File(videoPath).existsSync()) {
      if (item.coverPath != null) {
        await showFullscreenImage(context, item.coverPath!);
      }
      return;
    }
    await showFullscreenVideo(
      context,
      videoPath,
      coverPath: item.coverPath,
    );
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
      // dirty 也不放行：canPop=true 时系统直接 pop（didPop=true），
      // _onPopInvoked 的早退分支让 flush 永不执行 → 2 秒去抖窗口内的编辑丢失。
      // saved/idle 直接走；dirty/saving 拦下来 flush 后手动 pop。
      canPop: _controller.status != SaveStatus.saving &&
          _controller.status != SaveStatus.dirty,
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
                          // 不用浮动 label（theme 全局 always 会被长文案裁切），
                          // 改 hint：输入后消失，语义不变
                          decoration: const InputDecoration(
                            hintText: '标题（可不填，留空显示日期）',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => _controller.onChanged(
                            title: v, content: _content.text, extra: _moodId,
                          ),
                        ),
                        _NotebookRow(
                          notebookId: _notebookId,
                          onPick: _pickNotebook,
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
                        _TagRow(
                          tags: _tags,
                          tagCtrl: _tagCtrl,
                          onAdd: _addTag,
                          onRemove: _removeTag,
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

/// 归入日记本选择行（类似 _MoodRow）
class _NotebookRow extends ConsumerWidget {
  const _NotebookRow({required this.notebookId, required this.onPick});

  final int? notebookId;
  final ValueChanged<int?> onPick;

  Future<void> _sheet(BuildContext context, WidgetRef ref) async {
    final p = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => StreamBuilder<List<(DiaryNotebook, int)>>(
        stream: ref.read(diaryRepoProvider).watchDiaryNotebooks(),
        builder: (context, snap) {
          final list = snap.data ?? const <(DiaryNotebook, int)>[];
          final dark = Theme.of(ctx).brightness == Brightness.dark;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '归入日记本',
                  style: AppType.headline.copyWith(color: p.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.stack,
                    color: p.onSurfaceVariant,
                  ),
                  title: const Text('不归本'),
                  selected: notebookId == null,
                  onTap: () {
                    onPick(null);
                    Navigator.pop(ctx);
                  },
                ),
                for (final (nb, _) in list)
                  ListTile(
                    leading: MoodDot(
                      color: NotebookPalette.resolve(nb.colorIndex, dark: dark),
                      size: 10,
                    ),
                    title: Text(nb.name),
                    selected: notebookId == nb.id,
                    onTap: () {
                      onPick(nb.id);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    return StreamBuilder<List<(DiaryNotebook, int)>>(
      stream: ref.watch(diaryRepoProvider).watchDiaryNotebooks(),
      builder: (context, snap) {
        final list = snap.data ?? const <(DiaryNotebook, int)>[];
        final current = list
            .where((e) => e.$1.id == notebookId)
            .map((e) => e.$1)
            .firstOrNull;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadii.rMd),
          onTap: () => _sheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsRegular.books,
                  size: 20,
                  color: p.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  current == null ? '归入日记本' : current.name,
                  style: AppType.label.copyWith(
                    color: current == null
                        ? p.onSurfaceVariant
                        : (dark ? p.onSurface : p.primary),
                  ),
                ),
                if (current != null) ...[
                  const SizedBox(width: AppSpacing.s8),
                  MoodDot(
                    color: NotebookPalette.resolve(
                      current.colorIndex,
                      dark: dark,
                    ),
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

/// 标签行：已有标签 chips（点叉删）+ 添加入口（底部弹窗输入）
class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tags,
    required this.tagCtrl,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final TextEditingController tagCtrl;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  Future<void> _sheet(BuildContext context) async {
    tagCtrl.clear();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page, 0, AppSpacing.page,
          AppSpacing.s24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '添加标签',
              style: AppType.headline.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: tagCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '标签名，如：工作、旅行'),
              onSubmitted: (v) {
                onAdd(v);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.s4,
              runSpacing: AppSpacing.s4,
              children: [
                for (final t in tags)
                  Chip(
                    label: Text(t),
                    onDeleted: () => onRemove(t),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _sheet(context),
            child: PhosphorIcon(
              PhosphorIconsRegular.plusCircle,
              size: 20,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
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
                GestureDetector(
                  // 图片/实况封面点开全屏查看；实况长按播放（与详情页一致）
                  onTap: (m.coverPath ?? m.thumbPath) == null
                      ? null
                      : () => showFullscreenImage(
                          context, m.coverPath ?? m.thumbPath!),
                  onLongPress: m.kind == MediaKind.livePhoto
                      ? () => onPlayLive(m)
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.rMd),
                    child: _thumb(context, m),
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

  /// 缩略图：路径缺失/加载失败给占位框，绝不 File(null) 崩
  Widget _thumb(BuildContext context, MediaItem m) {
    final p = Theme.of(context).colorScheme;
    final path = m.thumbPath ?? m.coverPath;
    Widget fallback() => Container(
          width: 96,
          height: 96,
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
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      // 性能纪律 #7：按显示尺寸解码，不把原视频帧拖进内存
      cacheWidth: 96,
      cacheHeight: 96,
      errorBuilder: (_, __, ___) => fallback(),
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
