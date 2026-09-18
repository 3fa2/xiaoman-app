import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database.dart';

/// 备份导出：JSON 全量 + WAL checkpoint（NotallyX 教训：不 checkpoint 备份可能是旧的）
class BackupServiceImpl {
  BackupServiceImpl(this._db);

  final AppDatabase _db;

  Future<String> exportAllJson() async {
    await _db.checkpoint();
    final data = <String, dynamic>{};

    data['schemaVersion'] = 1;
    data['exportedAt'] = DateTime.now().toIso8601String();
    data['diaries'] =
        (await _db.select(_db.diaries).get()).map((r) => r.toJson()).toList();
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
    await Share.shareXFiles([XFile(path)], text: '三位一体备份');
  }
}
