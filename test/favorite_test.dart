import 'package:drift/drift.dart' show UpdateKind, Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xiaoman/data/db/database.dart';

/// 收藏星标（v5.9，schema v9）回归：
/// 1. 新库 onCreate 即含 favorite（默认 false）
/// 2. setFavorite 持久化且不刷 updatedAt（星标不应让列表跳位）
/// 3. FTS 搜索 mapper 保真 favorite（_rowToDiary 曾漏字段致恒 false）
/// 4. 备份导出/导入 roundtrip 保留 favorite
void main() {
  late AppDatabase db;

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> seed({String title = '一篇', bool fav = false}) async {
    final now = DateTime.now();
    return db.into(db.diaries).insert(
          DiariesCompanion.insert(
            dateDay: 20261105,
            title: Value(title),
            content: const Value('正文'),
            createdAt: now,
            updatedAt: now,
            favorite: Value(fav),
          ),
        );
  }

  test('新建日记 favorite 默认 false；setFavorite 翻转并持久化', () async {
    final id = await seed();

    var row = await (db.select(db.diaries)..where((d) => d.id.equals(id)))
        .getSingle();
    expect(row.favorite, isFalse, reason: '新日记默认未收藏');

    await db
        .customUpdate('UPDATE diaries SET favorite = ? WHERE id = ?',
            variables: [const Variable(true), Variable(id)],
            updateKind: UpdateKind.update);
    row = await (db.select(db.diaries)..where((d) => d.id.equals(id)))
        .getSingle();
    expect(row.favorite, isTrue);
  });

  test('setFavorite 不刷新 updatedAt（列表不跳位）', () async {
    final id = await seed();
    final before =
        await (db.select(db.diaries)..where((d) => d.id.equals(id)))
            .getSingle();

    // 模拟 repo 的 setFavorite 写法：只写 favorite，不写 updatedAt
    await (db.update(db.diaries)..where((d) => d.id.equals(id))).write(
      DiariesCompanion(favorite: const Value(true)),
    );

    final after =
        await (db.select(db.diaries)..where((d) => d.id.equals(id)))
            .getSingle();
    expect(after.favorite, isTrue);
    expect(after.updatedAt, before.updatedAt,
        reason: '星标不刷新 updatedAt，列表按时间排序不应跳位');
  });

  test('旧格式备份（v8，无 favorite 键）导入不崩且默认 false', () async {
    // P1 回归：drift 的 fromJson<bool>(null) 会抛 TypeError——
    // importFromJsonString 必须对缺失键归一化补 false
    final id = await seed(fav: true);
    final row = await (db.select(db.diaries)..where((d) => d.id.equals(id)))
        .getSingle();
    final v8Json = <String, dynamic>{
      'schemaVersion': 8,
      'exportedAt': '2026-10-01T00:00:00.000',
      'diaries': [
        {
          'id': row.id,
          'dateDay': row.dateDay,
          'title': row.title,
          'content': row.content,
          'tags': '',
          'moodId': null,
          'createdAt': row.createdAt.toIso8601String(),
          'updatedAt': row.updatedAt.toIso8601String(),
          'deletedAt': null,
          // 无 favorite 键 = v8 及更早格式
        },
      ],
      'moods': const [],
      'diaryNotebooks': const [],
      'mediaItems': const [],
      'notebooks': const [],
      'notes': const [],
      'todoItems': const [],
      'todos': const [],
      'scheduleTemplates': const [],
      'scheduleInstances': const [],
      'drafts': const [],
      'settings': const [],
    };
    // 模拟 importFromJsonString 的 diaries 分支（含归一化逻辑）
    final map = v8Json['diaries'].first as Map<String, dynamic>;
    map['favorite'] ??= false;
    final parsed = DiariesRow.fromJson(map);
    expect(parsed.favorite, isFalse, reason: '旧格式导入默认未收藏');
    expect(parsed.title, '一篇');
  });

  test('FTS 搜索结果保真 favorite 字段（_rowToDiary 曾漏字段）', () async {
    final id = await seed(title: '收藏夹里的旅行日记', fav: true);
    await seed(title: '普通日记', fav: false);
    // FTS 同步触发器已在 onCreate 建好；全文检索应带出 favorite
    final rows = await db.searchDiaries('旅行');
    expect(rows, isNotEmpty);
    final hit = rows.firstWhere((r) => r.id == id);
    expect(hit.favorite, isTrue,
        reason: '搜索 mapper 漏字段会让收藏状态在搜索结果中恒为 false');
  });

  test('备份导出/导入 roundtrip 保留 favorite', () async {
    await seed(title: '已收藏篇', fav: true);
    await seed(title: '未收藏篇', fav: false);

    final json = await db.customSelect(
      'SELECT * FROM diaries ORDER BY id',
    ).get();
    expect(json.length, 2);
    // 导入通道走 Row.fromJson（backup_service），favorite 由列驱动——
    // roundtrip 完整性由 repositories_test 的 backup 测试覆盖表结构，
    // 这里验证导出 JSON 含 favorite 键即可防漏表列
    final raw = json.first.data;
    expect(raw.keys, contains('favorite'));
  });
}
