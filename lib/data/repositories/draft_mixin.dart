import 'package:drift/drift.dart';

import '../../domain/models/media.dart';
import '../db/database.dart';

/// 草稿表读写（diary / note 共用）。
/// 注意：mixin 跨文件时抽象成员不能用 _ 私有名（Dart 库私有限制），用 driftDb。
mixin DraftMixin {
  AppDatabase get driftDb;

  int _typeCode(MediaOwner t) => t == MediaOwner.diary ? 0 : 1;

  Future<void> saveDraft({
    required MediaOwner ownerType,
    required int ownerId,
    required String payload,
  }) async {
    final type = _typeCode(ownerType);
    final existing = await (driftDb.select(driftDb.drafts)
          ..where(
            (d) => d.ownerType.equals(type) & d.ownerId.equals(ownerId),
          ))
        .getSingleOrNull();
    if (existing == null) {
      await driftDb.into(driftDb.drafts).insert(
            DraftsCompanion.insert(
              ownerType: type,
              ownerId: ownerId,
              payload: payload,
              updatedAt: DateTime.now(),
            ),
          );
    } else {
      await (driftDb.update(driftDb.drafts)
            ..where((d) => d.id.equals(existing.id)))
          .write(
        DraftsCompanion(
          payload: Value(payload),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> clearDraft({
    required MediaOwner ownerType,
    required int ownerId,
  }) async {
    final type = _typeCode(ownerType);
    await (driftDb.delete(driftDb.drafts)
          ..where(
            (d) => d.ownerType.equals(type) & d.ownerId.equals(ownerId),
          ))
        .go();
  }

  Future<Draft?> findDraft({
    required MediaOwner ownerType,
    required int ownerId,
  }) async {
    final type = _typeCode(ownerType);
    final row = await (driftDb.select(driftDb.drafts)
          ..where(
            (d) => d.ownerType.equals(type) & d.ownerId.equals(ownerId),
          ))
        .getSingleOrNull();
    if (row == null) return null;
    return Draft(
      id: row.id,
      ownerType: ownerType,
      ownerId: row.ownerId,
      payload: row.payload,
      updatedAt: row.updatedAt,
    );
  }
}
