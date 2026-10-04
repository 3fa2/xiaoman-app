import '../models/diary.dart';
import '../models/media.dart';
import '../models/note.dart';
import '../models/schedule.dart';
import '../models/todo.dart';

/// 仓库接口（domain 层，纯 Dart）。
/// 实现在 data/repositories/；features 只允许 import 本文件与 di/providers。

/// 自动保存控制器使用的最小编辑接口（日记 / 备忘共用）
abstract interface class EditorRepository {
  Future<int> save({
    required int? id,
    required String title,
    required String content,
    required int? extra, // diary: moodId / note: notebookId 变更另走专用方法
  });

  Future<void> saveDraft({
    required MediaOwner ownerType,
    required int ownerId,
    required String payload,
  });

  Future<void> clearDraft({
    required MediaOwner ownerType,
    required int ownerId,
  });

  Future<Draft?> findDraft({
    required MediaOwner ownerType,
    required int ownerId,
  });
}

abstract interface class DiaryRepository implements EditorRepository {
  Stream<List<Diary>> watchByDate(int dateDay);
  Stream<List<Diary>> watchAll();
  Stream<List<Diary>> watchByMonth(int yearMonth); // yyyymm

  /// 按日记本过滤（notebookId null = 全部，-1 = 未归本）
  Stream<List<Diary>> watchByMonthIn(
    int yearMonth,
    int? notebookId,
  );
  Stream<List<Diary>> watchByDateIn(int dateDay, int? notebookId);
  Future<Diary?> getById(int id);
  Future<void> setMood({required int diaryId, required int? moodId});
  Future<void> setTags({required int diaryId, required List<String> tags});
  Future<void> setNotebook({required int diaryId, required int? notebookId});
  Future<void> delete(int id);
  Future<List<Diary>> search(String query); // FTS5，<3 字回退 LIKE
  Stream<List<Mood>> watchMoods();
  Future<int> addMood(String name, double hue);
  Future<void> deleteMood(int id); // 仅自定义心情（isPreset=false），引用先置空
  Future<List<(Diary, Mood?)>> watchWithMoodRange(int fromDay, int toDay);

  // ---- 日记本（v4.3 自建分类）----
  Stream<List<(DiaryNotebook, int)>> watchDiaryNotebooks(); // 含篇数
  Future<int> saveDiaryNotebook({
    required int? id,
    required String name,
    required int colorIndex,
  });
  Future<void> deleteDiaryNotebook(int id); // 里面的日记保留（未归本）
}

abstract interface class NoteRepository implements EditorRepository {
  Stream<List<Notebook>> watchNotebooks();
  Stream<int> watchNoteCount(int notebookId);
  Future<void> saveNotebook({required int? id, required String name, required int colorIndex});
  Future<void> deleteNotebook(int id);
  Stream<List<Note>> watchNotes(int notebookId);
  Stream<List<Note>> watchPinned();
  Future<Note?> getNoteById(int id);
  Future<int> saveNote({
    required int? id,
    required int notebookId,
    required String title,
    required String content,
    required List<String> tags,
    required bool pinned,
  });
  Future<void> setPinned({required int noteId, required bool pinned});
  Future<void> deleteNote(int id);
  Future<List<Note>> searchNotes(String query);
  Stream<List<TodoItem>> watchTodos(int noteId);
  Future<void> addTodo({required int noteId, required String text});
  Future<void> toggleTodo({required int todoId, required bool done});
  Future<void> deleteTodo(int todoId);
}

/// 独立待办（v5.0：待办 tab + 桌面小组件数据源）
abstract interface class TodoRepository {
  Stream<List<Todo>> watchAll(); // 未完成在前，按 sortOrder/createdAt
  Future<int> add({required String title, int? dueDay, int? remindBefore});
  Future<void> update({
    required int id,
    required String title,
    int? dueDay,
    int? remindBefore,
  });
  Future<void> toggle({required int id, required bool done});
  Future<void> delete(int id);
}

abstract interface class ScheduleRepository {
  Stream<List<ScheduleInstance>> watchDay(int dateDay);
  Stream<List<ScheduleInstance>> watchRange(int fromDay, int toDay);
  Future<ScheduleInstance?> getInstance(int id);
  Future<int> saveInstance({
    required int? id,
    required int? templateId,
    required int dateDay,
    required int startMinutes,
    required int durationMinutes,
    required String title,
    required String description,
    required int colorIndex,
    required bool detachOnEdit,
    required int? remindMinutesBefore,
  });
  Future<void> setStatus({required int id, required BlockStatus status});
  Future<void> deleteInstance(int id);
  Future<void> skipTemplateOccurrence({
    required ScheduleTemplate template,
    required int dateDay,
  });
  Stream<List<ScheduleTemplate>> watchTemplates();
  Future<ScheduleTemplate?> getTemplate(int id);
  Future<int> saveTemplate(ScheduleTemplate t, {required bool isNew});
  Future<void> deleteTemplate(int id);
  Future<void> regenerate({DateTime? now});
  Future<void> markNotified(int instanceId);

  /// 今天是否已生成过（App 启动 / 页面打开时判断，避免重复全量扫）
  bool get needsRegenerate;
}

abstract interface class MediaRepository {
  Stream<List<MediaItem>> watchFor(MediaOwner owner, int ownerId);
  Future<List<MediaItem>> listFor(MediaOwner owner, int ownerId);
  Future<int> attach(MediaItem item);
  Future<void> remove(int mediaId);
  Future<MediaItem?> get(int mediaId);

  /// 把外部文件拷入私有目录，返回目标路径
  Future<String> copyInto(String sourcePath, MediaOwner owner, int ownerId);

  /// 解析实况照片（双文件/单文件归一），非实况返回 null
  Future<LivePhoto?> resolveLivePhoto(String imagePath);
}

abstract interface class BackupRepository {
  Future<String> exportAllJson();
  Future<String> databasePath();
  Future<void> walCheckpoint();
}

abstract interface class SettingsRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
  Stream<String?> watch(String key);
}
