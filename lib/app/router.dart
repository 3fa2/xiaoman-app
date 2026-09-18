import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/diary/diary_calendar_screen.dart';
import '../features/diary/diary_detail_screen.dart';
import '../features/diary/diary_editor_screen.dart';
import '../features/diary/diary_search_screen.dart';
import '../features/diary/mood_trend_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notes/note_editor_screen.dart';
import '../features/notes/note_list_screen.dart';
import '../features/notes/notebook_grid_screen.dart';
import '../features/schedule/schedule_edit_screen.dart';
import '../features/schedule/schedule_day_screen.dart';
import '../features/schedule/schedule_today_screen.dart';
import '../features/schedule/template_manage_screen.dart';
import '../features/settings/lock_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// 解锁状态（内存态：进 App 锁一次即可）
final lockGateProvider = Provider<LockGate>((ref) => LockGate());

class LockGate {
  bool unlocked = false;
  bool get required => _pinHash != null;
  String? _pinHash;

  Future<void> load(String? hash) async {
    _pinHash = hash;
    if (hash == null) unlocked = true;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final gate = ref.watch(lockGateProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final locked = gate.required && !gate.unlocked;
      final atLock = state.matchedLocation == '/lock';
      if (locked && !atLock) return '/lock';
      if (!locked && atLock) return '/home';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/diary',
                builder: (c, s) => const DiaryCalendarScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) => const DiaryEditorScreen(diaryId: null),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (c, s) => DiaryDetailScreen(
                      diaryId: int.parse(s.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (c, s) => DiaryEditorScreen(
                      diaryId: int.tryParse(s.pathParameters['id'] ?? ''),
                    ),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (c, s) => const DiarySearchScreen(),
                  ),
                  GoRoute(
                    path: 'trend',
                    builder: (c, s) => const MoodTrendScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (c, s) => const NotebookGridScreen(),
                routes: [
                  GoRoute(
                    path: 'list/:notebookId',
                    builder: (c, s) => NoteListScreen(
                      notebookId: int.parse(s.pathParameters['notebookId']!),
                    ),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) => NoteEditorScreen(
                      noteId: int.tryParse(
                        s.uri.queryParameters['noteId'] ?? '',
                      ),
                      notebookId: int.tryParse(
                        s.uri.queryParameters['notebookId'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (c, s) => const ScheduleTodayScreen(),
                routes: [
                  GoRoute(
                    path: 'day/:dateDay',
                    builder: (c, s) => ScheduleDayScreen(
                      dateDay: int.parse(s.pathParameters['dateDay']!),
                    ),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) => ScheduleEditScreen(
                      instanceId: int.tryParse(
                        s.uri.queryParameters['instanceId'] ?? '',
                      ),
                      templateId: int.tryParse(
                        s.uri.queryParameters['templateId'] ?? '',
                      ),
                      dateDay: int.tryParse(
                        s.uri.queryParameters['dateDay'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'templates',
                    builder: (c, s) => const TemplateManageScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      GoRoute(path: '/lock', builder: (c, s) => const LockScreen()),
    ],
  );
});

/// 供页面跳转用的小助手（统一命名，避免裸字符串散落）
extension AppNav on BuildContext {
  void openDiaryEditor([int? id]) =>
      id == null ? push('/diary/edit') : push('/diary/edit/$id');
  void openDiaryDetail(int id) => push('/diary/detail/$id');
  void openDiarySearch() => push('/diary/search');
  void openMoodTrend() => push('/diary/trend');
  void openNoteList(int notebookId) => push('/notes/list/$notebookId');
  void openNoteEditor({int? noteId, int? notebookId}) {
    final q = [
      if (noteId != null) 'noteId=$noteId',
      if (notebookId != null) 'notebookId=$notebookId',
    ].join('&');
    push(q.isEmpty ? '/notes/edit' : '/notes/edit?$q');
  }

  void openScheduleEdit({int? instanceId, int? templateId, int? dateDay}) {
    final q = [
      if (instanceId != null) 'instanceId=$instanceId',
      if (templateId != null) 'templateId=$templateId',
      if (dateDay != null) 'dateDay=$dateDay',
    ].join('&');
    push(q.isEmpty ? '/schedule/edit' : '/schedule/edit?$q');
  }

  void openScheduleDay(int dateDay) => push('/schedule/day/$dateDay');
  void openTemplates() => push('/schedule/templates');
  void openSettings() => push('/settings');
}
