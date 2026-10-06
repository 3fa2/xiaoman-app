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
        repeat: row.repeat,
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
    String? repeat,
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
            repeat: Value(repeat),
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
    String? repeat,
  }) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(
          title: Value(title),
          dueDay: Value(dueDay),
          remindBefore: Value(remindBefore),
          repeat: Value(repeat),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> toggle({required int id, required bool done}) async {
    final row = await (_db.select(_db.todos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    // 循环待办：勾掉 = 滚动到下一期（不留在已完成），桌面小组件/手动勾选同一条路径
    if (done && row.repeat != null && row.dueDay != null) {
      final due = DateTime(
        row.dueDay! ~/ 10000, (row.dueDay! ~/ 100) % 100, row.dueDay! % 100,
      );
      final next = switch (row.repeat!) {
        'daily' => due.add(const Duration(days: 1)),
        'weekly' => due.add(const Duration(days: 7)),
        'monthly' => () {
            final y = due.month == 12 ? due.year + 1 : due.year;
            final m = due.month == 12 ? 1 : due.month + 1;
            final lastDay = DateTime(y, m + 1, 0).day;
            return DateTime(y, m, due.day.clamp(1, lastDay));
          }(),
        _ => due,
      };
      await (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(
          dueDay: Value(next.year * 10000 + next.month * 100 + next.day),
          done: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    await (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        done: Value(done),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
}
