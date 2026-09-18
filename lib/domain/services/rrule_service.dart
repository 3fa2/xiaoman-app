import 'package:intl/intl.dart';

/// 重复规则引擎 v4（纯 Dart，零依赖，支持 RFC5545 子集）。
///
/// 支持：
/// - FREQ=DAILY(+INTERVAL)
/// - FREQ=WEEKLY(+INTERVAL)(+BYDAY=MO,TU..)
/// - FREQ=MONTHLY(+INTERVAL)(+BYSETPOS=n;BYDAY=xx 第 n 个周几 | BYMONTHDAY=dd)
/// - FREQ=YEARLY（每年起始日）
/// - 例外日期 EXDATE 由 [exdatesCsv]（csv yyyymmdd）在展开层剔除
class RruleService {
  RruleService._();

  static const dayNames = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  static const _dayMap = {
    'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7,
  };

  static Map<String, String> parse(String rrule) {
    final parts = <String, String>{};
    for (final seg in rrule.split(';')) {
      final kv = seg.split('=');
      if (kv.length == 2) parts[kv[0].trim().toUpperCase()] = kv[1].trim();
    }
    return parts;
  }

  /// 展开日期（仅日期）。[start] 首次发生，[rangeStart]..[rangeEnd] 为窗口。
  /// [exdatesCsv] 例：'20260921,20260928'。
  static List<int> expand({
    required String rrule,
    required DateTime start,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    String exdatesCsv = '',
  }) {
    if (rrule.isEmpty) return const [];
    final parts = parse(rrule);
    final freq = (parts['FREQ'] ?? 'DAILY').toUpperCase();
    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final byDayRaw = parts['BYDAY'] ?? '';
    final bySetPos = int.tryParse(parts['BYSETPOS'] ?? '') ?? 0;
    final byMonthDay = int.tryParse(parts['BYMONTHDAY'] ?? '') ?? 0;

    final startDay = DateTime(start.year, start.month, start.day);
    final winStart = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final winEnd = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    if (winEnd.isBefore(winStart)) return const [];

    final excluded = _parseExdates(exdatesCsv);
    final result = <int>[];

    void addIfInWindow(DateTime d) {
      if (d.isBefore(startDay) || d.isAfter(winEnd)) return;
      final dd = d.year * 10000 + d.month * 100 + d.day;
      if (excluded.contains(dd)) return;
      if (d.isBefore(winStart)) return;
      result.add(dd);
    }

    switch (freq) {
      case 'DAILY':
        var d = startDay;
        // 先快进到窗口起点，再逐日展开（ceil 对齐到第一个 >= winStart 的日期）
        if (d.isBefore(winStart)) {
          final diff = winStart.difference(d).inDays;
          final steps = (diff / interval).ceil() * interval;
          d = d.add(Duration(days: steps));
        }
        while (!d.isAfter(winEnd)) {
          addIfInWindow(d);
          d = d.add(Duration(days: interval));
        }
        break;
      case 'WEEKLY':
        final days = _parseByDay(byDayRaw);
        var week = _weekMonday(startDay);
        while (!week.isAfter(winEnd)) {
          if (days.isEmpty) {
            // 无 BYDAY：start 日所在周几，每 interval 周
            addIfInWindow(week.add(Duration(days: startDay.weekday - 1)));
          } else {
            for (final wd in days) {
              addIfInWindow(week.add(Duration(days: wd - 1)));
            }
          }
          week = week.add(Duration(days: 7 * interval));
        }
        break;
      case 'MONTHLY':
        final days = _parseByDay(byDayRaw);
        var cursor = DateTime(start.year, start.month, 1);
        var i = 0;
        while (!cursor.isAfter(DateTime(winEnd.year, winEnd.month, 1))) {
          final inMonth = i % interval == 0;
          if (inMonth) {
            if (days.isNotEmpty && bySetPos > 0) {
              // 每月第 n 个周几
              final nths =
                  _nthWeekdays(cursor.year, cursor.month, days, bySetPos);
              for (final d in nths) {
                addIfInWindow(d);
              }
            } else if (byMonthDay > 0) {
              // 每月某日
              final last = DateTime(cursor.year, cursor.month + 1, 0).day;
              if (byMonthDay <= last) {
                addIfInWindow(DateTime(cursor.year, cursor.month, byMonthDay));
              }
            } else {
              final day = startDay.day;
              final last = DateTime(cursor.year, cursor.month + 1, 0).day;
              if (day <= last) {
                addIfInWindow(DateTime(cursor.year, cursor.month, day));
              }
            }
          }
          cursor = DateTime(cursor.year, cursor.month + 1, 1);
          i++;
        }
        break;
      case 'YEARLY':
        var cursor = DateTime(start.year, start.month, start.day);
        var i = 0;
        while (!cursor.isAfter(winEnd)) {
          if (i % interval == 0) addIfInWindow(cursor);
          cursor = DateTime(cursor.year + 1, cursor.month, cursor.day);
          i++;
        }
        break;
      default:
        break;
    }

    result.sort();
    return result;
  }

  static Set<int> _parseExdates(String csv) {
    final out = <int>{};
    for (final token in csv.split(',')) {
      final v = int.tryParse(token.trim());
      if (v != null) out.add(v);
    }
    return out;
  }

  static List<int> _parseByDay(String byDay) {
    if (byDay.isEmpty) return const [];
    return byDay
        .split(',')
        .map((d) => _dayMap[d.trim().toUpperCase()])
        .whereType<int>()
        .toList();
  }

  static DateTime _weekMonday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  static List<DateTime> _nthWeekdays(
    int year, int month, List<int> weekdays, int n,
  ) {
    final out = <DateTime>[];
    for (final wd in weekdays) {
      final first = DateTime(year, month, 1);
      final offset = (wd - first.weekday) % 7;
      var d = first.add(Duration(days: offset));
      var count = 1;
      while (d.month == month) {
        if (count == n) {
          out.add(d);
          break;
        }
        d = d.add(const Duration(days: 7));
        count++;
      }
    }
    return out;
  }

  /// 中文语义 → RRULE 字符串（编辑器用）
  static String? build({
    required RepeatFreq freq,
    int interval = 1,
    List<int> weekdays = const [],
    int nthWeek = 0,
    int monthDay = 0,
  }) {
    switch (freq) {
      case RepeatFreq.none:
        return null;
      case RepeatFreq.daily:
        return interval == 1 ? 'FREQ=DAILY' : 'FREQ=DAILY;INTERVAL=$interval';
      case RepeatFreq.weekly:
        if (weekdays.isEmpty) {
          return interval == 1 ? 'FREQ=WEEKLY' : 'FREQ=WEEKLY;INTERVAL=$interval';
        }
        final days = weekdays.map((w) => dayNames[w.clamp(0, 6)]).join(',');
        return 'FREQ=WEEKLY;BYDAY=$days'
            '${interval == 1 ? '' : ';INTERVAL=$interval'}';
      case RepeatFreq.monthlyByNthWeekday:
        if (weekdays.isEmpty || nthWeek <= 0) return 'FREQ=MONTHLY';
        final days = weekdays.map((w) => dayNames[w.clamp(0, 6)]).join(',');
        return 'FREQ=MONTHLY;BYDAY=$days;BYSETPOS=$nthWeek';
      case RepeatFreq.monthlyByDate:
        if (monthDay <= 0) return 'FREQ=MONTHLY';
        return 'FREQ=MONTHLY;BYMONTHDAY=$monthDay';
      case RepeatFreq.yearly:
        return 'FREQ=YEARLY';
    }
  }
}

enum RepeatFreq {
  none,
  daily,
  weekly,
  monthlyByNthWeekday,
  monthlyByDate,
  yearly,
}

/// 展示工具（页面用）
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String formatDateDay(int dateDay, {String pattern = 'MM月dd日 EEE'}) {
  final d = DateTime(dateDay ~/ 10000, (dateDay ~/ 100) % 100, dateDay % 100);
  Intl.defaultLocale = 'zh_CN';
  return DateFormat(pattern).format(d);
}

/// RRULE 中文摘要（模板页展示用）
String describeRrule(String? rrule) {
  if (rrule == null || rrule.isEmpty) return '不重复';
  final parts = RruleService.parse(rrule);
  final freq = (parts['FREQ'] ?? 'DAILY').toUpperCase();
  final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
  final intervalText = interval > 1 ? '$interval ' : '';
  const dayCn = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  switch (freq) {
    case 'DAILY':
      return interval == 1 ? '每天' : '每 $interval 天';
    case 'WEEKLY':
      final byDay = parts['BYDAY'] ?? '';
      if (byDay.isEmpty) return '每周';
      final names = byDay
          .split(',')
          .map((d) {
            const map = {
              'MO': 0, 'TU': 1, 'WE': 2, 'TH': 3, 'FR': 4, 'SA': 5, 'SU': 6,
            };
            final i = map[d.trim().toUpperCase()];
            return i == null ? '' : dayCn[i];
          })
          .where((s) => s.isNotEmpty)
          .join('、');
      return '$intervalText每周$names';
    case 'MONTHLY':
      final bySetPos = int.tryParse(parts['BYSETPOS'] ?? '') ?? 0;
      final byMonthDay = int.tryParse(parts['BYMONTHDAY'] ?? '') ?? 0;
      final byDay = parts['BYDAY'] ?? '';
      if (bySetPos > 0 && byDay.isNotEmpty) {
        const map = {
          'MO': 0, 'TU': 1, 'WE': 2, 'TH': 3, 'FR': 4, 'SA': 5, 'SU': 6,
        };
        final i = map[byDay.split(',').first.trim().toUpperCase()] ?? 0;
        return '每月第$bySetPos个${dayCn[i]}';
      }
      if (byMonthDay > 0) return '每月$byMonthDay日';
      return '每月';
    case 'YEARLY':
      return '每年';
    default:
      return '不重复';
  }
}
