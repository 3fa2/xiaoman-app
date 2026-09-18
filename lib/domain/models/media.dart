/// 领域模型 · 媒体（统一 media_items 模型 + 实况照片，纯 Dart）
enum MediaKind { image, video, livePhoto }

enum MediaOwner { diary, note }

/// 统一媒体表对应模型：
/// 现在（v3）是 5 个平行数组字段，v4 归一为一张表，livePhoto = 封面 + 视频一对。
class MediaItem {
  final int id;
  final MediaOwner ownerType;
  final int ownerId;
  final MediaKind kind;
  final String? coverPath; // 图片本体 / 实况封面
  final String? videoPath; // 视频 / 实况视频
  final String? thumbPath; // 视频缩略图
  final int sortOrder;
  final int? width;
  final int? height;
  final int? durationMs;
  final DateTime createdAt;

  const MediaItem({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.kind,
    required this.coverPath,
    required this.videoPath,
    required this.thumbPath,
    required this.sortOrder,
    required this.width,
    required this.height,
    required this.durationMs,
    required this.createdAt,
  });
}

/// 实况照片统一模型：两种形态（单文件 Motion Photo / vivo 双文件）导入后归一。
/// 播放 = 直接播自己的 mp4，完全绕开格式地狱。
class LivePhoto {
  final String coverImagePath; // JPG，直接给列表/缩略图
  final String videoPath; // MP4，长按直接播

  const LivePhoto({required this.coverImagePath, required this.videoPath});
}

/// 崩溃恢复草稿
class Draft {
  final int id;
  final MediaOwner ownerType; // 0 diary / 1 note
  final int ownerId; // -1 = 新建未落库
  final String payload; // json
  final DateTime updatedAt;

  const Draft({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.payload,
    required this.updatedAt,
  });
}
