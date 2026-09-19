/// 领域模型 · 日记与心情（纯 Dart，禁 Flutter 依赖）
class Diary {
  final int id;
  final int dateDay; // yyyymmdd
  final String title;
  final String content;
  final List<String> tags; // 标签（csv 存储，域层转 List）
  final int? notebookId; // 归属日记本，null=未归本
  final int? moodId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Diary({
    required this.id,
    required this.dateDay,
    required this.title,
    required this.content,
    this.tags = const [],
    this.notebookId,
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

/// 日记本：用户自建分类（碎碎念/认知日记/…）
class DiaryNotebook {
  final int id;
  final String name;
  final int colorIndex;
  final int sortOrder;

  const DiaryNotebook({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.sortOrder,
  });
}
