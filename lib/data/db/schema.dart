import 'package:drift/drift.dart';

/// v4 数据模型（旧数据不保留，schema 自由重构，一次做对）。
/// 对应 详细方案.md §4：
/// - 媒体统一成 media_items（替代 v3 的 5 个平行数组字段）
/// - 日程模板/实例分离（templateId + detached + status）
/// - drafts 草稿表（崩溃恢复）
///
/// ⚠️ 列名禁止与 drift 类型构造函数同名（text/integer/boolean/dateTime/real），
/// 否则 getter 自引用导致生成器解析失败（todo_items 曾用 text 踩坑，改 body）。

/// ① 日记主表
@DataClassName('DiariesRow')
class Diaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dateDay => integer()(); // yyyymmdd
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))(); // csv（v4.2 新增）
  IntColumn get moodId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 心情：8 预设 + 用户自定义（hue）
@DataClassName('MoodsRow')
class Moods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get hue => real()();
  BoolColumn get isPreset => boolean()();
  IntColumn get sortOrder => integer()();
}

/// ② 统一媒体表 ★ 最大改进
@DataClassName('MediaItemRow')
class MediaItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ownerType => integer()(); // 0 diary / 1 note
  IntColumn get ownerId => integer()();
  IntColumn get kind => integer()(); // 0 image / 1 video / 2 livePhoto
  TextColumn get coverPath => text().nullable()();
  TextColumn get videoPath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get sortOrder => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// ③ 备忘
@DataClassName('NotebookRow')
class Notebooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get colorIndex => integer()(); // 0=primary, 1-5
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('NoteRow')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get notebookId => integer()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))(); // csv
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('TodoItemRow')
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer()();
  TextColumn get body => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
}

/// ④ 日程：模板 + 实例分离 ★ 关键设计
@DataClassName('ScheduleTemplateRow')
class ScheduleTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  TextColumn get rrule => text().nullable()(); // RFC5545 子集
  TextColumn get exdates => text().withDefault(const Constant(''))(); // csv yyyymmdd
  IntColumn get startMinutes => integer()(); // 0-1439
  IntColumn get durationMinutes => integer()();
  IntColumn get remindMinutesBefore => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('ScheduleInstanceRow')
class ScheduleInstances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().nullable()(); // null = 手工块
  IntColumn get dateDay => integer()();
  IntColumn get startMinutes => integer()();
  IntColumn get durationMinutes => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  IntColumn get status => integer().withDefault(const Constant(0))(); // pending/done/skipped
  BoolColumn get detached => boolean().withDefault(const Constant(false))();
  DateTimeColumn get remindAt => dateTime().nullable()();
  DateTimeColumn get notifiedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// ⑤ 草稿（崩溃恢复）
@DataClassName('DraftRow')
class Drafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ownerType => integer()(); // 0 diary / 1 note
  IntColumn get ownerId => integer()(); // -1 = 新建未落库
  TextColumn get payload => text()(); // json
  DateTimeColumn get updatedAt => dateTime()();
}

/// ⑥ 设置
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

/// ⑦ 全文索引（FTS5 external content + 触发器，见 database.dart）
/// diaries_fts(content, title) / notes_fts(content, title, tags)
