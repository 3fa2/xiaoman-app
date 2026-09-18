import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/domain/services/rrule_service.dart';

void main() {
  group('RruleService.expand', () {
    test('DAILY 每天一次', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=DAILY',
        start: DateTime(2026, 9, 1),
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 9, 7),
      );
      expect(dates.length, 7);
      expect(dates.first, 20260901);
      expect(dates.last, 20260907);
    });

    test('DAILY INTERVAL=3 隔三天', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=DAILY;INTERVAL=3',
        start: DateTime(2026, 9, 1),
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 9, 15),
      );
      expect(dates, [20260901, 20260904, 20260907, 20260910, 20260913]);
    });

    test('WEEKLY BYDAY 周一三五', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        start: DateTime(2026, 9, 7), // 周一
        rangeStart: DateTime(2026, 9, 7),
        rangeEnd: DateTime(2026, 9, 13),
      );
      // 2026-09-07 是周一：7(一) 9(三) 11(五)
      expect(dates, [20260907, 20260909, 20260911]);
    });

    test('MONTHLY 第 2 个周一', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2',
        start: DateTime(2026, 8, 1),
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 10, 31),
      );
      // 2026-09 月第 2 个周一 = 9/14；10 月 = 10/12
      expect(dates, [20260914, 20261012]);
    });

    test('MONTHLY BYMONTHDAY 每月 15 日', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=15',
        start: DateTime(2026, 8, 1),
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 10, 31),
      );
      expect(dates, [20260915, 20261015]);
    });

    test('YEARLY 每年一次', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=YEARLY',
        start: DateTime(2025, 12, 31),
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2027, 12, 31),
      );
      expect(dates, [20261231, 20271231]);
    });

    test('EXDATE 例外日剔除（跳过某天）', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=DAILY',
        start: DateTime(2026, 9, 1),
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 9, 5),
        exdatesCsv: '20260903',
      );
      expect(dates, [20260901, 20260902, 20260904, 20260905]);
    });

    test('窗口裁剪：start 早于窗口时只返回窗口内', () {
      final dates = RruleService.expand(
        rrule: 'FREQ=DAILY',
        start: DateTime(2026, 8, 1),
        rangeStart: DateTime(2026, 9, 10),
        rangeEnd: DateTime(2026, 9, 12),
      );
      expect(dates, [20260910, 20260911, 20260912]);
    });
  });

  group('RruleService.build', () {
    test('weekly byday', () {
      expect(
        RruleService.build(
          freq: RepeatFreq.weekly,
          weekdays: [0, 2, 4], // 0=周一
        ),
        'FREQ=WEEKLY;BYDAY=MO,WE,FR',
      );
    });

    test('monthly by nth weekday', () {
      expect(
        RruleService.build(
          freq: RepeatFreq.monthlyByNthWeekday,
          weekdays: [0], // 0=周一
          nthWeek: 2,
        ),
        'FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2',
      );
    });

    test('none 返回 null', () {
      expect(RruleService.build(freq: RepeatFreq.none), isNull);
    });
  });

  test('DateDay 工具', () {
    final d = DateTime(2026, 9, 19);
    final dd = d.year * 10000 + d.month * 100 + d.day;
    expect(dd, 20260919);
    final back = DateTime(dd ~/ 10000, (dd ~/ 100) % 100, dd % 100);
    expect(back.year, 2026);
    expect(back.month, 9);
    expect(back.day, 19);
  });
}
