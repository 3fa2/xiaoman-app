import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/schedule.dart';
import '../../domain/services/rrule_service.dart';
import '../shared/widgets.dart';

/// 日程 · 编辑块：标题/起止时间/时长/提醒提前量/分离语义。
/// 来自模板的实例编辑后 detached=true（不再受模板更新影响）。
class ScheduleEditScreen extends ConsumerStatefulWidget {
  const ScheduleEditScreen({
    super.key,
    required this.instanceId,
    this.templateId,
    this.dateDay,
  });

  final int? instanceId;
  final int? templateId; // 从模板创建
  final int? dateDay;

  @override
  ConsumerState<ScheduleEditScreen> createState() =>
      _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends ConsumerState<ScheduleEditScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  int? _templateId;
  int _dateDay = _today();
  int _start = 9 * 60;
  int _duration = 60;
  int _colorIndex = 0;
  int _remindBefore = 0;
  bool _detached = false;
  bool _loaded = false;

  static int _today() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(scheduleRepoProvider);
    if (widget.instanceId != null) {
      final inst = await repo.getInstance(widget.instanceId!);
      if (inst != null) {
        _templateId = inst.templateId;
        _dateDay = inst.dateDay;
        _start = inst.startMinutes;
        _duration = inst.durationMinutes;
        _title.text = inst.title;
        _description.text = inst.description;
        _colorIndex = inst.colorIndex;
        _detached = inst.detached;
        // 从 remindAt 反推提前量回填：否则只改标题点保存也会把提醒清掉
        final remindAt = inst.remindAt;
        if (remindAt != null) {
          final day = DateDay.toDateTime(inst.dateDay);
          final blockStart = DateTime(day.year, day.month, day.day)
              .add(Duration(minutes: inst.startMinutes));
          final before = blockStart.difference(remindAt).inMinutes;
          _remindBefore = before > 0 ? before : 0;
        } else {
          _remindBefore = 0;
        }
      }
    } else if (widget.templateId != null) {
      final t = await repo.getTemplate(widget.templateId!);
      if (t != null) {
        _title.text = t.title;
        _description.text = t.description;
        _colorIndex = t.colorIndex;
        _start = t.startMinutes;
        _duration = t.durationMinutes;
        _remindBefore = t.remindMinutesBefore;
      }
    } else {
      _dateDay = widget.dateDay ?? _today();
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final repo = ref.read(scheduleRepoProvider);
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先写个标题')),
      );
      return;
    }
    await repo.saveInstance(
      id: widget.instanceId,
      templateId: _templateId,
      dateDay: _dateDay,
      startMinutes: _start,
      durationMinutes: _duration,
      title: title,
      description: _description.text.trim(),
      colorIndex: _colorIndex,
      // detach 语义：来自模板的实例被手动改动后分离
      detachOnEdit: widget.instanceId != null,
      remindMinutesBefore: _remindBefore,
    );
    if (mounted) {
      // 提醒重排（失败会在日程页警告条显示）
      ref.read(reminderWarningsProvider.notifier).syncNow();
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (widget.instanceId == null) return;
    final ok = await showConfirmSheet(
      context,
      title: '删除这个时间块？',
      message: '重复日程的这一天会记为例外，模板其他日期不受影响',
    );
    if (!ok) return;
    final repo = ref.read(scheduleRepoProvider);
    final inst = await repo.getInstance(widget.instanceId!);
    if (inst != null && inst.templateId != null) {
      // 模板实例走 EXDATE 语义：物理删除后 regenerate 会在下次启动把它重新生成
      final tpl = await repo.getTemplate(inst.templateId!);
      if (tpl != null) {
        await repo.skipTemplateOccurrence(template: tpl, dateDay: inst.dateDay);
      } else {
        await repo.deleteInstance(inst.id);
      }
    } else if (inst != null) {
      await repo.deleteInstance(inst.id);
    }
    if (mounted) {
      ref.read(reminderWarningsProvider.notifier).syncNow();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(),
        body: const SkeletonList(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.instanceId == null ? '新建时间块' : '编辑时间块',
        ),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          TextField(
            controller: _title,
            style: AppType.headline.copyWith(color: p.onSurface),
            decoration: const InputDecoration(labelText: '标题'),
          ),
          const SizedBox(height: AppSpacing.withinBlock),
          TextField(
            controller: _description,
            style: AppType.body.copyWith(color: p.onSurface),
            decoration: const InputDecoration(labelText: '备注'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.block),
          _TimeRow(
            start: _start,
            duration: _duration,
            onChanged: (start, dur) =>
                setState(() { _start = start; _duration = dur; }),
          ),
          const SizedBox(height: AppSpacing.withinBlock),
          _DatePickerRow(
            dateDay: _dateDay,
            onChanged: (d) => setState(() => _dateDay = d),
          ),
          const SizedBox(height: AppSpacing.withinBlock),
          _RemindRow(
            minutes: _remindBefore,
            onChanged: (m) => setState(() => _remindBefore = m),
          ),
          const SizedBox(height: AppSpacing.withinBlock),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              Text('颜色', style: AppType.label.copyWith(color: p.onSurfaceVariant)),
              for (var i = 0; i < SchedulePalette.lightColors.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SchedulePalette.of(i, dark: dark),
                      border: _colorIndex == i
                          ? Border.all(color: p.primary, width: 2)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          if (_templateId != null && !_detached) ...[
            const SizedBox(height: AppSpacing.withinBlock),
            Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsRegular.linkBreak,
                  size: 16,
                  color: p.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    '保存后此块与模板分离，模板更新不再影响它',
                    style: AppType.caption.copyWith(
                      color: p.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.instanceId != null) ...[
            const SizedBox(height: AppSpacing.block),
            OutlinedButton.icon(
              onPressed: _delete,
              icon: PhosphorIcon(
                PhosphorIconsRegular.trash,
                color: p.error,
                size: 18,
              ),
              label: Text(
                '删除',
                style: AppType.label.copyWith(color: p.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.start,
    required this.duration,
    required this.onChanged,
  });

  final int start;
  final int duration;
  final void Function(int start, int duration) onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        border: Border.all(color: p.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '时间',
            style: AppType.label.copyWith(color: p.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: start ~/ 60, minute: start % 60,
                      ),
                    );
                    if (picked != null) {
                      onChanged(picked.hour * 60 + picked.minute, duration);
                    }
                  },
                  child: Text(formatMinutes(start)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                child: Text('起，'),
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showSliderSheet(context, duration);
                    if (picked != null) onChanged(start, picked);
                  },
                  child: Text('$duration 分钟'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<int?> showSliderSheet(BuildContext context, int initial) {
    var value = initial.toDouble();
    return showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '时长 ${value.round()} 分钟',
                style: AppType.headline.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface,
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
                onPressed: () => Navigator.pop(ctx, value.round()),
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({required this.dateDay, required this.onChanged});

  final int dateDay;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.rLg),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateDay.toDateTime(dateDay),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked.year * 10000 + picked.month * 100 + picked.day);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadii.rLg),
          border: Border.all(color: p.outlineVariant),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.calendarBlank,
              size: 18,
              color: p.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              '${dateDay ~/ 10000}年${(dateDay ~/ 100) % 100}月${dateDay % 100}日',
              style: AppType.body.copyWith(color: p.onSurface),
            ),
            const Spacer(),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: p.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RemindRow extends StatelessWidget {
  const _RemindRow({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  static const options = <(String, int)>[
    ('不提醒', 0),
    ('提前 5 分钟', 5),
    ('提前 15 分钟', 15),
    ('提前 30 分钟', 30),
    ('提前 1 天', 1440),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      children: [
        for (final (label, value) in options)
          ChoiceChip(
            label: Text(label),
            selected: minutes == value,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}
