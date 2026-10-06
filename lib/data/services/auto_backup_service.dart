import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import 'backup_service.dart';

/// 每日自动备份（v5.3）：启动时静默写一份全量 JSON 到
/// 应用私有目录 auto_backup/，保留最近 [keep] 份，防数据库损坏/误操作。
/// 卸载即清（私有目录）；跨机迁移仍走手动「导出全部数据」。
class AutoBackupService {
  AutoBackupService(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;

  static const keep = 7;
  static const _keyEnabled = 'auto_backup_enabled';
  static const _keyLast = 'auto_backup_last';
  static const _minInterval = Duration(hours: 20); // ~每天一次

  Future<bool> isEnabled() async =>
      (await _settings.get(_keyEnabled) ?? '1') == '1'; // 默认开

  Future<void> setEnabled(bool v) =>
      _settings.set(_keyEnabled, v ? '1' : '0');

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'auto_backup')).create(recursive: true);
  }

  /// 启动时调用：距上次成功备份 ≥20 小时才写（静默，失败不抛）
  Future<void> runIfNeeded() async {
    try {
      if (!await isEnabled()) return;
      final last =
          int.tryParse(await _settings.get(_keyLast) ?? '0') ?? 0;
      final now = DateTime.now();
      if (now.millisecondsSinceEpoch - last < _minInterval.inMilliseconds) {
        return;
      }
      await runNow();
    } catch (_) {
      // 自动备份失败不阻塞启动（手动导出仍是主路径）
    }
  }

  /// 立即备份一份（设置页"立即备份"按钮 / 启动共用）
  Future<String> runNow() async {
    final content = await BackupServiceImpl(_db).exportAllJsonString();
    final dir = await _dir();
    final n = DateTime.now();
    final stamp = '${n.year}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}'
        '-${n.hour.toString().padLeft(2, '0')}'
        '${n.minute.toString().padLeft(2, '0')}';
    final file = File(p.join(dir.path, 'auto-backup-$stamp.json'));
    await file.writeAsString(content, flush: true);
    await _prune(dir);
    await _settings.set(_keyLast, DateTime.now().millisecondsSinceEpoch.toString());
    return file.path;
  }

  /// 保留最近 keep 份，其余删除
  Future<void> _prune(Directory dir) async {
    final files = await listBackups();
    for (final f in files.skip(keep)) {
      try {
        await f.delete();
      } on FileSystemException {
        // 占用/已删：跳过
      }
    }
  }

  /// 备份文件列表（新→旧）
  Future<List<File>> listBackups() async {
    final dir = await _dir();
    if (!await dir.exists()) return const [];
    final files =
        (await dir.list().toList()).whereType<File>().where((f) {
          return p.extension(f.path) == '.json';
        }).toList()
          ..sort((a, b) => b.path.compareTo(a.path)); // 文件名含时间戳，字典序=时间序
    return files;
  }

  Future<void> restoreFrom(String path) async {
    final json = await File(path).readAsString();
    await BackupServiceImpl(_db).importFromJsonString(json);
  }
}
