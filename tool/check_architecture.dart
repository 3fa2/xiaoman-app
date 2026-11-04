import 'dart:io';

/// 架构检查 v4（保留有架构意义的规则，删除 v3 的行数契约：
/// 单文件行数 / build() 行数 / 函数行数限制已废除——那是把一致性切碎的元凶）。
///
/// 保留的检查：
/// 1. lib/domain/**  禁止 import Flutter（纯 Dart，可测试）
/// 2. lib/features/** 禁止 import lib/data/**（只经 di/providers.dart 桥；
///    相对导入与 package:xiaoman/data/ 绝对导入都拦）
/// 3. lib/features/** 禁止写裸色值（Color(0x..) / fromARGB / fromRGBO；
///    design/tokens.dart 与 theme.dart 是唯一例外）
void main() {
  final root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('找不到 lib/ 目录——请在项目根目录运行');
    exit(2);
  }
  final violations = <String>[];

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    final lines = entity.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // 去掉行注释再匹配（行尾注释不应豁免整行检查）
      final code = line.split('//').first.trim();

      // 1. domain 禁 Flutter
      if (path.contains('/domain/')) {
        if (code.contains("import 'package:flutter/")) {
          violations.add('[domain 禁 Flutter] $path:${i + 1} -> ${line.trim()}');
        }
      }

      // 2. features 禁直连 data（相对 ../data/ 与 package:xiaoman/data/ 两种写法）
      if (path.contains('/features/')) {
        final relImport = RegExp(
          r'''import\s+['"](\.\./)+data/|import\s+['"]package:[^/]+/data/''',
        );
        if (relImport.hasMatch(code)) {
          violations.add('[features 禁直连 data] $path:${i + 1} -> ${line.trim()}');
        }
        if (code.contains('package:drift/')) {
          violations.add('[features 禁 drift] $path:${i + 1} -> ${line.trim()}');
        }
      }

      // 3. features 禁裸色值（design/tokens.dart 与 theme.dart 是唯一例外）
      if (path.contains('/features/') && !path.contains('/design/')) {
        final bareColor = RegExp(
          r'Color\(0x|Color\.fromARGB|Color\.fromRGBO',
        );
        if (bareColor.hasMatch(code)) {
          violations.add('[裸色值] $path:${i + 1} -> ${line.trim()}');
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('架构检查通过：0 违规');
    exit(0);
  } else {
    stderr.writeln('架构违规 ${violations.length} 处：');
    for (final v in violations) {
      stderr.writeln('  $v');
    }
    exit(1);
  }
}
