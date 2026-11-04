import 'rrule_service.dart';
import '../models/schedule.dart';

/// 模板 → 实例生成引擎（纯 Dart）。
///
/// 两条关键语义（TimePlanner 蓝本，别家都没有）：
/// 1. detach（分离）：实例 detached=true 后不再受模板更新影响
/// 2. skip-on-conflict：模板生成实例时，若与已有手工块（templateId=null）
///    或其他模板实例时间段冲突，则跳过，不覆盖用户自己排的块。
///
/// 生成策略：滚动窗口，只物化 [rangeStart]..[rangeEnd]（默认未来 14 天），
/// 每天滚动补生成。不一次性生成一年。
class ScheduleGenerator {
  ScheduleGenerator._();

  /// 滚动窗口天数
  static const windowDays = 14;

  /// 生成窗口内缺失的实例（需要新插入的，无 id）。
  ///
  /// [templates] 启用中的模板；[existing] 数据库中该窗口内已有实例。
  static List<NewInstance> missing({
    required List<ScheduleTemplate> templates,
    required List<ScheduleInstance> existing,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final out = <NewInstance>[];

    // 冲突来源：手工块 + 其他模板的实例
    final manual = existing.where((e) => e.templateId == null).toList();
    final otherTemplate = existing
        .where(
          (e) => e.templateId != null && e.status != BlockStatus.skipped,
        )
        .toList();

    for (final t in templates) {
      if (!t.enabled) continue;
      // 生成该模板在窗口内的日期集合：
      // - rrule 为空：单次/时间段（靠 startDate/endDate，v4.8）
      // - rrule 非空：按规则展开；若设了 startDate/endDate 再做范围过滤
      final List<int> dates;
      if (t.rrule == null || t.rrule!.isEmpty) {
        final s = t.startDate;
        if (s == null) continue; // 无日期信息的老"不重复"模板：无法定位，跳过
        final e = t.endDate ?? s;
        // 与窗口求交集后再遍历（跨年时间段也不会白循环）
        final winStartDay = DateDay.of(rangeStart);
        final winEndDay = DateDay.of(rangeEnd);
        var d = s > winStartDay ? s : winStartDay;
        final to = e < winEndDay ? e : winEndDay;
        dates = <int>[];
        while (d <= to) {
          dates.add(d);
          d = DateDay.addDays(d, 1);
        }
      } else {
        // 模板起始日最早回看 30 天，避免"模板刚建，start 就在未来"漏生成
        final back = rangeStart.subtract(const Duration(days: 30));
        dates = RruleService.expand(
          rrule: t.rrule!,
          start: back,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          exdatesCsv: t.exdates,
        );
        if (t.startDate != null) {
          dates.removeWhere((d) => d < t.startDate!);
        }
        if (t.endDate != null) {
          dates.removeWhere((d) => d > t.endDate!);
        }
      }
      // 本模板自己的既有实例（含 detach：用户改过时间的实例代表该日
      // 已有此模板的安排，再生成会冒出原时段副本）不算缺失（幂等重生成）
      final ownExisting = existing
          .where((e) => e.templateId == t.id)
          .map((e) => e.dateDay)
          .toSet();

      for (final dateDay in dates) {
        if (ownExisting.contains(dateDay)) continue;
        final candidate = NewInstance(
          templateId: t.id,
          dateDay: dateDay,
          startMinutes: t.startMinutes,
          durationMinutes: t.durationMinutes,
          title: t.title,
          description: t.description,
          colorIndex: t.colorIndex,
          remindMinutesBefore: t.remindMinutesBefore,
        );
        if (_conflicts(candidate, manual) ||
            _conflicts(candidate, otherTemplate)) {
          continue;
        }
        out.add(candidate);
      }
    }
    out.sort((a, b) {
      final c = a.dateDay.compareTo(b.dateDay);
      return c != 0 ? c : a.startMinutes.compareTo(b.startMinutes);
    });
    return out;
  }

  static bool _conflicts(NewInstance candidate, List<ScheduleInstance> blocks) {
    for (final b in blocks) {
      if (b.dateDay != candidate.dateDay) continue;
      final bEnd = b.startMinutes + b.durationMinutes;
      final cEnd = candidate.startMinutes + candidate.durationMinutes;
      if (candidate.startMinutes < bEnd && b.startMinutes < cEnd) return true;
    }
    return false;
  }

  /// 模板更新后，该模板"未来且未 detach 且未开始"的实例应被删除重生成
  ///（detach 实例保留）。
  static bool shouldDropInstance(ScheduleInstance e, int todayDay) {
    return e.templateId != null &&
        !e.detached &&
        e.status == BlockStatus.pending &&
        e.dateDay >= todayDay;
  }
}

/// 待插入实例（无 id）
class NewInstance {
  final int templateId;
  final int dateDay;
  final int startMinutes;
  final int durationMinutes;
  final String title;
  final String description;
  final int colorIndex;
  final int remindMinutesBefore;

  const NewInstance({
    required this.templateId,
    required this.dateDay,
    required this.startMinutes,
    required this.durationMinutes,
    required this.title,
    required this.description,
    required this.colorIndex,
    required this.remindMinutesBefore,
  });
}
