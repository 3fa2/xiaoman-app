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
  Future<void> delete(int id) =>
      (_db.delete(_db.diaries)..where((d) => d.id.equals(id))).go();

  Diary _map(DiariesRow row) => Diary(
        id: row.id,
        dateDay: row.dateDay,
        title: row.title,
        content: row.content,
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
