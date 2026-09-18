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
      ..where(_db.notes.notebookId.equals(notebookId));
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
    // 级联删笔记与子项
    final notes = await (_db.select(_db.notes)
          ..where((n) => n.notebookId.equals(id)))
        .get();
    for (final n in notes) {
      await (_db.delete(_db.todoItems)..where((t) => t.noteId.equals(n.id)))
          .go();
    }
    await (_db.delete(_db.notes)..where((n) => n.notebookId.equals(id))).go();
    await (_db.delete(_db.notebooks)..where((n) => n.id.equals(id))).go();
  }

  @override
  Stream<List<Note>> watchNotes(int notebookId) {
    final q = _db.select(_db.notes)
      ..where((n) => n.notebookId.equals(notebookId))
      ..orderBy([
        (n) => OrderingTerm.desc(n.pinned),
        (n) => OrderingTerm.desc(n.updatedAt),
      ]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<Note>> watchPinned() {
    final q = _db.select(_db.notes)
      ..where((n) => n.pinned.equals(true))
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
  Future<void> deleteNote(int id) async {
    await (_db.delete(_db.todoItems)..where((t) => t.noteId.equals(id))).go();
    await (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
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
  }) {
    return saveNote(
      id: id,
      notebookId: extra ?? 1,
      title: title,
      content: content,
      tags: const [],
      pinned: false,
    );
  }
}
