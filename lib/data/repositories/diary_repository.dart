import 'package:drift/drift.dart';

import '../../domain/models/diary.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import 'draft_mixin.dart';

class DiaryRepositoryImpl with DraftMixin implements DiaryRepository {
  DiaryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  AppDatabase get driftDb => _db;

  DiariesCompanion _companion({
    required int dateDay,
    required String title,
    required String content,
    required int? moodId,
  }) {
    final now = DateTime.now();
    return DiariesCompanion.insert(
      dateDay: dateDay,
      title: Value(title),
      content: Value(content),
      moodId: Value(moodId),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<int> save({
    required int? id,
    required String title,
    required String content,
    required int? extra,
  }) async {
    if (id == null) {
      final today = DateTime.now();
      final dateDay = today.year * 10000 + today.month * 100 + today.day;
      final companion = _companion(
        dateDay: dateDay, title: title, content: content, moodId: extra,
      );
      return _db.into(_db.diaries).insert(companion);
    }
    await (_db.update(_db.diaries)..where((d) => d.id.equals(id))).write(
      DiariesCompanion(
        title: Value(title),
        content: Value(content),
        moodId: Value(extra),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  @override
  Future<void> setMood({required int diaryId, required int? moodId}) async {
    await (_db.update(_db.diaries)..where((d) => d.id.equals(diaryId))).write(
      DiariesCompanion(
        moodId: Value(moodId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> setTags({required int diaryId, required List<String> tags}) async {
    await (_db.update(_db.diaries)..where((d) => d.id.equals(diaryId))).write(
      DiariesCompanion(
        tags: Value(tags.join(',')),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> setNotebook({required int diaryId, required int? notebookId}) async {
    await (_db.update(_db.diaries)..where((d) => d.id.equals(diaryId))).write(
      DiariesCompanion(
        notebookId: Value(notebookId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.diaries)..where((d) => d.id.equals(id))).go();

  Diary _map(DiariesRow row) => Diary(
        id: row.id,
        dateDay: row.dateDay,
        title: row.title,
        content: row.content,
        tags: row.tags.isEmpty
            ? const []
            : row.tags.split(',').where((t) => t.isNotEmpty).toList(),
        notebookId: row.notebookId,
        moodId: row.moodId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  @override
  Stream<List<Diary>> watchByDate(int dateDay) {
    final q = _db.select(_db.diaries)
      ..where((d) => d.dateDay.equals(dateDay))
      ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<Diary>> watchAll() {
    final q = _db.select(_db.diaries)
      ..orderBy([(d) => OrderingTerm.desc(d.dateDay)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<Diary>> watchByMonth(int yearMonth) {
    final from = yearMonth * 100;
    final to = from + 99;
    final q = _db.select(_db.diaries)
      ..where((d) => d.dateDay.isBetweenValues(from, to))
      ..orderBy([(d) => OrderingTerm.desc(d.dateDay)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<Diary>> watchByMonthIn(int yearMonth, int? notebookId) {
    final from = yearMonth * 100;
    final to = from + 99;
    final q = _db.select(_db.diaries)
      ..where((d) => d.dateDay.isBetweenValues(from, to));
    if (notebookId == null) {
      // 全部
    } else if (notebookId == -1) {
      q.where((d) => d.notebookId.isNull());
    } else {
      q.where((d) => d.notebookId.equals(notebookId));
    }
    q.orderBy([(d) => OrderingTerm.desc(d.dateDay)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<Diary>> watchByDateIn(int dateDay, int? notebookId) {
    final q = _db.select(_db.diaries)
      ..where((d) => d.dateDay.equals(dateDay));
    if (notebookId == null) {
      // 全部
    } else if (notebookId == -1) {
      q.where((d) => d.notebookId.isNull());
    } else {
      q.where((d) => d.notebookId.equals(notebookId));
    }
    q.orderBy([(d) => OrderingTerm.desc(d.createdAt)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<(DiaryNotebook, int)>> watchDiaryNotebooks() {
    final countExp = _db.diaries.id.count();
    final q = _db.select(_db.diaryNotebooks).join(
          [
            leftOuterJoin(
              _db.diaries,
              _db.diaries.notebookId.equalsExp(_db.diaryNotebooks.id),
            ),
          ],
        )
      ..addColumns([countExp])
      ..groupBy([_db.diaryNotebooks.id])
      ..orderBy([OrderingTerm.asc(_db.diaryNotebooks.sortOrder)]);
    return q.watch().map(
          (rows) => rows
              .map(
                (r) => (
                  DiaryNotebook(
                    id: r.readTable(_db.diaryNotebooks).id,
                    name: r.readTable(_db.diaryNotebooks).name,
                    colorIndex: r.readTable(_db.diaryNotebooks).colorIndex,
                    sortOrder: r.readTable(_db.diaryNotebooks).sortOrder,
                  ),
                  r.read(countExp) ?? 0,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<int> saveDiaryNotebook({
    required int? id,
    required String name,
    required int colorIndex,
  }) async {
    if (id == null) {
      final maxSort = await (_db.select(_db.diaryNotebooks)
            ..orderBy([(n) => OrderingTerm.desc(n.sortOrder)])
            ..limit(1))
          .getSingleOrNull();
      return _db.into(_db.diaryNotebooks).insert(
            DiaryNotebooksCompanion.insert(
              name: name,
              colorIndex: Value(colorIndex),
              sortOrder: (maxSort?.sortOrder ?? -1) + 1,
              createdAt: DateTime.now(),
            ),
          );
    }
    await (_db.update(_db.diaryNotebooks)..where((n) => n.id.equals(id)))
        .write(
      DiaryNotebooksCompanion(
        name: Value(name),
        colorIndex: Value(colorIndex),
      ),
    );
    return id;
  }

  @override
  Future<void> deleteDiaryNotebook(int id) async {
    // 日记保留，归到未归本
    await (_db.update(_db.diaries)
          ..where((d) => d.notebookId.equals(id)))
        .write(
      DiariesCompanion(notebookId: Value(null)),
    );
    await (_db.delete(_db.diaryNotebooks)..where((n) => n.id.equals(id))).go();
  }

  @override
  Future<Diary?> getById(int id) async {
    final row = await (_db.select(_db.diaries)
          ..where((d) => d.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<List<Diary>> search(String query) async =>
      (await _db.searchDiaries(query)).map(_map).toList();

  @override
  Stream<List<Mood>> watchMoods() {
    final q = _db.select(_db.moods)
      ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]);
    return q.watch().map(
          (rows) => rows
              .map(
                (r) => Mood(
                  id: r.id,
                  name: r.name,
                  hue: r.hue,
                  isPreset: r.isPreset,
                  sortOrder: r.sortOrder,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<int> addMood(String name, double hue) =>
      _db.into(_db.moods).insert(
            MoodsCompanion.insert(
              name: name,
              hue: hue,
              isPreset: false,
              sortOrder: 100,
            ),
          );

  @override
  Future<void> deleteMood(int id) async {
    // 无 FK 约束，手动保证一致：先解除日记引用，再删行（预设行拒绝删除）
    await (_db.update(_db.diaries)..where((d) => d.moodId.equals(id)))
        .write(const DiariesCompanion(moodId: Value(null)));
    await (_db.delete(_db.moods)
          ..where((m) => m.id.equals(id) & m.isPreset.equals(false)))
        .go();
  }

  @override
  Future<List<(Diary, Mood?)>> watchWithMoodRange(
    int fromDay,
    int toDay,
  ) async {
    final diaryRows = await (_db.select(_db.diaries)
          ..where((d) => d.dateDay.isBetweenValues(fromDay, toDay))
          ..orderBy([(d) => OrderingTerm.asc(d.dateDay)]))
        .get();
    final moodRows = await _db.select(_db.moods).get();
    final moodMap = {
      for (final m in moodRows)
        m.id: Mood(
          id: m.id, name: m.name, hue: m.hue,
          isPreset: m.isPreset, sortOrder: m.sortOrder,
        ),
    };
    return diaryRows
        .map(
          (r) => (_map(r), r.moodId == null ? null : moodMap[r.moodId]),
        )
        .toList();
  }
}
