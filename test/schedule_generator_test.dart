import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/domain/models/schedule.dart';
import 'package:trinity/domain/services/schedule_generator.dart';

ScheduleTemplate _tpl(
  int id,
  String rrule,
  int start, {
  bool enabled = true,
  int? startDate,
  int? endDate,
}) =>
    ScheduleTemplate(
      id: id,
      title: 'T$id',
      description: '',
      colorIndex: 0,
      rrule: rrule,
      exdates: '',
      startDate: startDate,
      endDate: endDate,
      startMinutes: start,
      durationMinutes: 60,
      remindMinutesBefore: 0,
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

ScheduleInstance _existing({
  int? templateId,
  required int dateDay,
  required int start,
  int duration = 60,
  bool detached = false,
  BlockStatus status = BlockStatus.pending,
  int id = 1,
}) =>
    ScheduleInstance(
      id: id,
      templateId: templateId,
      dateDay: dateDay,
      startMinutes: start,
      durationMinutes: duration,
      title: 'X',
      description: '',
      colorIndex: 0,
      status: status,
      detached: detached,
      remindAt: null,
      notifiedAt: null,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  final rangeStart = DateTime(2026, 9, 7);
  final rangeEnd = DateTime(2026, 9, 13);

  test('生成每日模板实例', () {
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, 'FREQ=DAILY', 9 * 60)],
      existing: const [],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing.length, 7);
    expect(missing.first.dateDay, 20260907);
    expect(missing.first.startMinutes, 540);
  });

  test('幂等：已有实例不重复生成', () {
    final existing = [
      for (var d = 7; d <= 13; d++) _existing(templateId: 1, dateDay: 20260900 + d, start: 540),
    ];
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, 'FREQ=DAILY', 9 * 60)],
      existing: existing,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing, isEmpty);
  });

  test('skip-on-conflict：手工块占用时间段则跳过', () {
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, 'FREQ=DAILY', 9 * 60)],
      existing: [_existing(templateId: null, dateDay: 20260908, start: 9 * 60 + 30)],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    // 9/8 与手工块重叠 → 只生成 6 条，且不含 20260908
    expect(missing.length, 6);
    expect(missing.any((m) => m.dateDay == 20260908), isFalse);
  });

  test('detached 实例不被重新生成（分离保留）', () {
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, 'FREQ=DAILY', 9 * 60)],
      existing: [
        _existing(templateId: 1, dateDay: 20260908, start: 540, detached: true),
      ],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    // 9/8 已分离 → 不再补生成该日的模板实例
    expect(missing.any((m) => m.dateDay == 20260908), isFalse);
  });

  test('detached 实例被拖走后该日不补生成（不产生原时段副本）', () {
    // 回归：实例被拖到 14:00（与模板 9:00 不重叠）后，
    // regenerate 不得在 9:00 重新生成原时段副本
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, 'FREQ=DAILY', 9 * 60)],
      existing: [
        _existing(
          templateId: 1, dateDay: 20260908, start: 14 * 60, detached: true,
        ),
      ],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing.any((m) => m.dateDay == 20260908), isFalse);
  });

  test('禁用模板不生成', () {
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, 'FREQ=DAILY', 9 * 60, enabled: false)],
      existing: const [],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing, isEmpty);
  });

  test('shouldDropInstance：模板更新的未来未分离实例被标记删除', () {
    final future = _existing(templateId: 1, dateDay: 20260910, start: 540);
    final past = _existing(templateId: 1, dateDay: 20260901, start: 540);
    final detached = _existing(
      templateId: 1, dateDay: 20260910, start: 540, detached: true,
    );
    final done = _existing(
      templateId: 1, dateDay: 20260910, start: 540, status: BlockStatus.done,
    );
    const today = 20260907;
    expect(ScheduleGenerator.shouldDropInstance(future, today), isTrue);
    expect(ScheduleGenerator.shouldDropInstance(past, today), isFalse);
    expect(ScheduleGenerator.shouldDropInstance(detached, today), isFalse);
    expect(ScheduleGenerator.shouldDropInstance(done, today), isFalse);
  });

  test('单次：rrule 空 + startDate 生成当天 1 个实例（窗口外不生成）', () {
    // 窗口 9/7-9/13，单次日 9/25 在窗口外 → 不生成
    var missing = ScheduleGenerator.missing(
      templates: [_tpl(1, '', 9 * 60, startDate: 20260925)],
      existing: const [],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing, isEmpty);

    // 窗口含 9/25 → 恰好 1 个
    missing = ScheduleGenerator.missing(
      templates: [_tpl(1, '', 9 * 60, startDate: 20260925)],
      existing: const [],
      rangeStart: DateTime(2026, 9, 25),
      rangeEnd: DateTime(2026, 10, 8),
    );
    expect(missing.length, 1);
    expect(missing.first.dateDay, 20260925);
    expect(missing.first.startMinutes, 540);
  });

  test('连续几天：startDate..endDate 每天各 1 个（中秋 25/26/27）', () {
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, '', 9 * 60, startDate: 20260925, endDate: 20260927)],
      existing: const [],
      rangeStart: DateTime(2026, 9, 25),
      rangeEnd: DateTime(2026, 10, 8),
    );
    expect(missing.map((m) => m.dateDay), [20260925, 20260926, 20260927]);
  });

  test('老的"不重复"模板（rrule 空 + 无日期）不生成，不炸', () {
    final missing = ScheduleGenerator.missing(
      templates: [_tpl(1, '', 9 * 60)],
      existing: const [],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing, isEmpty);
  });

  test('重复规则 + startDate/endDate 作为范围过滤', () {
    final missing = ScheduleGenerator.missing(
      templates: [
        _tpl(
          1, 'FREQ=DAILY', 9 * 60,
          startDate: 20260910, endDate: 20260912,
        ),
      ],
      existing: const [],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing.map((m) => m.dateDay), [20260910, 20260911, 20260912]);
  });

  test('exdates 在生成层被剔除', () {
    final t = ScheduleTemplate(
      id: 1,
      title: 'T',
      description: '',
      colorIndex: 0,
      rrule: 'FREQ=DAILY',
      exdates: '20260909,20260910',
      startMinutes: 540,
      durationMinutes: 60,
      remindMinutesBefore: 0,
      enabled: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final missing = ScheduleGenerator.missing(
      templates: [t],
      existing: const [],
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    expect(missing.length, 5);
    expect(missing.any((m) => m.dateDay == 20260909), isFalse);
    expect(missing.any((m) => m.dateDay == 20260910), isFalse);
  });
}
