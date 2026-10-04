import 'package:drift/drift.dart';

import '../../domain/models/todo.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';

class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._db);

  final AppDatabase _db;

  Todo _map(TodoRow row) => Todo(
        id: row.id,
        title: row.title,
        done: row.done,
        dueDay: row.dueDay,
        remindBefore: row.remindBefore,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  @override
  Stream<List<Todo>> watchAll() {
    final q = _db.select(_db.todos)
      ..orderBy([
        (t) => OrderingTerm.asc(t.done),
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<int> add({
    required String title,
    int? dueDay,
    int? remindBefore,
  }) async {
    final now = DateTime.now();
    final maxExp = _db.todos.sortOrder.max();
    final q = _db.selectOnly(_db.todos)..addColumns([maxExp]);
    final maxSort = await q.getSingle();
    final next = (maxSort.read(maxExp) ?? 0) + 1;
    return _db.into(_db.todos).insert(
          TodosCompanion.insert(
            title: title,
            dueDay: Value(dueDay),
            remindBefore: Value(remindBefore),
            sortOrder: Value(next),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> update({
    required int id,
    required String title,
    int? dueDay,
    int? remindBefore,
  }) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(
          title: Value(title),
          dueDay: Value(dueDay),
          remindBefore: Value(remindBefore),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> toggle({required int id, required bool done}) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(
          done: Value(done),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
}