import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import 'backup_service.dart';

/// 每日自动备份（v5.3）：启动时静默写一份全量 JSON 到
/// 应用私有目录 auto_backup/，保留最近 [keep] 份，防数据库损坏/误操作。
/// v5.8：可选同步一份到用户选择的目录（SAF tree，如网盘同步文件夹）——
/// 私有目录卸载即焚，用户目录的备份在卸载/换机后仍在。
class AutoBackupService {
  AutoBackupService(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;

  static const _channel = MethodChannel('trinity/backup');

  static const keep = 7;
  static const _keyEnabled = 'auto_backup_enabled';
  static const _keyLast = 'auto_backup_last';
  static const _keyTreeUri = 'auto_backup_tree_uri';
  static const _keyTreeSync = 'auto_backup_tree_sync'; // ok / fail / 空=未知
  static const _minInterval = Duration(hours: 20); // ~每天一次

  /// 最近一次同步到用户目录的结果（ok/fail），设置页展示用
  Future<String> treeSyncStatus() async =>
      await _settings.get(_keyTreeSync) ?? '';

  Future<bool> isEnabled() async =>
      (await _settings.get(_keyEnabled) ?? '1') == '1'; // 默认开

  Future<void> setEnabled(bool v) =>
      _settings.set(_keyEnabled, v ? '1' : '0');

  /// 用户备份目录（SAF tree URI，null=未开启）。写入走 MainActivity 通道。
  Future<String?> backupDirUri() async {
    final v = await _settings.get(_keyTreeUri);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setBackupDirUri(String? uri) =>
      _settings.set(_keyTreeUri, uri ?? '');

  /// 弹系统目录选择器；授权持久化后存 settings，返回目录 uri（null=取消）。
  /// 换目录时释放旧持久授权（系统 128/512 上限，防累积）。
  Future<String?> pickBackupDir() async {
    final oldUri = await backupDirUri();
    final uri = await _channel.invokeMethod<String>('pickBackupDir');
    if (uri == null) return null;
    if (oldUri != null && oldUri.isNotEmpty && oldUri != uri) {
      try {
        await _channel.invokeMethod<void>(
          'releaseTreePermission',
          {'uri': oldUri},
        );
      } catch (_) {}
    }
    await setBackupDirUri(uri);
    await _settings.set(_keyTreeSync, '');
    return uri;
  }

  /// Kotlin 侧只认 ByteArray（StandardMessageCodec 不做 String→byte[] 转换），
  /// 必须显式 utf8 编码——传 String 会 ClassCastException 且被下方 catch 静默吞掉
  Future<void> _writeToTree(String treeUri, String fileName, String content) =>
      _channel.invokeMethod<void>('writeToTree', {
        'uri': treeUri,
        'fileName': fileName,
        'bytes': utf8.encode(content),
      });

  Future<List<String>> _listTree(String treeUri) async {
    final names =
        await _channel.invokeMethod<List<dynamic>>('listTree', {'uri': treeUri});
    return names?.cast<String>() ?? const [];
  }

  Future<void> _deleteFromTree(String treeUri, String fileName) =>
      _channel.invokeMethod<void>('deleteFromTree', {
        'uri': treeUri,
        'fileName': fileName,
      });

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

  /// 立即备份一份（设置页"立即备份"按钮 / 启动共用）。
  /// 私有目录照写；配置了用户目录则再同步一份（写失败不影响私有份）。
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
    // 用户目录同步（v5.8）：授权可能已失效（网盘被卸/目录被删），
    // 失败记录到设置（设置页展示），不影响私有份
    final treeUri = await backupDirUri();
    if (treeUri != null && treeUri.isNotEmpty) {
      var ok = false;
      try {
        final name = 'auto-backup-$stamp.json';
        await _writeToTree(treeUri, name, content);
        final names = await _listTree(treeUri);
        final backups =
            names.where((n) => n.startsWith('auto-backup-')).toList()..sort();
        for (final old in backups
            .reversed
            .skip(keep)) {
          try {
            await _deleteFromTree(treeUri, old);
          } catch (_) {}
        }
        ok = true;
      } catch (_) {
        // 同步失败：私有份仍在
      }
      await _settings.set(_keyTreeSync, ok ? 'ok' : 'fail');
    }
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
