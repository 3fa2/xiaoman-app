/// 领域模型 · 备忘（笔记本 / 笔记 / 清单子项，纯 Dart）
class Notebook {
  final int id;
  final String name;
  final int colorIndex; // 0 = 跟 primary，1-5 预设
  final int sortOrder;
  final DateTime createdAt;

  const Notebook({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.sortOrder,
    required this.createdAt,
  });
}

class Note {
  final int id;
  final int notebookId;
  final String title;
  final String content;
  final List<String> tags;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.notebookId,
    required this.title,
    required this.content,
    required this.tags,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
  });

  String get summary {
    final c = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return c.length <= 60 ? c : '${c.substring(0, 60)}…';
  }
}

class TodoItem {
  final int id;
  final int noteId;
  final String text;
  final bool done;
  final int sortOrder;

  const TodoItem({
    required this.id,
    required this.noteId,
    required this.text,
    required this.done,
    required this.sortOrder,
  });
}
