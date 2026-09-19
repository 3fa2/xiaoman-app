import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AutosaveController(
      repo: ref.read(noteRepoProvider),
      draftOwnerType: MediaOwner.note,
      onSaved: (id) => _savedId = id,
    );
    _controller.addListener(() {
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
      _controller.loadBaseline(
        entityId: note.id,
        title: note.title,
        content: note.content,
        extra: note.notebookId,
      );
    } else {
      _notebookId = widget.notebookId;
      _controller.loadBaseline(
        entityId: null, title: '', content: '', extra: widget.notebookId,
      );
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // 笔记的 notebookId 变更走 saveNote 专用通道，这里 flush 标题正文
      _flushNote();
    }
  }

  Future<void> _flushNote() async {
    final id = _controllerEntityId();
    if (id == null) return;
    await ref.read(noteRepoProvider).saveNote(
          id: id,
          notebookId: _notebookId ?? 1,
          title: _title.text,
          content: _content.text,
          tags: _tags,
          pinned: _pinned,
        );
  }

  int? _controllerEntityId() {
    return _savedId;
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
    await _controller.flush(
      title: _title.text, content: _content.text, extra: _notebookId,
    );
    // pinned/tags 不走 controller，单独补一次（已有 id 才需要）
    await _flushNote();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final noteId = widget.noteId;

    return PopScope(
      canPop: _controller.status != SaveStatus.saving,
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
                    message: '删除后找不回来',
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
              onPressed: () => Navigator.of(context).pop(),
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
                      labelText: '标题',
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
                            onDeleted: () {
                              setState(() => _tags = [..._tags]..remove(t));
                            },
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
                                        setState(() {
                                          _tags = [..._tags, v.trim()];
                                        });
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

class _TodoSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final repo = ref.watch(noteRepoProvider);
    // 新建笔记也展示入口：待办输入会先确保实体落库（见 onSubmitted）
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s8),
        TextButton.icon(
          onPressed: onToggleShow,
          icon: PhosphorIcon(
            show
                ? PhosphorIconsRegular.caretUp
                : PhosphorIconsRegular.checkSquare,
            size: 16,
            color: p.onSurfaceVariant,
          ),
          label: Text(
            show ? '收起清单' : '待办清单（可打勾）',
            style: AppType.label.copyWith(color: p.onSurfaceVariant),
          ),
        ),
        if (show)
          Column(
            children: [
              if (noteId != null)
                StreamBuilder<List<TodoItem>>(
                  stream: repo.watchTodos(noteId!),
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
                  controller: todoCtrl,
                  decoration: const InputDecoration(
                    labelText: '添加待办，回车确认',
                  ),
                  style: AppType.body.copyWith(color: p.onSurface),
                  onSubmitted: (v) {
                    if (v.trim().isEmpty) return;
                    if (noteId != null) {
                      repo.addTodo(noteId: noteId!, text: v.trim());
                    } else {
                      onAddFirst?.call(v.trim());
                    }
                    todoCtrl.clear();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

