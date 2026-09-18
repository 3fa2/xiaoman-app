
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';

/// 键值设置（存 settings 表）
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
  }

  @override
  Stream<String?> watch(String key) {
    final q = _db.select(_db.settings)..where((s) => s.key.equals(key));
    return q.watchSingleOrNull().map((row) => row?.value);
  }
}
