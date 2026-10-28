import '../models/diary.dart';

/// 记录统计核心（纯函数，无 Flutter 依赖，可单测）。
/// 供统计页与「每日打卡日记提醒」文案共用。

int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// 从 [today] 起往回数的连续记录天数。
/// 今天没写不断链：从容从昨天起算（昨天的记录仍算连续）。
int streakDays(List<Diary> diaries, DateTime today) =>
    streakUntil(diaries, today, includeToday: true);

/// 到 [anchor] 为止的连续记录天数。
/// [includeToday]=false 时从 anchor 的前一天起算（"到昨天为止的连续数"，
/// 打卡提醒文案用）；=true 时 anchor 当天没写则从容从昨天起算。
int streakUntil(
  List<Diary> diaries,
  DateTime anchor, {
  bool includeToday = true,
}) {
  final days = diaries.map((d) => d.dateDay).toSet();
  var cursor = DateTime(anchor.year, anchor.month, anchor.day);
  if (includeToday && days.contains(_dayKey(cursor))) {
    // anchor 当天有记录：从这里开始数
  } else {
    // includeToday=false 恒从前一天起算；includeToday=true 且当天没写也从前一天起算
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(_dayKey(cursor))) return 0;
  }
  var n = 0;
  while (days.contains(_dayKey(cursor))) {
    n++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return n;
}

/// [anchor] 当天是否已有记录
bool writtenOn(List<Diary> diaries, DateTime anchor) =>
    diaries.any((d) => d.dateDay == _dayKey(anchor));

/// 最长连续（全量扫描，按日期升序找连续段）
int longestStreak(List<Diary> diaries) {
  if (diaries.isEmpty) return 0;
  final days = diaries.map((d) => d.dateDay).toSet().toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final prev = days[i - 1];
    final cur = days[i];
    final pd = DateTime(prev ~/ 10000, (prev ~/ 100) % 100, prev % 100);
    final next = pd.add(const Duration(days: 1));
    if (_dayKey(next) == cur) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
  }
  return best;
}
