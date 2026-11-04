import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/schedule.dart';
import '../shared/widgets.dart';
import 'schedule_today_screen.dart' show TimeLineView;

/// 日程 · 单日时间轴（v5.5.0 重做）：任意一天（含过去）的 0-24h 时间轴，
/// 与「今天」页同一套交互：块可点编辑、长按拖动改时间（15 分钟吸附）。
/// AppBar ‹ › 切前后一天（replace 保持栈不增长）。
class ScheduleDayScreen extends ConsumerStatefulWidget {
  const ScheduleDayScreen({super.key, required this.dateDay});

  final int dateDay;

  @override
  ConsumerState<ScheduleDayScreen> createState() => _ScheduleDayScreenState();
}

class _ScheduleDayScreenState extends ConsumerState<ScheduleDayScreen> {
  /// 拖拽改时间：保留时长与提醒提前量，模板实例自动分离（与今天页同一套）
  Future<void> _moveBlock(ScheduleInstance b, int newStart) async {
    final repo = ref.read(scheduleRepoProvider);
    int? remindBefore;
    final remindAt = b.remindAt;
    if (remindAt != null) {
      final day = DateDay.toDateTime(b.dateDay);
      final blockStart = DateTime(day.year, day.month, day.day)
          .add(Duration(minutes: b.startMinutes));
      remindBefore = blockStart.difference(remindAt).inMinutes;
    }
    await repo.saveInstance(
      id: b.id,
      templateId: b.templateId,
      dateDay: b.dateDay,
      startMinutes: newStart,
      durationMinutes: b.durationMinutes,
      title: b.title,
      description: b.description,
      colorIndex: b.colorIndex,
      detachOnEdit: true,
      remindMinutesBefore: remindBefore != null && remindBefore > 0
          ? remindBefore
          : null,
    );
    ref.read(reminderWarningsProvider.notifier).syncNow();
  }

  void _jump(int delta) {
    final next = DateDay.addDays(widget.dateDay, delta);
    context.pushReplacement('/schedule/day/$next');
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final d = DateDay.toDateTime(widget.dateDay);
    final now = DateTime.now();
    final isToday = widget.dateDay ==
        now.year * 10000 + now.month * 100 + now.day;
    final instances =
        ref.watch(scheduleRepoProvider).watchDay(widget.dateDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isToday
              ? '今天'
              : DateFormat('M月d日 EEEE', 'zh_CN').format(d),
        ),
        actions: [
          IconButton(
            onPressed: () => _jump(-1),
            tooltip: '前一天',
            icon: PhosphorIcon(
              PhosphorIconsRegular.caretLeft,
              color: p.onSurfaceVariant,
            ),
          ),
          IconButton(
            onPressed: () => _jump(1),
            tooltip: '后一天',
            icon: PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      floatingActionButton: AppFab(
        icon: PhosphorIconsRegular.calendarPlus,
        tooltip: '新建日程',
        onPressed: () => context.openScheduleEdit(dateDay: widget.dateDay),
      ),
      body: StreamBuilder<List<ScheduleInstance>>(
        stream: instances,
        builder: (context, snap) {
          final list = snap.data ?? const <ScheduleInstance>[];
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: SkeletonList(),
            );
          }
          if (list.isEmpty) {
            return EmptyState(
              icon: PhosphorIconsRegular.calendarBlank,
              title: '这天没有安排',
              hint: isToday ? '加一个时间块，或建个每天重复的模板' : '点右下角补一个',
              actionLabel: isToday ? '管理重复模板' : null,
              onAction: isToday ? () => context.openTemplates() : null,
            );
          }
          return TimeLineView(
            dateDay: widget.dateDay,
            blocks: list,
            nowMinutes: now.hour * 60 + now.minute,
            onBlockTap: (b) => context.openScheduleEdit(instanceId: b.id),
            onBlockMove: _moveBlock,
          );
        },
      ),
    );
  }
}
