import 'dart:io';
import 'dart:typed_data';

import '../../domain/models/media.dart';

/// 实况照片导入器（P0-3）。
///
/// 机型真相（字节级核实过）：
/// - vivo X200 Pro mini（≤ X200 双文件派）：动态照片 = `(动态图)` 文件夹里的
///   同名 JPG + 同名 MP4 两个独立文件，JPG 内部无内嵌视频
/// - 标准单文件 Motion Photo（Google/小米）：XMP 声明 Container:Item，
///   视频物理拼接在 JPEG 尾部
///
/// 统一模型：LivePhoto{coverImagePath, videoPath}，两种形态导入后归一。
/// 播放直接播 videoPath，完全绕开格式地狱。
class LivePhotoImporter {
  LivePhotoImporter._();

  /// 解析结果
  static Future<LivePhoto?> resolve(String coverImagePath) async {
    final cover = File(coverImagePath);
    if (!await cover.exists()) return null;

    // ① 单文件 Motion Photo：XMP 声明 + 尾部内嵌
    final embedded = await _extractEmbeddedVideo(cover);
    if (embedded != null) return embedded;

    // ② vivo 双文件形态：同目录同名 .mp4
    final dir = cover.parent.path;
    final base = cover.uri.pathSegments.last.replaceAll(
      RegExp(r'\.[^.]+$'),
      '',
    );
    for (final videoName in ['$base.mp4', '$base.MP4', '$base.mov']) {
      final video = File('$dir/$videoName');
      if (await video.exists()) {
        return LivePhoto(
          coverImagePath: cover.path,
          videoPath: video.path,
        );
      }
    }
    return null;
  }

  /// 单文件拆解：读 XMP → 算偏移 → 拷出视频。
  /// 定位公式：videoOffset = 文件大小 - Item:Length；校验 ftyp；
  /// 兜底从 JPEG EOI 之后搜 ftyp。
  static Future<LivePhoto?> _extractEmbeddedVideo(File cover) async {
    final raf = await cover.open();
    try {
      final size = await raf.length();
      // XMP 在文件头部，读前 256KB 足够
      await raf.setPosition(0);
      final head = await raf.read(size < 262144 ? size : 262144);
      final headStr = String.fromCharCodes(head);

      final length = _parseItemLength(headStr);
      if (length == null || length <= 0 || length >= size) return null;

      final videoOffset = size - length;
      if (!(await _ftypAt(raf, videoOffset))) {
        // 兜底：EOI(FF D9) 之后搜 ftyp
        final alt = await _searchFtypAfterEoi(raf, size);
        if (alt == null) return null;
        return await _carve(raf, cover.path, alt, size - alt);
      }
      return await _carve(raf, cover.path, videoOffset, length);
    } on FileSystemException {
      return null;
    } finally {
      await raf.close();
    }
  }

  /// 解析 XMP 里 MotionPhoto/Secondary 的 Item:Length（兼容两种前缀）
  static int? _parseItemLength(String xmp) {
    // GCamera:Item Item:Semantic="MotionPhoto" Item:Length="123456"
    final regex = RegExp(
      r'Item:Semantic="MotionPhoto".*?Item:Length="(\d+)"',
      dotAll: true,
    );
    final m = regex.firstMatch(xmp);
    if (m != null) return int.tryParse(m.group(1)!);
    // 旧 MicroVideo：MicroVideoOffset
    final mv = RegExp(r'MicroVideoOffset="(\d+)"').firstMatch(xmp);
    if (mv != null) {
      final offset = int.tryParse(mv.group(1)!);
      return offset;
    }
    return null;
  }

  static Future<bool> _ftypAt(RandomAccessFile raf, int offset) async {
    if (offset < 0) return false;
    await raf.setPosition(offset);
    final magic = await raf.read(8);
    // xxyy len + 'ftyp'
    return magic.length >= 8 &&
        magic[4] == 0x66 &&
        magic[5] == 0x74 &&
        magic[6] == 0x79 &&
        magic[7] == 0x70;
  }

  static Future<int?> _searchFtypAfterEoi(RandomAccessFile raf, int size) async {
    await raf.setPosition(0);
    const chunkSize = 4 * 1024 * 1024;
    var pos = 0;
    while (pos < size) {
      await raf.setPosition(pos);
      final data = await raf.read(chunkSize);
      var idx = _indexOf(data, _ftypBytes);
      while (idx != -1) {
        final candidate = pos + idx - 4; // ftyp 前面 4 字节是 box size
        if (candidate >= 0) return candidate;
        idx = _indexOf(data, _ftypBytes, idx + 4);
      }
      pos += chunkSize;
    }
    return null;
  }

  static final _ftypBytes = Uint8List.fromList(
    [0x66, 0x74, 0x79, 0x70], // 'ftyp'
  );

  static int _indexOf(Uint8List data, Uint8List pattern, [int start = 0]) {
    for (var i = start; i <= data.length - pattern.length; i++) {
      var found = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  static Future<LivePhoto> _carve(
    RandomAccessFile raf,
    String coverPath,
    int videoOffset,
    int length,
  ) async {
    // 写到系统临时目录（唯一文件名）：绝不写在源文件旁边——
    // 无扩展名的源文件会让 replaceAll 退化为同路径，openWrite 直接截断用户原图；
    // 相册目录在分区存储下也多半不可写。systemTemp 在 Android 即应用缓存目录，OS 自行回收。
    final tmp = File(
      '${Directory.systemTemp.path}/live_carve_'
      '${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    final sink = tmp.openWrite();
    await raf.setPosition(videoOffset);
    var remaining = length;
    const chunk = 512 * 1024;
    while (remaining > 0) {
      final n = remaining < chunk ? remaining : chunk;
      final bytes = await raf.read(n);
      sink.add(bytes);
      remaining -= bytes.length;
    }
    await sink.close();
    return LivePhoto(coverImagePath: coverPath, videoPath: tmp.path);
  }

  /// 是否看起来像实况（列表 UI 判断用：展示"实况"角标）
  static Future<bool> looksLikeLivePhoto(String imagePath) async {
    final lp = await resolve(imagePath);
    return lp != null;
  }
}
