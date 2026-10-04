import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/todo.dart';
import '../shared/widgets.dart';

/// 打开新建/编辑待办弹窗。v5.0：独立待办，桌面小组件数据源。
Future<void> showTodoAddSheet(
  BuildContext context, {
  Todo? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _TodoAddSheet(existing: existing),
  );
}

class _TodoAddSheet extends ConsumerStatefulWidget {
  const _TodoAddSheet({this.existing});
  final Todo? existing;

  @override
  ConsumerState<_TodoAddSheet> createState() => _TodoAddSheetState();
}

class _TodoAddSheetState extends ConsumerState<_TodoAddSheet> {
  late final TextEditingController _titleCtrl;
  int? _dueDay; // yyyymmdd，null=无期限
  int? _remindBefore; // 提前提醒分钟数，null=到点即提醒

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _dueDay = widget.existing?.dueDay;
    _remindBefore = widget.existing?.remindBefore;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  static int _today() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  static int _dayOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static int _addDay(int day, int delta) {
    final d = DateTime(day ~/ 10000, (day ~/ 100) % 100, day % 100)
        .add(Duration(days: delta));
    return d.year * 10000 + d.month * 100 + d.day;
  }

  String _dueLabel(int day) {
    final d = DateTime(day ~/ 10000, (day ~/ 100) % 100, day % 100);
    return '${d.month}月${d.day}日';
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final initial = _dueDay == null
        ? now
        : DateTime(_dueDay! ~/ 10000, (_dueDay! ~/ 100) % 100, _dueDay! % 100);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDay = _dayOf(picked));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final repo = ref.read(todoRepoProvider);
    final existing = widget.existing;
    if (existing == null) {
      await repo.add(title: title, dueDay: _dueDay, remindBefore: _remindBefore);
    } else {
      await repo.update(
        id: existing.id,
        title: title,
        dueDay: _dueDay,
        remindBefore: _remindBefore,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final today = _today();
    final tomorrow = _addDay(today, 1);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.s24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: '要做什么？',
              counterText: '',
              filled: true,
              fillColor: p.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.rMd),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text('截止', style: AppType.caption.copyWith(color: p.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              _ChoiceChip(
                label: '无期限',
                selected: _dueDay == null,
                onTap: () => setState(() => _dueDay = null),
              ),
              _ChoiceChip(
                label: '今天',
                selected: _dueDay == today,
                onTap: () => setState(() => _dueDay = today),
              ),
              _ChoiceChip(
                label: '明天',
                selected: _dueDay == tomorrow,
                onTap: () => setState(() => _dueDay = tomorrow),
              ),
              if (_dueDay != null &&
                  _dueDay != today &&
                  _dueDay != tomorrow)
                _ChoiceChip(
                  label: _dueLabel(_dueDay!),
                  selected: true,
                  onTap: _pickDue,
                ),
              _ChoiceChip(
                label: '选日期',
                selected: false,
                onTap: _pickDue,
                icon: PhosphorIconsRegular.calendarBlank,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text('提醒', style: AppType.caption.copyWith(color: p.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final (label, min) in const <(String, int?)>[
                ('到点', null),
                ('提前10分', 10),
                ('提前30分', 30),
                ('提前60分', 60),
              ])
                _ChoiceChip(
                  label: label,
                  selected: _remindBefore == min,
                  onTap: () => setState(() => _remindBefore = min),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          FilledButton(
            onPressed: _save,
            child: Text(_editing ? '保存' : '添加'),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionDuration.fast,
        curve: MotionCurve.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.rSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              PhosphorIcon(
                icon!,
                size: 14,
                color: selected ? p.onPrimary : p.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: AppType.label.copyWith(
                color: selected ? p.onPrimary : p.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}