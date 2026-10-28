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
import '../domain/models/schedule.dart' show DateDay;
import '../domain/models/todo.dart';
import '../domain/repositories/repositories.dart';
import '../domain/services/stats_service.dart' show streakUntil;

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

/// 日记页视图模式：false=日历 true=时间线列表（首页「全部」直达时间线用）
final diaryViewModeProvider = StateProvider<bool>((ref) => false);

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

/// Material You 动态取色（v5.8，Android 12+）：
/// state = (开关是否开, 设备是否支持)；supported 由 DynamicColorBuilder 写入，
/// 设备不支持时设置页隐藏开关。开关默认关，保持雾蓝品牌色。
/// 骨架跟随壁纸，内容色板不动。
final dynamicColorProvider = NotifierProvider<DynamicColorNotifier,
    ({bool enabled, bool supported})>(DynamicColorNotifier.new);

class DynamicColorNotifier
    extends Notifier<({bool enabled, bool supported})> {
  @override
  ({bool enabled, bool supported}) build() {
    final repo = ref.watch(settingsRepoProvider);
    repo.get('use_dynamic_color').then((v) {
      final enabled = v == '1';
      if (state.enabled != enabled) {
        state = (enabled: enabled, supported: state.supported);
      }
    });
    return (enabled: false, supported: false);
  }

  /// DynamicColorBuilder 回调写入（每次主题构建都会调；值不变时 Riverpod 跳过重建）
  void setSupported(bool value) {
    if (state.supported != value) {
      state = (enabled: state.enabled, supported: value);
    }
  }

  void setEnabled(bool enabled) {
    state = (enabled: enabled, supported: state.supported);
    ref.read(settingsRepoProvider).set('use_dynamic_color', enabled ? '1' : '0');
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
  /// v5.3：读设置传写日记提醒（开关 + 时间）；
  /// v5.8：打卡文案——读日记算今天是否已写 + 到昨天的连续天数
  Future<void> syncNow() async {
    final todos = await _currentTodos();
    final settings = ref.read(settingsRepoProvider);
    final diaryRemind = (await settings.get('diary_remind_enabled')) == '1';
    final timeStr = await settings.get('diary_remind_time') ?? '22:00';
    final parts = timeStr.split(':');
    final minutes = (int.tryParse(parts[0]) ?? 22) * 60 +
        (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);

    var writtenToday = false;
    var streak = -1;
    if (diaryRemind) {
      try {
        final diaries =
            await ref.read(diaryRepoProvider).watchAll().first;
        final now = DateTime.now();
        writtenToday =
            diaries.any((d) => d.dateDay == DateDay.of(now));
        streak = streakUntil(diaries, now, includeToday: false);
      } catch (_) {
        // 读失败不影响提醒排定：文案退默认
      }
    }

    final warnings = await NotificationService.instance.syncAll(
      ref.read(scheduleRepoProvider),
      todos: todos,
      diaryRemind: diaryRemind,
      diaryRemindMinutes: minutes,
      diaryWrittenToday: writtenToday,
      diaryStreak: streak,
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
