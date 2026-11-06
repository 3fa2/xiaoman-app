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

// ---- 年度回顾 + 写作时段（v5.9.1，DiaryX writing patterns 借鉴）----

/// 年度回顾快照（Wrapped 风格）：某一年度全部核心数字。
class YearlyStats {
  final int year;
  final int entries; // 总篇数
  final int totalChars; // 总字数（标题+正文）
  final int activeDays; // 有记录的天数
  final int bestMonth; // 最高产月份（1-12，0=全年无记录）
  final int bestMonthEntries;
  final String? topMood; // 最常心情名（null=全年没打过心情）
  final int topMoodCount;
  final int longestStreakDays;

  const YearlyStats({
    required this.year,
    required this.entries,
    required this.totalChars,
    required this.activeDays,
    required this.bestMonth,
    required this.bestMonthEntries,
    required this.topMood,
    required this.topMoodCount,
    required this.longestStreakDays,
  });
}

/// 汇总 [year] 年度的回顾数据。moods 提供心情名映射。
YearlyStats yearlyStats(
  List<Diary> diaries,
  Map<int, String> moodNames,
  int year,
) {
  final inYear = diaries.where((d) => d.dateDay ~/ 10000 == year).toList();
  final totalChars =
      inYear.fold<int>(0, (n, d) => n + d.title.length + d.content.length);
  final activeDays = inYear.map((d) => d.dateDay).toSet().length;

  final perMonth = List<int>.filled(12, 0);
  for (final d in inYear) {
    perMonth[(d.dateDay ~/ 100) % 100 - 1]++;
  }
  var bestMonth = 0;
  var bestMonthEntries = 0;
  for (var m = 0; m < 12; m++) {
    if (perMonth[m] > bestMonthEntries) {
      bestMonthEntries = perMonth[m];
      bestMonth = m + 1;
    }
  }

  final moodCounts = <int, int>{};
  for (final d in inYear) {
    if (d.moodId != null) moodCounts[d.moodId!] = (moodCounts[d.moodId!] ?? 0) + 1;
  }
  String? topMood;
  var topMoodCount = 0;
  // 平局规则（隐式约定）：严格大于 → 并列时取 diaries 遍历序中最先出现者
  for (final e in moodCounts.entries) {
    if (e.value > topMoodCount) {
      topMoodCount = e.value;
      topMood = moodNames[e.key] ?? '已删心情';
    }
  }

  return YearlyStats(
    year: year,
    entries: inYear.length,
    totalChars: totalChars,
    activeDays: activeDays,
    bestMonth: bestMonth,
    bestMonthEntries: bestMonthEntries,
    topMood: topMood,
    topMoodCount: topMoodCount,
    longestStreakDays: longestStreak(inYear),
  );
}

/// 写作时段分布（6 个时段的篇数）：凌晨(0-6) 早晨(6-9) 上午(9-12)
/// 下午(12-17) 傍晚(17-21) 夜晚(21-24)。基于 createdAt 的小时。
List<int> hourBuckets(List<Diary> diaries) {
  final buckets = List<int>.filled(6, 0);
  for (final d in diaries) {
    final h = d.createdAt.hour;
    if (h < 6) {
      buckets[0]++;
    } else if (h < 9) {
      buckets[1]++;
    } else if (h < 12) {
      buckets[2]++;
    } else if (h < 17) {
      buckets[3]++;
    } else if (h < 21) {
      buckets[4]++;
    } else {
      buckets[5]++;
    }
  }
  return buckets;
}

/// 时段名称（与 hourBuckets 下标对应）
const hourBucketNames = ['凌晨', '早晨', '上午', '下午', '傍晚', '夜晚'];
