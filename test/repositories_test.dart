import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/data/db/database.dart';
import 'package:trinity/data/repositories/diary_repository.dart';
import 'package:trinity/data/repositories/media_repository.dart';
import 'package:trinity/data/repositories/note_repository.dart';
import 'package:trinity/data/repositories/schedule_repository.dart';
import 'package:trinity/data/repositories/settings_repository.dart';
import 'package:trinity/domain/models/media.dart';
import 'package:trinity/domain/models/schedule.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  group('DiaryRepository', () {
    test('save + getById + watchAll', () async {
      final repo = DiaryRepositoryImpl(db);
      final id = await repo.save(
        id: null, title: '第一篇', content: '内容', extra: null,
      );
      final diary = await repo.getById(id);
      expect(diary, isNotNull);
      expect(diary!.title, '第一篇');
      final all = await repo.watchAll().first;
      expect(all.length, 1);
    });

    test('update 走 updatedAt', () async {
      final repo = DiaryRepositoryImpl(db);
      final id = await repo.save(id: null, title: 'a', content: 'b', extra: null);
      final before = await repo.getById(id);
      // drift 把 DateTime 存成秒级时间戳，间隔需 >1s 才能保证不等
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await repo.save(id: id, title: 'a2', content: 'b2', extra: null);
      final after = await repo.getById(id);
      expect(after!.updatedAt.isAfter(before!.updatedAt), isTrue);
    });

    test('FTS5 搜索：3 字以上走 MATCH，短词回退 LIKE', () async {
      final repo = DiaryRepositoryImpl(db);
      await repo.save(id: null, title: '工作会议', content: '讨论季度目标', extra: null);
      await repo.save(id: null, title: '买菜', content: '西红柿和鸡蛋', extra: null);

      final r1 = await repo.search('季度目标');
      expect(r1.length, 1);
      expect(r1.first.title, '工作会议');

      final r2 = await repo.search('鸡蛋');
      expect(r2.length, 1);
      expect(r2.first.title, '买菜');
    });

    test('心情预设种子 + setMood', () async {
      final repo = DiaryRepositoryImpl(db);
      final moods = await repo.watchMoods().first;
      expect(moods.length, 8);
      final id = await repo.save(id: null, title: 't', content: 'c', extra: null);
      await repo.setMood(diaryId: id, moodId: moods.first.id);
      final d = await repo.getById(id);
      expect(d!.moodId, moods.first.id);
    });

    test('日记标签：setTags 落库 + 读回 csv 转 List + 按标签搜索', () async {
      final repo = DiaryRepositoryImpl(db);
      final id = await repo.save(id: null, title: '旅行', content: '去海边', extra: null);
      // 初始无标签
      expect((await repo.getById(id))!.tags, isEmpty);
      // 写入标签
      await repo.setTags(diaryId: id, tags: ['旅行', '夏天']);
      final d = await repo.getById(id);
      expect(d!.tags, ['旅行', '夏天']);
      // LIKE 回退能搜到标签
      final r = await repo.search('夏天');
      expect(r.length, 1);
      expect(r.first.title, '旅行');
    });

    test('日记本：建本 + 归属过滤 + 删除本后日记变未归本', () async {
      final repo = DiaryRepositoryImpl(db);
      final nbId = await repo.saveDiaryNotebook(
        id: null, name: '碎碎念', colorIndex: 1,
      );
      // 两篇日记：一篇归本、一篇不归
      final inBook = await repo.save(
        id: null, title: '本内', content: 'a', extra: null,
      );
      final outside = await repo.save(
        id: null, title: '本外', content: 'b', extra: null,
      );
      await repo.setNotebook(diaryId: inBook, notebookId: nbId);
      // 篇数统计
      final notebooks = await repo.watchDiaryNotebooks().first;
      expect(notebooks.single.$1.name, '碎碎念');
      expect(notebooks.single.$2, 1);
      // 按本过滤
      final inList = await repo
          .watchByMonthIn(202609, nbId)
          .first;
      expect(inList.map((d) => d.title), ['本内']);
      // 未归本过滤（-1）
      final outList = await repo.watchByMonthIn(202609, -1).first;
      expect(outList.map((d) => d.title), ['本外']);
      // 全部视图两篇都有
      expect((await repo.watchByMonthIn(202609, null).first).length, 2);
      // 删除本：日记保留变未归本
      await repo.deleteDiaryNotebook(nbId);
      expect((await repo.watchDiaryNotebooks().first).isEmpty, isTrue);
      final d = await repo.getById(inBook);
      expect(d!.notebookId, isNull);
      // 防止未使用变量警告
      expect(outside, isPositive);
    });
  });

  group('NoteRepository', () {
    test('notebook + note + todo 全链路', () async {
      final repo = NoteRepositoryImpl(db);
      await repo.saveNotebook(id: null, name: '灵感', colorIndex: 2);
      final notebooks = await repo.watchNotebooks().first;
      expect(notebooks.length, 1);
      expect(notebooks.first.colorIndex, 2);

      final noteId = await repo.saveNote(
        id: null,
        notebookId: notebooks.first.id,
        title: '清单',
        content: '- [ ] 买菜',
        tags: ['生活'],
        pinned: false,
      );
      final notes = await repo.watchNotes(notebooks.first.id).first;
      expect(notes.length, 1);
      expect(notes.first.tags, ['生活']);

      await repo.addTodo(noteId: noteId, text: '买咖啡');
      final todos = await repo.watchTodos(noteId).first;
      expect(todos.length, 1);
      await repo.toggleTodo(todoId: todos.first.id, done: true);
      final todos2 = await repo.watchTodos(noteId).first;
      expect(todos2.first.done, isTrue);
    });

    test('删除笔记本级联删笔记', () async {
      final repo = NoteRepositoryImpl(db);
      await repo.saveNotebook(id: null, name: 'A', colorIndex: 0);
      final nbs = await repo.watchNotebooks().first;
      final noteId = await repo.saveNote(
        id: null, notebookId: nbs.first.id, title: 'x', content: 'y',
        tags: [], pinned: false,
      );
      await repo.addTodo(noteId: noteId, text: 't1');
      await repo.deleteNotebook(nbs.first.id);
      expect((await repo.watchNotebooks().first), isEmpty);
      expect(await repo.getNoteById(noteId), isNull);
    });

    test('FTS5 笔记搜索', () async {
      final repo = NoteRepositoryImpl(db);
      await repo.saveNotebook(id: null, name: 'B', colorIndex: 0);
      final nbs = await repo.watchNotebooks().first;
      await repo.saveNote(
        id: null, notebookId: nbs.first.id, title: '量化策略',
        content: '动量因子回测', tags: [], pinned: false,
      );
      final r = await repo.searchNotes('动量因子');
      expect(r.length, 1);
    });

    test('自动保存通道（EditorRepository.save）不清空 tags/pinned', () async {
      final repo = NoteRepositoryImpl(db);
      await repo.saveNotebook(id: null, name: 'C', colorIndex: 0);
      final nbs = await repo.watchNotebooks().first;
      final id = await repo.saveNote(
        id: null, notebookId: nbs.first.id, title: 'a', content: 'b',
        tags: ['重要'], pinned: true,
      );
      // 模拟打字触发的自动保存（只传标题正文）
      await repo.save(id: id, title: 'a2', content: 'b2', extra: nbs.first.id);
      final note = await repo.getNoteById(id);
      expect(note!.title, 'a2');
      expect(note.tags, ['重要']);
      expect(note.pinned, isTrue);
    });
  });

  group('ScheduleRepository', () {
    test('saveInstance + watchDay + setStatus', () async {
      final repo = ScheduleRepositoryImpl(db);
      final id = await repo.saveInstance(
        id: null, templateId: null, dateDay: 20260919,
        startMinutes: 540, durationMinutes: 90,
        title: '晨会', description: '', colorIndex: 1,
        detachOnEdit: false, remindMinutesBefore: 15,
      );
      final day = await repo.watchDay(20260919).first;
      expect(day.length, 1);
      expect(day.first.remindAt, isNotNull);

      await repo.setStatus(id: id, status: BlockStatus.done);
      final day2 = await repo.watchDay(20260919).first;
      expect(day2.first.status, BlockStatus.done);
    });

    test('regenerate 幂等 + skip-on-conflict 落库', () async {
      final repo = ScheduleRepositoryImpl(db);
      await repo.saveTemplate(
        ScheduleTemplate(
          id: 0, title: '每日站会', description: '', colorIndex: 0,
          rrule: 'FREQ=DAILY', exdates: '', startMinutes: 540,
          durationMinutes: 30, remindMinutesBefore: 0, enabled: true,
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
        ),
        isNew: true,
      );
      final today = DateDay.of(DateTime.now());
      // 生成窗口 = 今天起 14 天；查询窗口取前 3 天交集
      final round1 =
          await repo.watchRange(today, DateDay.addDays(today, 2)).first;
      expect(round1.length, 3);

      // 再跑一遍：不重复（幂等）
      await repo.regenerate();
      final round2 =
          await repo.watchRange(today, DateDay.addDays(today, 2)).first;
      expect(round2.length, 3);
    });

    test('regenerate 生成的模板实例带 remindAt（模板提醒生效）', () async {
      final repo = ScheduleRepositoryImpl(db);
      await repo.saveTemplate(
        ScheduleTemplate(
          id: 0, title: '带提醒的重复', description: '', colorIndex: 0,
          rrule: 'FREQ=DAILY', exdates: '', startMinutes: 540,
          durationMinutes: 30, remindMinutesBefore: 10, enabled: true,
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
        ),
        isNew: true,
      );
      final today = DateDay.of(DateTime.now());
      final instances =
          await repo.watchRange(today, DateDay.addDays(today, 1)).first;
      expect(instances.length, 2);
      expect(instances.first.remindAt, isNotNull);
      // remindAt = 当天 00:00 + (540 - 10) 分钟 = 08:50
      final day = DateDay.toDateTime(instances.first.dateDay);
      expect(
        instances.first.remindAt,
        DateTime(day.year, day.month, day.day, 8, 50),
      );
    });

    test('skipTemplateOccurrence 写 exdates 并删该次实例', () async {
      final repo = ScheduleRepositoryImpl(db);
      final tid = await repo.saveTemplate(
        ScheduleTemplate(
          id: 0, title: '跑步', description: '', colorIndex: 0,
          rrule: 'FREQ=DAILY', exdates: '', startMinutes: 420,
          durationMinutes: 60, remindMinutesBefore: 0, enabled: true,
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
        ),
        isNew: true,
      );
      final tpl = await repo.getTemplate(tid);
      final tomorrow = DateDay.addDays(
        DateDay.of(DateTime.now()), 1,
      );
      await repo.skipTemplateOccurrence(template: tpl!, dateDay: tomorrow);
      final tpl2 = await repo.getTemplate(tid);
      expect(tpl2!.exdates, contains(tomorrow.toString()));
      final day = await repo.watchDay(tomorrow).first;
      expect(day, isEmpty);
    });

    test('detach 实例在模板更新后保留', () async {
      final repo = ScheduleRepositoryImpl(db);
      final tid = await repo.saveTemplate(
        ScheduleTemplate(
          id: 0, title: '锻炼', description: '', colorIndex: 0,
          rrule: 'FREQ=DAILY', exdates: '', startMinutes: 420,
          durationMinutes: 60, remindMinutesBefore: 0, enabled: true,
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
        ),
        isNew: true,
      );
      final tpl = await repo.getTemplate(tid);
      final tomorrow = DateDay.addDays(DateDay.of(DateTime.now()), 1);
      final instances = await repo.watchDay(tomorrow).first;
      final instId = instances.first.id;
      // 手动编辑 → detach
      await repo.saveInstance(
        id: instId, templateId: tid, dateDay: tomorrow,
        startMinutes: 600, durationMinutes: 60,
        title: '锻炼（改）', description: '', colorIndex: 0,
        detachOnEdit: true, remindMinutesBefore: 0,
      );
      // 模板更新（改时间）
      await repo.saveTemplate(
        ScheduleTemplate(
          id: tid, title: '锻炼', description: '', colorIndex: 0,
          rrule: 'FREQ=DAILY', exdates: '', startMinutes: 500,
          durationMinutes: 60, remindMinutesBefore: 0, enabled: true,
          createdAt: tpl!.createdAt, updatedAt: DateTime.now(),
        ),
        isNew: false,
      );
      final after = await repo.watchDay(tomorrow).first;
      final detached = after.where((e) => e.id == instId).toList();
      expect(detached, isNotEmpty); // 分离实例没被删
      expect(detached.first.startMinutes, 600); // 时间还是用户改的
      expect(detached.first.detached, isTrue);
    });
  });

  group('Draft', () {
    test('save + find + clear', () async {
      final repo = DiaryRepositoryImpl(db);
      await repo.saveDraft(
        ownerType: MediaOwner.diary, ownerId: -1,
        payload: '{"title":"x"}',
      );
      final d = await repo.findDraft(
        ownerType: MediaOwner.diary, ownerId: -1,
      );
      expect(d, isNotNull);
      expect(d!.payload, contains('title'));
      await repo.saveDraft(
        ownerType: MediaOwner.diary, ownerId: -1,
        payload: '{"title":"y"}',
      );
      final d2 = await repo.findDraft(
        ownerType: MediaOwner.diary, ownerId: -1,
      );
      expect(d2!.payload, contains('"title":"y"'));
      await repo.clearDraft(ownerType: MediaOwner.diary, ownerId: -1);
      final d3 = await repo.findDraft(
        ownerType: MediaOwner.diary, ownerId: -1,
      );
      expect(d3, isNull);
    });
  });

  group('MediaRepository', () {
    test('attach + watchFor + remove', () async {
      final repo = MediaRepositoryImpl(db);
      final id = await repo.attach(
        MediaItem(
          id: 0, ownerType: MediaOwner.diary, ownerId: 1,
          kind: MediaKind.livePhoto, coverPath: '/tmp/a.jpg',
          videoPath: '/tmp/a.mp4', thumbPath: null, sortOrder: 0,
          width: null, height: null, durationMs: null,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final list = await repo.watchFor(MediaOwner.diary, 1).first;
      expect(list.length, 1);
      expect(list.first.kind, MediaKind.livePhoto);
      await repo.remove(id);
      expect(await repo.watchFor(MediaOwner.diary, 1).first, isEmpty);
    });
  });

  group('Settings', () {
    test('get/set roundtrip', () async {
      final impl = SettingsRepositoryImpl(db);
      await impl.set('theme_mode', 'dark');
      expect(await impl.get('theme_mode'), 'dark');
    });
  });
}
