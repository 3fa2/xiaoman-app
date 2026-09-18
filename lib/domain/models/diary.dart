/// 领域模型 · 日记与心情（纯 Dart，禁 Flutter 依赖）
class Diary {
  final int id;
  final int dateDay; // yyyymmdd
  final String title;
  final String content;
  final int? moodId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Diary({
    required this.id,
    required this.dateDay,
    required this.title,
    required this.content,
    required this.moodId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get summary {
    final c = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return c.length <= 60 ? c : '${c.substring(0, 60)}…';
  }
}

class Mood {
  final int id;
  final String name;
  final double hue;
  final bool isPreset;
  final int sortOrder;

  const Mood({
    required this.id,
    required this.name,
    required this.hue,
    required this.isPreset,
    required this.sortOrder,
  });
}
