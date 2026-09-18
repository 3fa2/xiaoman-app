import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/data/services/live_photo_importer.dart';

/// 实况照片导入器测试：
/// ① vivo 双文件形态（主力，X200 Pro mini 字节级核实）
/// ② 标准单文件 Motion Photo（MicroVideo V1）
/// ③ 两者都不是 → null

Future<File> _makeJpeg(File f, {String? xmp}) async {
  final bytes = <int>[
    0xFF, 0xD8, // SOI
    0xFF, 0xE1, 0x00, 0x20, // APP1
    ...('http://ns.adobe.com/xap/1.0/\x00${xmp ?? ''}').codeUnits,
    0xFF, 0xD9, // EOI
  ];
  return f.writeAsBytes(bytes);
}

Future<File> _makeMp4(File f) async {
  final bytes = <int>[
    0x00, 0x00, 0x00, 0x18, // box size
    0x66, 0x74, 0x79, 0x70, // 'ftyp'
    0x6D, 0x70, 0x34, 0x32, // 'mp42'
    ...List.filled(16, 0x00),
  ];
  return f.writeAsBytes(bytes);
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('trinity_live_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('vivo 双文件：同名 jpg + mp4 直接归一', () async {
    final jpg = await _makeJpeg(
      File('${tmp.path}/IMG_20250320_180642.jpg'),
    );
    final mp4 = await _makeMp4(
      File('${tmp.path}/IMG_20250320_180642.mp4'),
    );
    final lp = await LivePhotoImporter.resolve(jpg.path);
    expect(lp, isNotNull);
    expect(lp!.coverImagePath, jpg.path);
    expect(lp.videoPath, mp4.path);
  });

  test('普通图片（无视频配对）返回 null', () async {
    final jpg = await _makeJpeg(File('${tmp.path}/plain.jpg'));
    final lp = await LivePhotoImporter.resolve(jpg.path);
    expect(lp, isNull);
  });

  test('单文件 MicroVideo V1：从 JPEG 尾部拆出视频', () async {
    // 构造：JPEG 头 + XMP(MicroVideoOffset=24) + 24 字节伪 mp4
    const xmp =
        'GCamera:MicroVideo="1" GCamera:MicroVideoVersion="1" '
        'GCamera:MicroVideoOffset="24"';
    final jpgFile = File('${tmp.path}/MVIMG_test.jpg');
    final head = <int>[
      0xFF, 0xD8,
      0xFF, 0xE1, 0x00, 0x60,
      ...('http://ns.adobe.com/xap/1.0/\x00$xmp').codeUnits,
      0xFF, 0xD9,
    ];
    final mp4part = <int>[
      0x00, 0x00, 0x00, 0x18,
      0x66, 0x74, 0x79, 0x70, // ftyp
      ...List.filled(16, 0x01),
    ];
    await jpgFile.writeAsBytes([...head, ...mp4part]);
    final lp = await LivePhotoImporter.resolve(jpgFile.path);
    expect(lp, isNotNull);
    expect(lp!.coverImagePath, jpgFile.path);
    final carved = File(lp.videoPath);
    expect(await carved.exists(), isTrue);
    final carvedBytes = await carved.readAsBytes();
    // 拆出的视频头是 ftyp
    expect(carvedBytes.length, 24);
    expect(carvedBytes[4], 0x66);
    expect(carvedBytes[5], 0x74);
    expect(carvedBytes[6], 0x79);
    expect(carvedBytes[7], 0x70);
  });
}
