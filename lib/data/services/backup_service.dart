import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart' as zip;
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database.dart';

/// 备份导出/导入：JSON 全量 + WAL checkpoint（NotallyX 教训：不 checkpoint 备份可能是旧的）
class BackupServiceImpl {
  BackupServiceImpl(this._db);

  final AppDatabase _db;

  /// 全量结构化 JSON（不含媒体文件）。手动导出与自动备份共用。
  Future<String> exportAllJsonString() async {
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
    // v5.0 独立待办表（todos）此前漏导出：换机恢复后待办全丢（v5.0.4 修复）
    data['todos'] =
        (await _db.select(_db.todos).get()).map((r) => r.toJson()).toList();
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

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> exportAllJson() async {
    final content = await exportAllJsonString();
    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${docs.path}/trinity-backup-$stamp.json');
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  /// 全部日记导出为单个 Markdown（按月分节，含心情/标签，排除回收站）
  Future<String> exportMarkdown() async {
    final content = await buildMarkdownString();
    final docs = await getApplicationDocumentsDirectory();
    final n = DateTime.now();
    final stamp = '${n.year}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
    final file = File('${docs.path}/xiaoman-diaries-$stamp.md');
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  /// Markdown 文本构建（纯可测）
  Future<String> buildMarkdownString() async {
    final rows = await (_db.select(_db.diaries)
          ..where((d) => d.deletedAt.isNull())
          ..orderBy([
            (d) => OrderingTerm.asc(d.dateDay),
            (d) => OrderingTerm.asc(d.createdAt),
          ]))
        .get();
    final moodRows = await _db.select(_db.moods).get();
    final moodNames = {for (final m in moodRows) m.id: m.name};

    String dayCn(int weekday) =>
        const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][weekday - 1];

    final b = StringBuffer();
    b.writeln('# 小满 · 日记导出');
    b.writeln();
    final now = DateTime.now();
    b.writeln(
      '> 导出时间 ${now.year}-${now.month.toString().padLeft(2, '0')}'
      '-${now.day.toString().padLeft(2, '0')} · 共 ${rows.length} 篇',
    );
    b.writeln();

    int? lastMonth;
    for (final r in rows) {
      final month = r.dateDay ~/ 100;
      if (month != lastMonth) {
        lastMonth = month;
        b.writeln('## ${month ~/ 100} 年 ${month % 100} 月');
        b.writeln();
      }
      final d = DateTime(
        r.dateDay ~/ 10000, (r.dateDay ~/ 100) % 100, r.dateDay % 100,
      );
      final meta = <String>[
        '${d.month}月${d.day}日',
        dayCn(d.weekday),
        if (r.moodId != null && moodNames[r.moodId] != null)
          '心情：${moodNames[r.moodId!]}',
        if (r.tags.isNotEmpty) '标签：${r.tags}',
      ].join(' · ');
      b.writeln('### $meta');
      b.writeln();
      if (r.title.isNotEmpty) {
        b.writeln('**${r.title}**');
        b.writeln();
      }
      if (r.content.isNotEmpty) {
        b.writeln(r.content);
        b.writeln();
      }
      b.writeln('---');
      b.writeln();
    }
    return b.toString();
  }

  Future<void> shareBackup() async {
    final path = await exportAllJson();
    await Share.shareXFiles([XFile(path)], text: '小满备份');
  }

  Future<void> shareMarkdown() async {
    final path = await exportMarkdown();
    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/markdown')],
      text: '小满日记导出（Markdown）',
    );
  }

  // ---- 完整备份 v5.8：JSON + 媒体文件 zip ----
  // 纯 JSON 备份不含媒体（CHANGELOG v5.3.0 起的已知限制），换机图片全丢。
  // zip 结构：backup.json + <docs 相对路径>（media/{owner}/{id}/{stamp}-{name}）。
  // 导入时按「当前 docs 路径」重写 media_items 行，跨机/同机都成立。

  /// 收集库内引用的全部媒体文件（去重、过滤已不存在的孤儿引用）
  Future<Set<String>> _collectMediaPaths() async {
    final rows = await _db.select(_db.mediaItems).get();
    final paths = <String>{};
    for (final r in rows) {
      for (final path in [r.coverPath, r.videoPath, r.thumbPath]) {
        if (path == null || path.isEmpty) continue;
        if (File(path).existsSync()) paths.add(path);
      }
    }
    return paths;
  }

  /// zip 内条目名：相对 docs 的 posix 路径（media/diary/42/173…-a.jpg）
  @visibleForTesting
  static String zipEntryNameFor(String filePath, String docsPath) {
    final rel = p.relative(filePath, from: docsPath).replaceAll('\\', '/');
    return rel;
  }

  /// 从（任意前缀的）媒体绝对路径提取 media/ 起始的尾段
  @visibleForTesting
  static String? mediaTailOf(String? path) {
    if (path == null || path.isEmpty) return null;
    final norm = path.replaceAll('\\', '/');
    final i = norm.indexOf('/media/');
    if (i == -1) return null;
    return norm.substring(i + 1); // media/...
  }

  /// 导出完整备份（JSON + 全部媒体）到指定 zip 路径，返回路径。
  /// level 0 = STORE 直存（archive 未导出 STORE 常量）：jpg/mp4 本身已压缩，
  /// deflate 白耗 CPU 且峰值内存更高。
  Future<String> exportFullBackupTo(String zipPath) async {
    await _db.checkpoint();
    final docs = await getApplicationDocumentsDirectory();
    final json = await exportAllJsonString();

    final encoder = zip.ZipFileEncoder();
    encoder.create(zipPath, level: 0);
    encoder.addArchiveFile(zip.ArchiveFile.string('backup.json', json));
    try {
      for (final path in await _collectMediaPaths()) {
        final entry = zipEntryNameFor(path, docs.path);
        await encoder.addFile(File(path), entry);
      }
    } finally {
      await encoder.close();
    }
    return zipPath;
  }

  /// 导出完整备份到 docs（默认命名），返回文件路径
  Future<String> exportFullBackup() async {
    final docs = await getApplicationDocumentsDirectory();
    final n = DateTime.now();
    final stamp = '${n.year}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}-${n.hour}'
        '${n.minute.toString().padLeft(2, '0')}';
    return exportFullBackupTo('${docs.path}/xiaoman-full-$stamp.zip');
  }

  Future<void> shareFullBackup() async {
    final path = await exportFullBackup();
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/zip')],
      text: '小满完整备份（含媒体）',
    );
  }

  /// 完整备份恢复：SAF 选 zip（v5.8.1 起走专用选择器，MIME 白名单含 zip——
  /// 复用 pickJsonFile 的 application/json 过滤会让 zip 灰显选不中）→
  /// 解媒体文件 → 导 JSON → 按「media/ 尾段」重写 media_items 路径。
  Future<({int diaries, int notes, int schedules, int media})>
      importFullBackup() async {
    final uri = await _channel.invokeMethod<String>('pickBackupFile');
    if (uri == null) throw Exception('未选择文件');
    final bytes = await _channel.invokeMethod<Uint8List>('readFile', {'uri': uri});
    if (bytes == null) throw Exception('读取失败');
    return importFullBackupFromBytes(bytes);
  }

  /// 恢复核心（可测）：zip 字节 → 媒体落位 → JSON 导入 → 路径重写。
  Future<({int diaries, int notes, int schedules, int media})>
      importFullBackupFromBytes(Uint8List bytes) async {
    final archive = zip.ZipDecoder().decodeBytes(bytes);
    final jsonEntry = archive.findFile('backup.json');
    if (jsonEntry == null) {
      throw Exception('不是完整备份：缺少 backup.json');
    }
    final docs = await getApplicationDocumentsDirectory();

    // 1. 媒体文件解到当前 docs（先落位，JSON 导入后重写路径才查得到）
    var mediaCount = 0;
    for (final entry in archive) {
      if (entry.isFile && entry.name.startsWith('media/')) {
        // 防路径穿越：条目名不允许 .. 或绝对段
        final parts = entry.name.split('/')
          ..removeWhere((s) => s.isEmpty || s == '.');
        if (parts.any((s) => s == '..')) continue;
        final target = File(p.joinAll([docs.path, ...parts]));
        await target.create(recursive: true);
        await target.writeAsBytes(entry.content as List<int>, flush: true);
        mediaCount++;
      }
    }

    // 2. JSON 结构化导入（沿用既有清表/FTS rebuild/种子兜底）
    final json = utf8.decode(jsonEntry.content as List<int>);
    final stats = await importFromJsonString(json);

    // 3. 路径重写：把库里的旧前缀绝对路径换成当前 docs 前缀（按 media/ 尾段）
    final rows = await _db.select(_db.mediaItems).get();
    for (final r in rows) {
      String? newPath(String? old) {
        final tail = mediaTailOf(old);
        if (tail == null) return null;
        final candidate = p.join(docs.path, tail);
        return File(candidate).existsSync() ? candidate : null;
      }

      final cover = newPath(r.coverPath);
      final video = newPath(r.videoPath);
      final thumb = newPath(r.thumbPath);
      if (cover != r.coverPath || video != r.videoPath || thumb != r.thumbPath) {
        await (_db.update(_db.mediaItems)..where((m) => m.id.equals(r.id)))
            .write(
          MediaItemsCompanion(
            coverPath: cover == null
                ? (r.coverPath == null
                    ? const Value.absent()
                    : Value(null))
                : Value(cover),
            videoPath: video == null
                ? (r.videoPath == null
                    ? const Value.absent()
                    : Value(null))
                : Value(video),
            thumbPath: thumb == null
                ? (r.thumbPath == null
                    ? const Value.absent()
                    : Value(null))
                : Value(thumb),
          ),
        );
      }
    }

    return (
      diaries: stats.diaries,
      notes: stats.notes,
      schedules: stats.schedules,
      media: mediaCount,
    );
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
      // 独立待办（此前漏清：导入后旧待办残留）
      await _db.delete(_db.todos).go();
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
      for (final row in (data['todos'] as List?) ?? []) {
        await _db.into(_db.todos).insertOnConflictUpdate(
              TodoRow.fromJson(row as Map<String, dynamic>),
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
