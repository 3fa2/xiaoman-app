import 'package:crypto/crypto.dart' as crypto;

/// PIN 哈希（纯 Dart sha256，无原生代码）
String sha256Hex(String input) =>
    crypto.sha256.convert(input.codeUnits).toString();
