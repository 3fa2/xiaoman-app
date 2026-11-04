import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/media.dart';
import '../../domain/models/note.dart';
import '../../domain/services/autosave_controller.dart';
import '../shared/widgets.dart';

/// 备忘编辑器：标题 / Markdown 正文 / 标签 / 清单子任务。
/// 自动保存走同一个 AutosaveController（P0-1 与日记同一套纪律）。
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId, this.notebookId});

  final int? noteId;
  final int? notebookId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _todoCtrl = TextEditingController();
  List<String> _tags = const [];
  bool _pinned = false;
  int? _notebookId;
  bool _ready = false;
  bool _showTodos = false;
  int? _savedId;
  SaveStatus? _lastStatus; // 保存失败重触感：只在 error 从无到有时震一次

  /// 当前笔记实体 id（编辑已有固定；新建首存后回填）
  int? get _noteEntityId => widget.noteId ?? _savedId;

  /// 新建笔记时输入待办先确保实体存在（复用日记编辑器模式）
  Future<int> _ensureNoteId() async {
    final existing = _noteEntityId;
    if (existing != null) return existing;
    final repo = ref.read(noteRepoProvider);
    final id = await repo.save(
      id: null,
      title: _title.text,
      content: _content.text,
      extra: _notebookId,
    );
    _controller.loadBaseline(
      entityId: id,
      title: _title.text,
      content: _content.text,
      extra: _notebookId,
    );
    _savedId = id;
    return id;
  }

  late final AutosaveController _controller;

  /// 退出流程进行中（防双击完成/系统返回并发触发两次 flush+pop）
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AutosaveController(
      repo: ref.read(noteRepoProvider),
      draftOwnerType: MediaOwner.note,
      // 自动保存首建实体时，补写暂存的标签（与 _ensureNoteId 同一套逻辑）。
      // 否则"先加标签再打字"的场景标签会丢。
      onSaved: (id) async {
        _savedId = id;
        // 补写暂存 tags：失败不抢断主流程（下次保存幂等重试）
        try {
          if (_tags.isNotEmpty) {
            await ref
                .read(noteRepoProvider)
                .setTags(noteId: id, tags: _tags);
          }
        } catch (_) {}
      },
    );
    _controller.addListener(() {
      // 保存失败重触感：错误从无到有时重震一下（UI pill + 触感双通道）
      if (_controller.status == SaveStatus.error &&
          _lastStatus != SaveStatus.error) {
        HapticFeedback.heavyImpact();
      }
      _lastStatus = _controller.status;
      if (mounted) setState(() {});
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(noteRepoProvider);
    final id = widget.noteId;
    if (id != null) {
      final note = await repo.getNoteById(id);
      if (note == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      _title.text = note.title;
      _content.text = note.content;
      _tags = note.tags;
      _pinned = note.pinned;
      _notebookId = note.notebookId;
      _snapshotBaseline();
      _controller.loadBaseline(
        entityId: note.id,
        title: note.title,
        content: note.content,
        extra: note.notebookId,
      );
    } else {
      _notebookId = widget.notebookId;
      // 草稿兜底（与日记编辑器同一套）：新建时有残留草稿则提示恢复，
      // 否则进程被杀时写进 drafts 表的内容永远没有恢复入口（等同丢失）
      final draft = await repo.findDraft(ownerType: MediaOwner.note, ownerId: -1);
      _controller.loadBaseline(
        entityId: null, title: '', content: '', extra: widget.notebookId,
      );
      _snapshotBaseline();
      if (draft != null && mounted) {
        _promptRestoreDraft(draft);
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  // ---- 整行写回通道的基线快照（_flushNote 脏检查用）----
  // 没有它：只打开不编辑也会整行重写并刷 updatedAt（笔记被顶到列表顶）；
  // 加载未完成时更会把空内容覆写进库（数据丢失），见 _flushNote 守卫。
  String _baseTitle = '';
  String _baseContent = '';
  String _baseTagsCsv = '';
  bool _basePinned = false;
  int? _baseNotebookId;

  void _snapshotBaseline() {
    _baseTitle = _title.text;
    _baseContent = _content.text;
    _baseTagsCsv = _tags.join(',');
    _basePinned = _pinned;
    _baseNotebookId = _notebookId;
  }

  bool _metaDirty() =>
      _title.text != _baseTitle ||
      _content.text != _baseContent ||
      _tags.join(',') != _baseTagsCsv ||
      _pinned != _basePinned ||
      _notebookId != _baseNotebookId;

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
              '上次退出时有一条没写完的备忘，恢复它吗？',
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
                ref.read(noteRepoProvider).clearDraft(
                      ownerType: MediaOwner.note,
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
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      title = map['title'] as String?;
      content = map['content'] as String?;
    } catch (_) {
      // 兼容旧正则（极旧版本草稿）
      title = RegExp(r'"title":"(.*?)"').firstMatch(payload)?.group(1);
      content = RegExp(r'"content":"(.*?)"').firstMatch(payload)?.group(1);
      title = title?.replaceAll(r'\n', '\n');
      content = content?.replaceAll(r'\n', '\n');
    }
    _title.text = title ?? '';
    _content.text = content ?? '';
    // extra(notebookId) 不从草稿恢复：归属以进入路径为准（与日记编辑器一致）
    _controller.loadBaseline(
      entityId: null,
      title: _title.text,
      content: _content.text,
      extra: null,
    );
    // 恢复内容作为新基线：不编辑直接完成不落库，内容留在草稿（与日记一致）
    _snapshotBaseline();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // 与日记编辑器同一套纪律：标题/正文走状态机 flush（新建也能落库），
      // tags/pinned/notebookId 再走编辑器专用通道整行补写（有脏检查守卫）。
      _controller.flush(
        title: _title.text, content: _content.text, extra: _notebookId,
      );
      // 后台态看不到 UI：失败不弹提示，但异常不能裸抛
      _flushNote().catchError((_) {});
    }
  }

  Future<void> _flushNote() async {
    // 双守卫：加载未完成绝不写（骨架期完成/退后台会把空内容整行覆写进库）；
    // 无变化不写（防 updatedAt 刷新把只打开过的笔记顶到列表顶部）。
    // id 必须是 widget.noteId ?? _savedId——只看 _savedId 的话已有笔记恒为
    // null（onSaved 只在新建首存触发），标签/置顶会静默丢失（P0 修复）。
    if (!_ready) return;
    final id = _noteEntityId;
    if (id == null) return;
    if (!_metaDirty()) return;
    await ref.read(noteRepoProvider).saveNote(
          id: id,
          notebookId: _notebookId ?? 1,
          title: _title.text,
          content: _content.text,
          tags: _tags,
          pinned: _pinned,
        );
  }

  // ---- 标签（实体已存在则立即落库；否则暂存，首存后 onSaved 补写）----
  Future<void> _addTag(String tag) async {
    final t = tag.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() => _tags = [..._tags, t]);
    final id = _noteEntityId;
    if (id != null) {
      await ref.read(noteRepoProvider).setTags(noteId: id, tags: _tags);
    }
  }

  Future<void> _removeTag(String tag) async {
    setState(() => _tags = [..._tags]..remove(tag));
    final id = _noteEntityId;
    if (id != null) {
      await ref.read(noteRepoProvider).setTags(noteId: id, tags: _tags);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _title.dispose();
    _content.dispose();
    _tagCtrl.dispose();
    _todoCtrl.dispose();
    super.dispose();
  }

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
    if (_popping) return; // 并发退出：flush 只跑一次
    _popping = true;
    await _controller.flush(
      title: _title.text, content: _content.text, extra: _notebookId,
    );
    // pinned/tags 不走 controller，单独补一次（已有 id 才需要）；
    // 失败必须可见且不许退出（UI 不撒谎）
    var metaOk = true;
    try {
      await _flushNote();
    } catch (_) {
      metaOk = false;
    }
    final failed = !mounted ||
        _controller.status == SaveStatus.error ||
        !metaOk;
    if (failed) {
      _popping = false;
      if (mounted && !metaOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final noteId = widget.noteId;

    return PopScope(
      // 恒 false：canPop 表达式在「typing 后重建帧完成前点完成」的微竞态下
      // 仍是旧值 true 会直弹丢字；由 _onPopInvoked 读 controller 实时状态统一决定。
      // ⚠️ PopScope 只拦截 maybePop/系统返回；直接 Navigator.pop() 会绕过它。
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: SaveStatusPill(
            status: _uiStatus,
            lastSavedAt: _controller.lastSavedAt,
            error: _controller.error,
            onRetry: () => _controller.saveNow(
              title: _title.text, content: _content.text, extra: _notebookId,
            ),
          ),
          actions: [
            if (noteId != null)
              IconButton(
                onPressed: () async {
                  final ok = await showConfirmSheet(
                    context,
                    title: '删除这条笔记？',
                    message: '进入回收站，30 天内可恢复',
                  );
                  if (!ok || !mounted) return;
                  await ref.read(noteRepoProvider).deleteNote(noteId);
                  if (mounted) Navigator.of(context).pop();
                },
                icon: PhosphorIcon(
                  PhosphorIconsRegular.trash,
                  color: p.onSurfaceVariant,
                ),
              ),
            TextButton(
              // maybePop 走 PopScope 判定（canPop:false → flush 后手动 pop）；
              // Navigator.pop() 直弹会绕过 PopScope 丢字（v5.4.2 同步修复）
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('完成'),
            ),
          ],
        ),
        body: !_ready
            ? const SkeletonList()
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, 0, AppSpacing.page, AppSpacing.listBottom,
                ),
                children: [
                  TextField(
                    controller: _title,
                    style: AppType.title.copyWith(color: p.onSurface),
                    decoration: const InputDecoration(
                      hintText: '标题（可不填）',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => _controller.onChanged(
                      title: v, content: _content.text, extra: _notebookId,
                    ),
                  ),
                  Row(
                    children: [
                      for (final t in _tags)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s4),
                          child: Chip(
                            label: Text(t),
                            onDeleted: () => _removeTag(t),
                          ),
                        ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          _tagCtrl.clear();
                          showModalBottomSheet<void>(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            builder: (ctx) => Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.page, 0, AppSpacing.page,
                                AppSpacing.s24 +
                                    MediaQuery.of(ctx).viewInsets.bottom,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: _tagCtrl,
                                    autofocus: true,
                                    decoration:
                                        const InputDecoration(labelText: '标签'),
                                    onSubmitted: (v) {
                                      if (v.trim().isNotEmpty) {
                                        _addTag(v);
                                      }
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.tag,
                          size: 16,
                          color: p.onSurfaceVariant,
                        ),
                        label: Text(
                          _tags.isEmpty ? '加标签' : '加标签',
                          style: AppType.label.copyWith(
                            color: p.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.withinBlock),
                  TextField(
                    controller: _content,
                    style: AppType.body.copyWith(color: p.onSurface),
                    maxLines: null,
                    minLines: 6,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: '正文（支持 Markdown）',
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => _controller.onChanged(
                      title: _title.text, content: v, extra: _notebookId,
                    ),
                  ),
                  _TodoSection(
                    noteId: _noteEntityId,
                    show: _showTodos,
                    onToggleShow: () =>
                        setState(() => _showTodos = !_showTodos),
                    todoCtrl: _todoCtrl,
                    onAddFirst: (text) async {
                      // 新建笔记：第一条待办先确保实体落库，再写入
                      final id = await _ensureNoteId();
                      await ref
                          .read(noteRepoProvider)
                          .addTodo(noteId: id, text: text);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _TodoSection extends ConsumerStatefulWidget {
  const _TodoSection({
    required this.noteId,
    required this.show,
    required this.onToggleShow,
    required this.todoCtrl,
    this.onAddFirst,
  });

  final int? noteId;
  final bool show;
  final VoidCallback onToggleShow;
  final TextEditingController todoCtrl;

  /// 新建笔记（实体未落库）时输入第一条待办的回调：先建实体再写入
  final Future<void> Function(String text)? onAddFirst;

  @override
  ConsumerState<_TodoSection> createState() => _TodoSectionState();
}

class _TodoSectionState extends ConsumerState<_TodoSection> {
  // 流按 noteId 缓存：父编辑器每次按键都重建，若每次 build 新建流，
  // StreamBuilder 会重订阅并在流首帧前闪一下空列表
  Stream<List<TodoItem>>? _stream;
  int? _streamNoteId;

  Stream<List<TodoItem>>? _streamFor(int? noteId) {
    if (noteId == null) return null;
    if (_streamNoteId != noteId || _stream == null) {
      _streamNoteId = noteId;
      _stream = ref.read(noteRepoProvider).watchTodos(noteId);
    }
    return _stream;
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final repo = ref.watch(noteRepoProvider);
    final noteId = widget.noteId;
    final stream = _streamFor(noteId);
    // 新建笔记也展示入口：待办输入会先确保实体落库（见 onSubmitted）
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s8),
        TextButton.icon(
          onPressed: widget.onToggleShow,
          icon: PhosphorIcon(
            widget.show
                ? PhosphorIconsRegular.caretUp
                : PhosphorIconsRegular.checkSquare,
            size: 16,
            color: p.onSurfaceVariant,
          ),
          label: Text(
            widget.show ? '收起清单' : '待办清单（可打勾）',
            style: AppType.label.copyWith(color: p.onSurfaceVariant),
          ),
        ),
        if (widget.show)
          Column(
            children: [
              if (noteId != null)
                StreamBuilder<List<TodoItem>>(
                  stream: stream,
                  builder: (context, snap) {
                    final todos = snap.data ?? const <TodoItem>[];
                    return Column(
                      children: [
                        for (final t in todos)
                          Row(
                            children: [
                              Checkbox(
                                value: t.done,
                                onChanged: (v) => repo.toggleTodo(
                                  todoId: t.id, done: v ?? false,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  t.text,
                                  style: AppType.body.copyWith(
                                    color: t.done
                                        ? p.onSurfaceVariant
                                        : p.onSurface,
                                    decoration: t.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => repo.deleteTodo(t.id),
                                icon: PhosphorIcon(
                                  PhosphorIconsRegular.x,
                                  size: 16,
                                  color: p.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: TextField(
                  controller: widget.todoCtrl,
                  decoration: const InputDecoration(
                    labelText: '添加待办，回车确认',
                  ),
                  style: AppType.body.copyWith(color: p.onSurface),
                  onSubmitted: (v) async {
                    if (v.trim().isEmpty) return;
                    widget.todoCtrl.clear();
                    if (noteId != null) {
                      await repo.addTodo(noteId: noteId, text: v.trim());
                    } else {
                      try {
                        await widget.onAddFirst?.call(v.trim());
                      } catch (_) {
                        // 失败不吞到 UI 级别：恢复输入让用户重试
                        widget.todoCtrl.text = v;
                      }
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

