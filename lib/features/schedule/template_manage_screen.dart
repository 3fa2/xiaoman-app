import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/schedule.dart';
import '../../domain/services/rrule_service.dart';
import '../shared/widgets.dart';

/// 日程 · 模板管理：重复规则编辑（周几/每月第 N 个周几/每月某日/每年）+ 启用开关。
class TemplateManageScreen extends ConsumerWidget {
  const TemplateManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('重复模板')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editTemplate(context, ref, null),
        child: PhosphorIcon(
          PhosphorIconsRegular.plus,
          color: p.onPrimary,
          weight: 1.5,
        ),
      ),
      body: StreamBuilder<List<ScheduleTemplate>>(
        stream: ref.watch(scheduleRepoProvider).watchTemplates(),
        builder: (context, snap) {
          final list = snap.data ?? const <ScheduleTemplate>[];
          if (list.isEmpty) {
            return EmptyState(
              icon: PhosphorIconsRegular.repeat,
              title: '还没有模板',
              hint: '比如「工作日 09:00 站会」建一次，以后自动生成',
              actionLabel: '新建模板',
              onAction: () => _editTemplate(context, ref, null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              final color = SchedulePalette.of(t.colorIndex, dark: dark);
              return StaggeredEntrance(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.rLg),
                      onTap: () => _editTemplate(context, ref, t),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.cardPad),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.rSm),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: AppType.headline
                                        .copyWith(color: p.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${describeRrule(t.rrule)} · '
                                    '${formatMinutes(t.startMinutes)} 起 · '
                                    '${t.durationMinutes} 分钟',
                                    style: AppType.caption.copyWith(
                                      color: p.onSurfaceVariant,
                                    ),
                                  ),
                                  if (t.exdates.isNotEmpty)
                                    Text(
                                      '${t.exdates.split(',').length} 个例外日',
                                      style: AppType.caption.copyWith(
                                        color: p.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Switch(
                              value: t.enabled,
                              onChanged: (v) {
                                final updated = ScheduleTemplate(
                                  id: t.id, title: t.title,
                                  description: t.description,
                                  colorIndex: t.colorIndex, rrule: t.rrule,
                                  exdates: t.exdates,
                                  startMinutes: t.startMinutes,
                                  durationMinutes: t.durationMinutes,
                                  remindMinutesBefore: t.remindMinutesBefore,
                                  enabled: v,
                                  createdAt: t.createdAt,
                                  updatedAt: t.updatedAt,
                                );
                                ref
                                    .read(scheduleRepoProvider)
                                    .saveTemplate(updated, isNew: false)
                                    .then(
                                      (_) => ref
                                          .read(reminderWarningsProvider
                                              .notifier)
                                          .syncNow(),
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editTemplate(
    BuildContext context,
    WidgetRef ref,
    ScheduleTemplate? t,
  ) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).colorScheme;
    final titleCtrl = TextEditingController(text: t?.title ?? '');
    final descCtrl = TextEditingController(text: t?.description ?? '');
    var colorIndex = t?.colorIndex ?? 0;
    var start = t?.startMinutes ?? 9 * 60;
    var duration = t?.durationMinutes ?? 60;
    var remind = t?.remindMinutesBefore ?? 0;
  var freq = RepeatFreq.none;
  var weekdays = <int>[1, 2, 3, 4, 5];
  var nthWeek = 1;
  var monthDay = 1;
  var interval = 1;

  // 回填规则（已有模板）
  if (t?.rrule != null && t!.rrule!.isNotEmpty) {
    final parts = RruleService.parse(t.rrule!);
    interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    freq = switch (parts['FREQ']) {
      'WEEKLY' => RepeatFreq.weekly,
      'MONTHLY' => (parts['BYSETPOS'] ?? '').isNotEmpty
          ? RepeatFreq.monthlyByNthWeekday
          : RepeatFreq.monthlyByDate,
      'YEARLY' => RepeatFreq.yearly,
      'DAILY' => interval > 1
          ? RepeatFreq.dailyInterval
          : RepeatFreq.daily,
      _ => RepeatFreq.daily,
    };
      final byDay = parts['BYDAY'] ?? '';
      if (byDay.isNotEmpty) {
        const map = {
          'MO': 0, 'TU': 1, 'WE': 2, 'TH': 3, 'FR': 4, 'SA': 5, 'SU': 6,
        };
        weekdays =
            byDay.split(',').map((d) => map[d.trim()] ?? 1).toList();
      }
      final pos = int.tryParse(parts['BYSETPOS'] ?? '');
      if (pos != null) nthWeek = pos;
      final md = int.tryParse(parts['BYMONTHDAY'] ?? '');
      if (md != null) monthDay = md;
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page, 0, AppSpacing.page,
            AppSpacing.s24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t == null ? '新建模板' : '编辑模板',
                  style: AppType.headline.copyWith(color: p.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '标题'),
                  style: AppType.body.copyWith(color: p.onSurface),
                ),
                const SizedBox(height: AppSpacing.withinBlock),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: '备注'),
                  style: AppType.body.copyWith(color: p.onSurface),
                ),
                const SizedBox(height: AppSpacing.withinBlock),
                Wrap(
                  spacing: AppSpacing.s8,
                  children: [
                    for (var i = 0; i < 4; i++)
                      GestureDetector(
                        onTap: () => setSheet(() => colorIndex = i),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SchedulePalette.of(i, dark: dark),
                            border: colorIndex == i
                                ? Border.all(color: p.primary, width: 2)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.withinBlock),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay(
                              hour: start ~/ 60, minute: start % 60,
                            ),
                          );
                          if (picked != null) {
                            setSheet(
                              () => start = picked.hour * 60 + picked.minute,
                            );
                          }
                        },
                        child: Text('开始 ${formatMinutes(start)}'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final v = await _pickDuration(ctx, duration);
                          if (v != null) setSheet(() => duration = v);
                        },
                        child: Text('$duration 分钟'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.withinBlock),
                DropdownButtonFormField<RepeatFreq>(
                  initialValue: freq,
                  decoration: const InputDecoration(labelText: '重复'),
                  items: const [
                    DropdownMenuItem(
                      value: RepeatFreq.none, child: Text('不重复'),
                    ),
                    DropdownMenuItem(
                      value: RepeatFreq.daily, child: Text('每天'),
                    ),
                    DropdownMenuItem(
                      value: RepeatFreq.dailyInterval,
                      child: Text('每隔几天'),
                    ),
                    DropdownMenuItem(
                      value: RepeatFreq.weekly, child: Text('每周（选周几）'),
                    ),
                    DropdownMenuItem(
                      value: RepeatFreq.monthlyByNthWeekday,
                      child: Text('每月第 N 个周几'),
                    ),
                    DropdownMenuItem(
                      value: RepeatFreq.monthlyByDate,
                      child: Text('每月某日'),
                    ),
                    DropdownMenuItem(
                      value: RepeatFreq.yearly, child: Text('每年'),
                    ),
                  ],
                  onChanged: (v) => setSheet(() => freq = v ?? RepeatFreq.none),
                ),
                if (freq == RepeatFreq.dailyInterval)
                  DropdownButtonFormField<int>(
                    initialValue: interval < 2 ? 3 : interval,
                    decoration: const InputDecoration(labelText: '间隔天数'),
                    items: [
                      for (var n = 2; n <= 30; n++)
                        DropdownMenuItem(value: n, child: Text('每 $n 天')),
                    ],
                    onChanged: (v) => setSheet(() => interval = v ?? 3),
                  ),
                if (freq == RepeatFreq.weekly ||
                    freq == RepeatFreq.monthlyByNthWeekday) ...[
                  const SizedBox(height: AppSpacing.withinBlock),
                  Wrap(
                    spacing: AppSpacing.s4,
                    children: [
                      for (var i = 0; i < 7; i++)
                        FilterChip(
                          label: Text('周${'一二三四五六日'[i]}'),
                          selected: weekdays.contains(i),
                          onSelected: (sel) => setSheet(() {
                            weekdays = [...weekdays];
                            if (sel) {
                              weekdays.add(i);
                            } else {
                              weekdays.remove(i);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
                if (freq == RepeatFreq.monthlyByNthWeekday)
                  DropdownButtonFormField<int>(
                    initialValue: nthWeek,
                    decoration: const InputDecoration(labelText: '第几个'),
                    items: [
                      for (var n = 1; n <= 5; n++)
                        DropdownMenuItem(value: n, child: Text('第 $n 个')),
                    ],
                    onChanged: (v) => setSheet(() => nthWeek = v ?? 1),
                  ),
                if (freq == RepeatFreq.monthlyByDate)
                  DropdownButtonFormField<int>(
                    initialValue: monthDay,
                    decoration: const InputDecoration(labelText: '每月几号'),
                    items: [
                      for (var n = 1; n <= 31; n++)
                        DropdownMenuItem(value: n, child: Text('$n 号')),
                    ],
                    onChanged: (v) => setSheet(() => monthDay = v ?? 1),
                  ),
                const SizedBox(height: AppSpacing.withinBlock),
                Wrap(
                  spacing: AppSpacing.s8,
                  children: [
                    for (final (label, value) in const <(String, int)>[
                      ('不提醒', 0), ('提前 5 分', 5),
                      ('提前 15 分', 15), ('提前 30 分', 30),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: remind == value,
                        onSelected: (_) => setSheet(() => remind = value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;

    final rrule = RruleService.build(
      freq: freq,
      interval: freq == RepeatFreq.dailyInterval
          ? (interval < 2 ? 3 : interval)
          : 1,
      weekdays: weekdays,
      nthWeek: nthWeek,
      monthDay: monthDay,
    );
    final now = DateTime.now();
    final template = ScheduleTemplate(
      id: t?.id ?? 0,
      title: title,
      description: descCtrl.text.trim(),
      colorIndex: colorIndex,
      rrule: rrule,
      exdates: t?.exdates ?? '',
      startMinutes: start,
      durationMinutes: duration,
      remindMinutesBefore: remind,
      enabled: t?.enabled ?? true,
      createdAt: t?.createdAt ?? now,
      updatedAt: now,
    );
    await ref
        .read(scheduleRepoProvider)
        .saveTemplate(template, isNew: t == null);
    if (context.mounted) {
      ref.read(reminderWarningsProvider.notifier).syncNow();
    }
  }

  Future<int?> _pickDuration(BuildContext ctx, int initial) async {
    var value = initial.toDouble();
    return showModalBottomSheet<int>(
      context: ctx,
      useSafeArea: true,
      builder: (bctx) => StatefulBuilder(
        builder: (bctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '时长 ${value.round()} 分钟',
                style: AppType.headline.copyWith(
                  color: Theme.of(bctx).colorScheme.onSurface,
                ),
              ),
              Slider(
                value: value,
                min: 5,
                max: 480,
                divisions: 95,
                onChanged: (v) => setSheet(() => value = v),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(bctx, value.round()),
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
