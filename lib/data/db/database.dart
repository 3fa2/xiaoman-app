import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'schema.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Diaries,
    Moods,
    MediaItems,
    DiaryNotebooks,
    Notebooks,
    Notes,
    TodoItems,
    ScheduleTemplates,
    ScheduleInstances,
    Drafts,
    Settings,
    Todos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// 测试用（NativeDatabase.memory）
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 6;

  static QueryExecutor _open() {
    return driftDatabase(name: 'trinity');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts();
          await _seedMoods();
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2：日记加标签列（csv），保留已有数据
          if (from < 2) {
            await m.addColumn(diaries, diaries.tags);
          }
          // v2 → v3：多日记本（自建分类）
          if (from < 3) {
            await m.createTable(diaryNotebooks);
            await m.addColumn(diaries, diaries.notebookId);
          }
          // v3 → v4：预设心情 hue 重排（v4.7.0，旧版三色挤蓝青区难分辨）
          if (from < 4) {
            await _refreshPresetMoodHues();
          }
          // v4 → v5：模板加 startDate/endDate（v4.8 单次/时间段日程）
          if (from < 5) {
            await m.addColumn(scheduleTemplates, scheduleTemplates.startDate);
            await m.addColumn(scheduleTemplates, scheduleTemplates.endDate);
          }
          // v5 → v6：独立待办表（v5.0 桌面小组件 + 待办 tab）
          if (from < 6) {
            await m.createTable(todos);
          }
        },
      );

  Future<void> _createFts() async {
    // external content 模式：正文存主表，FTS 只存索引，触发器同步
    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS diaries_fts USING fts5("
      "content, title, content='diaries', content_rowid='id', tokenize='unicode61')",
    );
    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5("
      "content, title, tags, content='notes', content_rowid='id', tokenize='unicode61')",
    );
    for (final sql in _ftsTriggers) {
      await customStatement(sql);
    }
  }

  Future<void> _seedMoods() async {
    const presets = <(String, double)>[
      ('开心', 50), ('期待', 130), ('平静', 190), ('感动', 330),
      ('疲惫', 260), ('难过', 215), ('焦虑', 25), ('生气', 0),
    ];
    for (var i = 0; i < presets.length; i++) {
      await into(moods).insert(
        MoodsCompanion.insert(
          name: presets[i].$1,
          hue: presets[i].$2,
          isPreset: true,
          sortOrder: i,
        ),
      );
    }
  }

  /// v3 → v4：按名字刷新预设行的 hue（设计真源在 tokens.dart MoodPalette.presets，
  /// 三处同步：这里种子、迁移、tokens.dart）
  Future<void> _refreshPresetMoodHues() async {
    const hues = <(String, double)>[
      ('开心', 50), ('期待', 130), ('平静', 190), ('感动', 330),
      ('疲惫', 260), ('难过', 215), ('焦虑', 25), ('生气', 0),
    ];
    for (final (name, hue) in hues) {
      await (update(moods)
            ..where((m) => m.isPreset.equals(true) & m.name.equals(name)))
          .write(MoodsCompanion(hue: Value(hue)));
    }
  }

  /// 供备份导入后调用：moods 为空时重新播种预设（防旧备份缺 moods 清掉心情体系）
  Future<void> seedMoodsIfEmpty() async {
    final existing = await select(moods).get();
    if (existing.isEmpty) {
      await _seedMoods();
    }
  }

  static const _ftsTriggers = <String>[
    'CREATE TRIGGER IF NOT EXISTS diaries_ai AFTER INSERT ON diaries BEGIN '
        "INSERT INTO diaries_fts(rowid, content, title) VALUES (new.id, new.content, new.title); END",
    'CREATE TRIGGER IF NOT EXISTS diaries_ad AFTER DELETE ON diaries BEGIN '
        "INSERT INTO diaries_fts(diaries_fts, rowid, content, title) VALUES ('delete', old.id, old.content, old.title); END",
    'CREATE TRIGGER IF NOT EXISTS diaries_au AFTER UPDATE ON diaries BEGIN '
        "INSERT INTO diaries_fts(diaries_fts, rowid, content, title) VALUES ('delete', old.id, old.content, old.title); "
        "INSERT INTO diaries_fts(rowid, content, title) VALUES (new.id, new.content, new.title); END",
    'CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN '
        "INSERT INTO notes_fts(rowid, content, title, tags) VALUES (new.id, new.content, new.title, new.tags); END",
    'CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN '
        "INSERT INTO notes_fts(notes_fts, rowid, content, title, tags) VALUES ('delete', old.id, old.content, old.title, old.tags); END",
    'CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN '
        "INSERT INTO notes_fts(notes_fts, rowid, content, title, tags) VALUES ('delete', old.id, old.content, old.title, old.tags); "
        "INSERT INTO notes_fts(rowid, content, title, tags) VALUES (new.id, new.content, new.title, new.tags); END",
  ];

  /// WAL 模式下导出/备份/复制 SQLite 文件前必须先 checkpoint（NotallyX 教训），
  /// 否则备份可能是旧的。
  Future<void> checkpoint() async {
    await customStatement('PRAGMA wal_checkpoint(FULL)');
  }

  /// v1 → v2：日记标签进 LIKE 搜索（v3 起 diary 表有 tags 列）
  Future<List<DiariesRow>> searchDiaries(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (q.length >= 3) {
      final rows = await customSelect(
        'SELECT d.* FROM diaries d JOIN diaries_fts f ON d.id = f.rowid '
        'WHERE diaries_fts MATCH ? ORDER BY d.date_day DESC',
        variables: [Variable(_ftsQuery(q))],
        readsFrom: {diaries},
      ).map(_rowToDiary).get();
      if (rows.isNotEmpty) return rows;
    }
    final like = '%$q%';
    final rows = await customSelect(
      'SELECT * FROM diaries WHERE content LIKE ? OR title LIKE ? OR tags LIKE ? '
      'ORDER BY date_day DESC',
      variables: [Variable(like), Variable(like), Variable(like)],
      readsFrom: {diaries},
    ).map(_rowToDiary).get();
    return rows;
  }

  Future<List<NoteRow>> searchNotes(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (q.length >= 3) {
      final rows = await customSelect(
        'SELECT n.* FROM notes n JOIN notes_fts f ON n.id = f.rowid '
        'WHERE notes_fts MATCH ? ORDER BY n.updated_at DESC',
        variables: [Variable(_ftsQuery(q))],
        readsFrom: {notes},
      ).map(_rowToNote).get();
      if (rows.isNotEmpty) return rows;
    }
    final like = '%$q%';
    final rows = await customSelect(
      'SELECT * FROM notes WHERE content LIKE ? OR title LIKE ? OR tags LIKE ? '
      'ORDER BY updated_at DESC',
      variables: [Variable(like), Variable(like), Variable(like)],
      readsFrom: {notes},
    ).map(_rowToNote).get();
    return rows;
  }

  /// 查询词转 FTS5 安全前缀（引号包裹防注入/语法错）
  static String _ftsQuery(String q) => '"${q.replaceAll('"', '""')}"';

  /// customSelect 返回的 key 是 SQL 列名（snake_case）
  DiariesRow _rowToDiary(QueryRow r) => DiariesRow(
        id: r.read<int>('id'),
        dateDay: r.read<int>('date_day'),
        title: r.read<String>('title'),
        content: r.read<String>('content'),
        tags: r.read<String>('tags'),
        notebookId: r.readNullable<int>('notebook_id'),
        moodId: r.readNullable<int>('mood_id'),
        createdAt: r.read<DateTime>('created_at'),
        updatedAt: r.read<DateTime>('updated_at'),
      );

  NoteRow _rowToNote(QueryRow r) => NoteRow(
        id: r.read<int>('id'),
        notebookId: r.read<int>('notebook_id'),
        title: r.read<String>('title'),
        content: r.read<String>('content'),
        tags: r.read<String>('tags'),
        pinned: r.read<bool>('pinned'),
        createdAt: r.read<DateTime>('created_at'),
        updatedAt: r.read<DateTime>('updated_at'),
      );

  /// 导出/备份用的数据库文件路径（App 私有文档目录）
  Future<String> databaseFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/trinity.sqlite';
  }
}
