import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/schedule.dart';
import '../shared/widgets.dart';

/// 日程 · 未来 N 天：横向日期条 + 每日块列表（滚动窗口 14 天）。
/// 也用于从日期条点进来的单日视图。
class ScheduleDayScreen extends ConsumerWidget {
  const ScheduleDayScreen({super.key, required this.dateDay});

  final int dateDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final start = DateDay.toDateTime(dateDay);
    final end = start.add(const Duration(days: 14));
    final startDay = start.year * 10000 + start.month * 100 + start.day;
    final endDay = end.year * 10000 + end.month * 100 + end.day;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('M月d日起 · 14 天', 'zh_CN').format(start),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.openScheduleEdit(dateDay: dateDay),
        child: PhosphorIcon(
          PhosphorIconsRegular.plus,
          color: p.onPrimary,
          weight: 1.5,
        ),
      ),
      body: StreamBuilder<List<ScheduleInstance>>(
        stream: ref.watch(scheduleRepoProvider).watchRange(startDay, endDay),
        builder: (context, snap) {
          final all = snap.data ?? const <ScheduleInstance>[];
          final byDay = <int, List<ScheduleInstance>>{};
          for (final b in all) {
            byDay.putIfAbsent(b.dateDay, () => []).add(b);
          }
          if (all.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsRegular.calendarBlank,
              title: '这两周没有安排',
              hint: '点右下角加一个时间块',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
            ),
            itemCount: 14,
            itemBuilder: (context, i) {
              final day = DateDay.addDays(dateDay, i);
              final blocks = byDay[day] ?? const <ScheduleInstance>[];
              final d = DateDay.toDateTime(day);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.s16, bottom: AppSpacing.s8,
                    ),
                    child: Text(
                      DateFormat('M月d日 EEEE', 'zh_CN').format(d),
                      style: AppType.headline.copyWith(color: p.onSurface),
                    ),
                  ),
                  if (blocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: Text(
                        '空',
                        style: AppType.caption.copyWith(
                          color: p.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...blocks.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: _DayBlockRow(block: b),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DayBlockRow extends ConsumerWidget {
  const _DayBlockRow({required this.block});

  final ScheduleInstance block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final color = SchedulePalette.of(block.colorIndex, dark: dark);
    final done = block.status == BlockStatus.done;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        onTap: () => context.openScheduleEdit(instanceId: block.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPad),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.rSm),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              SizedBox(
                width: 96,
                child: Text(
                  '${_hm(block.startMinutes)}\n${_hm(block.endMinutes)}',
                  style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: AppType.headline.copyWith(
                        color: done ? p.onSurfaceVariant : p.onSurface,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (block.description.isNotEmpty)
                      Text(
                        block.description,
                        style: AppType.caption.copyWith(
                          color: p.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final next = done ? BlockStatus.pending : BlockStatus.done;
                  await ref
                      .read(scheduleRepoProvider)
                      .setStatus(id: block.id, status: next);
                },
                icon: PhosphorIcon(
                  done
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.circle,
                  size: 22,
                  color: done ? p.primary : p.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
