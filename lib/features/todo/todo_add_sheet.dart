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
  String? _repeat; // v5.3 循环：daily/weekly/monthly（null=不重复）

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _dueDay = widget.existing?.dueDay;
    _remindBefore = widget.existing?.remindBefore;
    _repeat = widget.existing?.repeat;
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

  /// 循环待办必须有截止日（滚动锚点）：选重复时自动补今天
  void _setRepeat(String? value) {
    setState(() {
      _repeat = value;
      if (value != null && _dueDay == null) _dueDay = _today();
    });
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
    // 循环待办必须有截止日（滚动锚点）；没选截止日就视为不重复
    final repeat = _dueDay == null ? null : _repeat;
    if (existing == null) {
      await repo.add(
        title: title,
        dueDay: _dueDay,
        remindBefore: _remindBefore,
        repeat: repeat,
      );
    } else {
      await repo.update(
        id: existing.id,
        title: title,
        dueDay: _dueDay,
        remindBefore: _remindBefore,
        repeat: repeat,
      );
    }
    // 新建当天到期的待办要能按时响铃：待办变化即重排提醒（与启动兜底同源）
    ref.read(reminderWarningsProvider.notifier).syncNow();
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
            onChanged: (_) => setState(() {}), // 保存按钮可用性跟随输入
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
                onTap: () => setState(() {
                  _dueDay = null;
                  // 无期限 = 循环没有滚动锚点，同步取消循环（否则保存时被静默丢弃）
                  _repeat = null;
                }),
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
          const SizedBox(height: AppSpacing.s16),
          Text('重复', style: AppType.caption.copyWith(color: p.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final (label, value) in const <(String, String?)>[
                ('不重复', null),
                ('每天', 'daily'),
                ('每周', 'weekly'),
                ('每月', 'monthly'),
              ])
                _ChoiceChip(
                  label: label,
                  selected: _repeat == value,
                  onTap: () => _setRepeat(value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          // 标题为空禁用保存（此前静默无反应，输入像是丢了）
          FilledButton(
            onPressed:
                _titleCtrl.text.trim().isEmpty ? null : _save,
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