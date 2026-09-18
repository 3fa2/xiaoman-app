/// 领域模型 · 日程（模板 / 实例分离，纯 Dart）
enum BlockStatus { pending, done, skipped }

/// 重复模板（规则 + 时间槽）。rrule 为 RFC5545 子集：
/// FREQ=DAILY/WEEKLY/MONTHLY/YEARLY (+INTERVAL) (+BYDAY / BYSETPOS / BYMONTHDAY)
class ScheduleTemplate {
  final int id;
  final String title;
  final String description;
  final int colorIndex;
  final String? rrule;
  final String exdates; // csv yyyymmdd，跳过某天（EXDATE，可撤销）
  final int startMinutes;
  final int durationMinutes;
  final int remindMinutesBefore;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.colorIndex,
    required this.rrule,
    required this.exdates,
    required this.startMinutes,
    required this.durationMinutes,
    required this.remindMinutesBefore,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// 具体某天的块。templateId=null 为手工块；detached=true 不再受模板更新影响。
class ScheduleInstance {
  final int id;
  final int? templateId;
  final int dateDay; // yyyymmdd
  final int startMinutes; // 0-1439
  final int durationMinutes;
  final String title;
  final String description;
  final int colorIndex;
  final BlockStatus status;
  final bool detached;
  final DateTime? remindAt; // epoch ms
  final DateTime? notifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleInstance({
    required this.id,
    required this.templateId,
    required this.dateDay,
    required this.startMinutes,
    required this.durationMinutes,
    required this.title,
    required this.description,
    required this.colorIndex,
    required this.status,
    required this.detached,
    required this.remindAt,
    required this.notifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  int get endMinutes => startMinutes + durationMinutes;

  bool overlaps(ScheduleInstance other) =>
      dateDay == other.dateDay &&
      startMinutes < other.endMinutes &&
      other.startMinutes < endMinutes;
}

/// 日期工具（yyyymmdd int ↔ DateTime，纯函数）
abstract final class DateDay {
  static int of(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime toDateTime(int dateDay) =>
      DateTime(dateDay ~/ 10000, (dateDay ~/ 100) % 100, dateDay % 100);

  static int addDays(int dateDay, int days) =>
      of(toDateTime(dateDay).add(Duration(days: days)));
}
