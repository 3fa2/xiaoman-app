import 'package:drift/drift.dart';

import '../../domain/models/note.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import 'draft_mixin.dart';

class NoteRepositoryImpl with DraftMixin implements NoteRepository {
  NoteRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  AppDatabase get driftDb => _db;

  Note _map(NoteRow row) => Note(
        id: row.id,
        notebookId: row.notebookId,
        title: row.title,
        content: row.content,
        tags: row.tags.split(',').where((s) => s.isNotEmpty).toList(),
        pinned: row.pinned,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  Notebook _mapNotebook(NotebookRow row) => Notebook(
        id: row.id,
        name: row.name,
        colorIndex: row.colorIndex,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
      );

  @override
  Stream<List<Notebook>> watchNotebooks() {
    final q = _db.select(_db.notebooks)
      ..orderBy([(n) => OrderingTerm.asc(n.sortOrder)]);
    return q.watch().map((rows) => rows.map(_mapNotebook).toList());
  }

  @override
  Stream<int> watchNoteCount(int notebookId) {
    final count = _db.notes.id.count();
    final q = _db.selectOnly(_db.notes)
      ..addColumns([count])
      ..where(_db.notes.notebookId.equals(notebookId) &
          _db.notes.deletedAt.isNull());
    return q.watchSingle().map((r) => r.read(count) ?? 0);
  }

  @override
  Future<void> saveNotebook({
    required int? id,
    required String name,
    required int colorIndex,
  }) async {
    if (id == null) {
      final maxExp = _db.notebooks.sortOrder.max();
      final q = _db.selectOnly(_db.notebooks)..addColumns([maxExp]);
      final maxSort = await q.getSingle();
      final next = (maxSort.read(maxExp) ?? 0) + 1;
      await _db.into(_db.notebooks).insert(
            NotebooksCompanion.insert(
              name: name,
              colorIndex: colorIndex,
              sortOrder: next,
              createdAt: DateTime.now(),
            ),
          );
    } else {
      await (_db.update(_db.notebooks)..where((n) => n.id.equals(id))).write(
        NotebooksCompanion(name: Value(name), colorIndex: Value(colorIndex)),
      );
    }
  }

  @override
  Future<void> deleteNotebook(int id) async {
    // 级联：笔记本删除 → 其笔记软删除（进回收站，30 天可恢复），笔记本行硬删
    final now = DateTime.now();
    await (_db.update(_db.notes)
          ..where((n) => n.notebookId.equals(id) & n.deletedAt.isNull()))
        .write(NotesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    await (_db.delete(_db.notebooks)..where((n) => n.id.equals(id))).go();
  }

  @override
  Stream<List<Note>> watchNotes(int notebookId) {
    final q = _db.select(_db.notes)
      ..where((n) => n.notebookId.equals(notebookId) & n.deletedAt.isNull())
      ..orderBy([
        (n) => OrderingTerm.desc(n.pinned),
        (n) => OrderingTerm.desc(n.updatedAt),
      ]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<Note>> watchPinned() {
    final q = _db.select(_db.notes)
      ..where((n) => n.pinned.equals(true) & n.deletedAt.isNull())
      ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<Note?> getNoteById(int id) async {
    final row = await (_db.select(_db.notes)..where((n) => n.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<int> saveNote({
    required int? id,
    required int notebookId,
    required String title,
    required String content,
    required List<String> tags,
    required bool pinned,
  }) async {
    final tagCsv = tags.join(',');
    if (id == null) {
      final now = DateTime.now();
      return _db.into(_db.notes).insert(
            NotesCompanion.insert(
              notebookId: notebookId,
              title: Value(title),
              content: Value(content),
              tags: Value(tagCsv),
              pinned: Value(pinned),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        notebookId: Value(notebookId),
        title: Value(title),
        content: Value(content),
        tags: Value(tagCsv),
        pinned: Value(pinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  @override
  Future<void> setPinned({required int noteId, required bool pinned}) =>
      (_db.update(_db.notes)..where((n) => n.id.equals(noteId)))
          .write(NotesCompanion(pinned: Value(pinned)));

  @override
  Future<void> setTags({required int noteId, required List<String> tags}) =>
      (_db.update(_db.notes)..where((n) => n.id.equals(noteId))).write(
        NotesCompanion(
          tags: Value(tags.join(',')),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> deleteNote(int id) async {
    // 软删除（v8 回收站）：清单子项随笔记一起隐藏，彻底删除时才清
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> restoreNote(int id) async {
    // 恢复：原笔记本可能已删 → 归到第一个笔记本；没有任何笔记本则新建默认本
    final row = await (_db.select(_db.notes)..where((n) => n.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    var notebookId = row.notebookId;
    final nbExists = await (_db.select(_db.notebooks)
          ..where((nb) => nb.id.equals(notebookId)))
        .getSingleOrNull();
    if (nbExists == null) {
      notebookId = await _resolveFallbackNotebookId();
    }
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        deletedAt: Value(null),
        notebookId: Value(notebookId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 兜底笔记本 id：按 sortOrder 取第一个；没有任何笔记本则新建「默认笔记本」。
  /// 供恢复/分享落库等"原归属不可考"的路径共用（notebooks 表无种子，
  /// notebookId=1 在全新安装或删过第一个本的用户身上是悬空引用）。
  Future<int> _resolveFallbackNotebookId() async {
    final first = await (_db.select(_db.notebooks)
          ..orderBy([(nb) => OrderingTerm.asc(nb.sortOrder)]))
        .getSingleOrNull();
    if (first != null) return first.id;
    return _db.into(_db.notebooks).insert(
          NotebooksCompanion.insert(
            name: '默认笔记本',
            colorIndex: 0,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> purgeNote(int id) async {
    await (_db.delete(_db.todoItems)..where((t) => t.noteId.equals(id))).go();
    await (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
  }

  @override
  Stream<List<Note>> watchDeletedNotes() {
    final q = _db.select(_db.notes)
      ..where((n) => n.deletedAt.isNotNull())
      ..orderBy([(n) => OrderingTerm.desc(n.deletedAt)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<List<int>> deletedNotesBefore(DateTime cutoff) async {
    final rows = await (_db.select(_db.notes)
          ..where((n) =>
              n.deletedAt.isNotNull() & n.deletedAt.isSmallerThanValue(cutoff)))
        .get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<List<Note>> searchNotes(String query) async =>
      (await _db.searchNotes(query)).map(_map).toList();

  @override
  Stream<List<TodoItem>> watchTodos(int noteId) {
    final q = _db.select(_db.todoItems)
      ..where((t) => t.noteId.equals(noteId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.watch().map(
          (rows) => rows
              .map(
                (r) => TodoItem(
                  id: r.id, noteId: r.noteId, text: r.body,
                  done: r.done, sortOrder: r.sortOrder,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> addTodo({required int noteId, required String text}) async {
    final maxExp = _db.todoItems.sortOrder.max();
    final q = _db.selectOnly(_db.todoItems)..addColumns([maxExp]);
    final maxSort = await q.getSingle();
    final next = (maxSort.read(maxExp) ?? 0) + 1;
    await _db.into(_db.todoItems).insert(
          TodoItemsCompanion.insert(
            noteId: noteId, body: text, sortOrder: next,
          ),
        );
  }

  @override
  Future<void> toggleTodo({required int todoId, required bool done}) =>
      (_db.update(_db.todoItems)..where((t) => t.id.equals(todoId)))
          .write(TodoItemsCompanion(done: Value(done)));

  @override
  Future<void> deleteTodo(int todoId) =>
      (_db.delete(_db.todoItems)..where((t) => t.id.equals(todoId))).go();

  // ---- EditorRepository：save（extra = notebookId），draft 三件套由 DraftMixin 提供 ----

  @override
  Future<int> save({
    required int? id,
    required String title,
    required String content,
    required int? extra,
    int? dateDay, // 备忘无日期概念，忽略（接口与日记共用）
  }) async {
    // 自动保存通道：更新已有笔记时绝不碰 tags/pinned（由编辑器专用通道管理），
    // 否则打字触发的每次自动保存都会清空标签和置顶（真机曾发生的丢数据路径）。
    // extra == null（未显式指定归属，如分享落库/无参新建）→ 兜底到第一个笔记本，
    // 没有笔记本则建「默认笔记本」——写死 1 在全新安装/删过第一个本的用户身上
    // 是悬空引用，备忘会从所有列表里消失（逐字审查发现的真 bug）。
    if (id == null) {
      return saveNote(
        id: null,
        notebookId: extra ?? await _resolveFallbackNotebookId(),
        title: title,
        content: content,
        tags: const [],
        pinned: false,
      );
    }
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        notebookId: Value(extra ?? await _resolveFallbackNotebookId()),
        title: Value(title),
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }
}
