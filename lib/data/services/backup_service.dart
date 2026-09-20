import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database.dart';

/// 备份导出/导入：JSON 全量 + WAL checkpoint（NotallyX 教训：不 checkpoint 备份可能是旧的）
class BackupServiceImpl {
  BackupServiceImpl(this._db);

  final AppDatabase _db;

  Future<String> exportAllJson() async {
    await _db.checkpoint();
    final data = <String, dynamic>{};

    data['schemaVersion'] = _db.schemaVersion;
    data['exportedAt'] = DateTime.now().toIso8601String();
    data['diaries'] =
        (await _db.select(_db.diaries).get()).map((r) => r.toJson()).toList();
    data['diaryNotebooks'] = (await _db.select(_db.diaryNotebooks).get())
        .map((r) => r.toJson())
        .toList();
    data['moods'] =
        (await _db.select(_db.moods).get()).map((r) => r.toJson()).toList();
    data['mediaItems'] = (await _db.select(_db.mediaItems).get())
        .map((r) => r.toJson())
        .toList();
    data['notebooks'] = (await _db.select(_db.notebooks).get())
        .map((r) => r.toJson())
        .toList();
    data['notes'] =
        (await _db.select(_db.notes).get()).map((r) => r.toJson()).toList();
    data['todoItems'] = (await _db.select(_db.todoItems).get())
        .map((r) => r.toJson())
        .toList();
    data['scheduleTemplates'] = (await _db.select(_db.scheduleTemplates).get())
        .map((r) => r.toJson())
        .toList();
    data['scheduleInstances'] = (await _db.select(_db.scheduleInstances).get())
        .map((r) => r.toJson())
        .toList();
    data['drafts'] =
        (await _db.select(_db.drafts).get()).map((r) => r.toJson()).toList();
    data['settings'] =
        (await _db.select(_db.settings).get()).map((r) => r.toJson()).toList();

    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${docs.path}/trinity-backup-$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    return file.path;
  }

  Future<void> shareBackup() async {
    final path = await exportAllJson();
    await Share.shareXFiles([XFile(path)], text: '小满备份');
  }

  /// 从 JSON 导入（覆盖恢复）。用 Android SAF 选文件，零新依赖。
  /// 返回导入统计；失败抛异常由调用方 catch。
  Future<({int diaries, int notes, int schedules})> importFromJsonFile() async {
    // 1. Android SAF 选文件（返回 content URI 字符串）
    final uri = await _channel.invokeMethod<String>('pickJsonFile');
    if (uri == null) throw Exception('未选择文件');

    // 2. 读文件内容
    final bytes =
        await _channel.invokeMethod<Uint8List>('readFile', {'uri': uri});
    if (bytes == null) throw Exception('读取失败');
    return importFromJsonString(utf8.decode(bytes));
  }

  /// 导入核心（可测）：JSON 字符串 → 清表 → 插入 → FTS 重建。
  Future<({int diaries, int notes, int schedules})> importFromJsonString(
    String json,
  ) async {
    final data = jsonDecode(json) as Map<String, dynamic>;

    // 3. 覆盖恢复：清表 + 插入
    await _db.checkpoint();

    // 表清空 + 插入（顺序：先子表再主表防 FK 问题——此 schema 无 FK 约束，但顺序仍合理）
    await _db.transaction(() async {
      // 日记本
      await _db.delete(_db.diaryNotebooks).go();
      // 日记
      await _db.delete(_db.diaries).go();
      // 心情（预设种子也会被覆盖，导出时含 moods 表）
      await _db.delete(_db.moods).go();
      // 媒体
      await _db.delete(_db.mediaItems).go();
      // 备忘
      await _db.delete(_db.todoItems).go();
      await _db.delete(_db.notes).go();
      await _db.delete(_db.notebooks).go();
      // 日程
      await _db.delete(_db.scheduleInstances).go();
      await _db.delete(_db.scheduleTemplates).go();
      // 草稿/设置
      await _db.delete(_db.drafts).go();
      await _db.delete(_db.settings).go();

      // 插入：用 drift 生成的 Row.fromJson → insertOnConflictUpdate
      for (final row in (data['moods'] as List?) ?? []) {
        await _db.into(_db.moods).insertOnConflictUpdate(
              MoodsRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['diaryNotebooks'] as List?) ?? []) {
        await _db.into(_db.diaryNotebooks).insertOnConflictUpdate(
              DiaryNotebookRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['diaries'] as List?) ?? []) {
        await _db.into(_db.diaries).insertOnConflictUpdate(
              DiariesRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['mediaItems'] as List?) ?? []) {
        await _db.into(_db.mediaItems).insertOnConflictUpdate(
              MediaItemRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['notebooks'] as List?) ?? []) {
        await _db.into(_db.notebooks).insertOnConflictUpdate(
              NotebookRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['notes'] as List?) ?? []) {
        await _db.into(_db.notes).insertOnConflictUpdate(
              NoteRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['todoItems'] as List?) ?? []) {
        await _db.into(_db.todoItems).insertOnConflictUpdate(
              TodoItemRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['scheduleTemplates'] as List?) ?? []) {
        await _db.into(_db.scheduleTemplates).insertOnConflictUpdate(
              ScheduleTemplateRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['scheduleInstances'] as List?) ?? []) {
        await _db.into(_db.scheduleInstances).insertOnConflictUpdate(
              ScheduleInstanceRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['drafts'] as List?) ?? []) {
        await _db.into(_db.drafts).insertOnConflictUpdate(
              DraftRow.fromJson(row as Map<String, dynamic>),
            );
      }
      for (final row in (data['settings'] as List?) ?? []) {
        await _db.into(_db.settings).insertOnConflictUpdate(
              SettingRow.fromJson(row as Map<String, dynamic>),
            );
      }
    });

    // 4. 重建 FTS 索引（清表后触发器不会回填已删除的索引行）
    await _db.customStatement(
      "INSERT INTO diaries_fts(diaries_fts) VALUES('rebuild')",
    );
    await _db.customStatement(
      "INSERT INTO notes_fts(notes_fts) VALUES('rebuild')",
    );

    // 4.5 防旧备份/手改 JSON 缺 moods：空则重播种预设，保住心情打卡
    await _db.seedMoodsIfEmpty();

    // 5. 读统计返回
    final dCount = await _db.select(_db.diaries).get().then((l) => l.length);
    final nCount = await _db.select(_db.notes).get().then((l) => l.length);
    final sCount =
        await _db.select(_db.scheduleInstances).get().then((l) => l.length);
    return (diaries: dCount, notes: nCount, schedules: sCount);
  }

  static const _channel = MethodChannel('trinity/backup');
}
