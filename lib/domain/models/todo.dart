/// 领域模型 · 独立待办（v5.0 新增，纯 Dart，禁 Flutter 依赖）
///
/// 与「笔记内的待办清单」（Note.todos / TodoItem）互相独立：
/// 这是 App 级的待办 tab 与桌面小组件的数据源。
class Todo {
  final int id;
  final String title;
  final bool done;
  final int? dueDay; // yyyymmdd 截止日（null=无期限）
  final int? remindBefore; // 提前提醒分钟数（null=到点即提醒）
  final DateTime createdAt;
  final DateTime updatedAt;

  const Todo({
    required this.id,
    required this.title,
    required this.done,
    this.dueDay,
    this.remindBefore,
    required this.createdAt,
    required this.updatedAt,
  });

  Todo copyWith({bool? done, String? title, int? dueDay, int? remindBefore}) =>
      Todo(
        id: id,
        title: title ?? this.title,
        done: done ?? this.done,
        dueDay: dueDay ?? this.dueDay,
        remindBefore: remindBefore ?? this.remindBefore,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}