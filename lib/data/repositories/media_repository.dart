import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/media.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../services/live_photo_importer.dart';

/// 媒体仓储：统一 media_items 表；文件一律进 App 私有目录 media/
class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl(this._db);

  final AppDatabase _db;

  MediaItem _map(MediaItemRow row) => MediaItem(
        id: row.id,
        ownerType: MediaOwner.values[row.ownerType.clamp(0, 1)],
        ownerId: row.ownerId,
        kind: MediaKind.values[row.kind.clamp(0, 2)],
        coverPath: row.coverPath,
        videoPath: row.videoPath,
        thumbPath: row.thumbPath,
        sortOrder: row.sortOrder,
        width: row.width,
        height: row.height,
        durationMs: row.durationMs,
        createdAt: row.createdAt,
      );

  @override
  Stream<List<MediaItem>> watchFor(MediaOwner owner, int ownerId) {
    final q = _db.select(_db.mediaItems)
      ..where(
        (m) => m.ownerType.equals(owner.index) & m.ownerId.equals(ownerId),
      )
      ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<List<MediaItem>> listFor(MediaOwner owner, int ownerId) async {
    final rows = await (_db.select(_db.mediaItems)
          ..where(
            (m) => m.ownerType.equals(owner.index) & m.ownerId.equals(ownerId),
          )
          ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
        .get();
    return rows.map(_map).toList();
  }

  @override
  Future<int> attach(MediaItem item) =>
      _db.into(_db.mediaItems).insert(
            MediaItemsCompanion.insert(
              ownerType: item.ownerType.index,
              ownerId: item.ownerId,
              kind: item.kind.index,
              coverPath: Value(item.coverPath),
              videoPath: Value(item.videoPath),
              thumbPath: Value(item.thumbPath),
              sortOrder: item.sortOrder,
              width: Value(item.width),
              height: Value(item.height),
              durationMs: Value(item.durationMs),
              createdAt: item.createdAt,
            ),
          );

  @override
  Future<void> remove(int mediaId) async {
    // 删记录 + 删私有文件（封面/视频/缩略图）
    final row = await (_db.select(_db.mediaItems)
          ..where((m) => m.id.equals(mediaId)))
        .getSingleOrNull();
    if (row != null) {
      for (final path in [row.coverPath, row.videoPath, row.thumbPath]) {
        if (path == null) continue;
        final f = File(path);
        if (await f.exists()) {
          try {
            await f.delete();
          } on FileSystemException {
            // 文件已不存在/被占用：忽略，不影响记录删除
          }
        }
      }
    }
    await (_db.delete(_db.mediaItems)..where((m) => m.id.equals(mediaId)))
        .go();
  }

  @override
  Future<MediaItem?> get(int mediaId) async {
    final row = await (_db.select(_db.mediaItems)
          ..where((m) => m.id.equals(mediaId)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  /// 把外部文件拷入私有目录 media/{owner}/{filename}
  @override
  Future<String> copyInto(
    String sourcePath,
    MediaOwner owner,
    int ownerId,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(docs.path, 'media', owner.name, ownerId.toString()),
    );
    await dir.create(recursive: true);
    final name = p.basename(sourcePath);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final target = p.join(dir.path, '$stamp-$name');
    await File(sourcePath).copy(target);
    return target;
  }

  @override
  Future<LivePhoto?> resolveLivePhoto(String imagePath) =>
      LivePhotoImporter.resolve(imagePath);
}
