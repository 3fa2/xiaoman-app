import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repositories/diary_repository.dart';
import '../data/repositories/media_repository.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/todo_repository.dart';
import '../data/services/auto_backup_service.dart';
import '../data/services/backup_service.dart';
import '../data/services/notification_service.dart';
import '../domain/models/todo.dart';
import '../domain/repositories/repositories.dart';

/// 唯一允许 import data/ 的桥（features 只 import 本文件 + domain 接口 + design）

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final diaryRepoProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepositoryImpl(ref.watch(dbProvider)),
);

final noteRepoProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(ref.watch(dbProvider)),
);

final scheduleRepoProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepositoryImpl(ref.watch(dbProvider)),
);

final mediaRepoProvider = Provider<MediaRepository>(
  (ref) => MediaRepositoryImpl(ref.watch(dbProvider)),
);

final settingsRepoProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(dbProvider)),
);

final todoRepoProvider = Provider<TodoRepository>(
  (ref) => TodoRepositoryImpl(ref.watch(dbProvider)),
);

final backupProvider = Provider<BackupServiceImpl>(
  (ref) => BackupServiceImpl(ref.watch(dbProvider)),
);

final autoBackupProvider = Provider<AutoBackupService>(
  (ref) => AutoBackupService(
    ref.watch(dbProvider),
    ref.watch(settingsRepoProvider),
  ),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

/// 主题模式：system / light / dark（设置页切换）
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final repo = ref.watch(settingsRepoProvider);
    repo.get('theme_mode').then((v) {
      if (v != null && state.name != v) {
        state = ThemeMode.values.firstWhere(
          (m) => m.name == v,
          orElse: () => ThemeMode.system,
        );
      }
    });
    return ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(settingsRepoProvider).set('theme_mode', mode.name);
  }
}

/// 提醒警告条（syncAll 结果展示在日程页）
final reminderWarningsProvider =
    NotifierProvider<ReminderWarningsNotifier, List<String>>(
  ReminderWarningsNotifier.new,
);

class ReminderWarningsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void set(List<String> warnings) => state = warnings;

  /// v5.0：待办数据一并传入 syncAll（待办提醒与日程提醒同一次全量重建）；
  /// v5.3：读设置传写日记提醒（开关 + 时间）
  Future<void> syncNow() async {
    final todos = await _currentTodos();
    final settings = ref.read(settingsRepoProvider);
    final diaryRemind = (await settings.get('diary_remind_enabled')) == '1';
    final timeStr = await settings.get('diary_remind_time') ?? '22:00';
    final parts = timeStr.split(':');
    final minutes = (int.tryParse(parts[0]) ?? 22) * 60 +
        (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    final warnings = await NotificationService.instance.syncAll(
      ref.read(scheduleRepoProvider),
      todos: todos,
      diaryRemind: diaryRemind,
      diaryRemindMinutes: minutes,
    );
    set(warnings);
  }

  /// repo 是 Stream 接口，一次性取当前全量列表
  Future<List<Todo>> _currentTodos() async {
    final repo = ref.read(todoRepoProvider);
    final completer = Completer<List<Todo>>();
    late StreamSubscription sub;
    sub = repo.watchAll().listen((list) {
      if (!completer.isCompleted) completer.complete(list);
    });
    final result = await completer.future;
    await sub.cancel();
    return result;
  }
}
