import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/todo.dart';
import '../shared/widgets.dart';
import 'todo_add_sheet.dart';

/// 待办主页：筛选（全部/进行中/已过期/今天/最近7）+ 未完成/已完成分区。
/// v5.0：独立待办（与笔记内清单无关），桌面小组件数据源。
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

enum _Filter { all, active, overdue, today, week, done }

class _TodoScreenState extends ConsumerState<TodoScreen> {
  _Filter _filter = _Filter.all;
  bool _doneExpanded = false;

  static int _today() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final stream = ref.watch(todoRepoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办'),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: '排序（待实现）',
            icon: PhosphorIcon(
              PhosphorIconsRegular.arrowsDownUp,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      floatingActionButton: AppFab(
        icon: PhosphorIconsRegular.plus,
        tooltip: '新建待办',
        onPressed: () => showTodoAddSheet(context),
      ),
      body: StreamBuilder<List<Todo>>(
        stream: stream,
        builder: (context, snap) {
          final all = snap.data ?? const <Todo>[];
          if (snap.connectionState == ConnectionState.waiting && all.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: SkeletonList(),
            );
          }
          if (all.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsRegular.listChecks,
              title: '还没有待办',
              hint: '点右下角加一个，或从桌面小组件直接记',
            );
          }
          final today = _today();
          final now = DateTime.now();
          final weekEndDt = DateTime(now.year, now.month, now.day)
              .add(const Duration(days: 7));
          final weekEndNum =
              weekEndDt.year * 10000 + weekEndDt.month * 100 + weekEndDt.day;
          bool matches(Todo t) => switch (_filter) {
                _Filter.all => true,
                _Filter.active => !t.done,
                _Filter.overdue =>
                  !t.done && t.dueDay != null && t.dueDay! < today,
                _Filter.today => t.dueDay == today,
                  _Filter.week =>
                    t.dueDay != null && t.dueDay! >= today && t.dueDay! <= weekEndNum,
                _Filter.done => t.done,
              };
          final active = all.where((t) => !t.done && matches(t)).toList();
          final done = all.where((t) => t.done && matches(t)).toList();
          final total = all.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              0, AppSpacing.s8, 0, AppSpacing.listBottom,
            ),
            children: [
              // 筛选条
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Row(
                  children: [
                    for (final (f, label) in const <(_Filter, String)>[
                      (_Filter.all, '全部'),
                      (_Filter.active, '进行中'),
                      (_Filter.overdue, '已过期'),
                      (_Filter.today, '今天'),
                      (_Filter.week, '最近 7'),
                      (_Filter.done, '已完成'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.s8),
                        child: _FilterChip(
                          label: '$label${f == _Filter.all ? ' $total' : ''}',
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              // 未完成列表
              if (active.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page, vertical: AppSpacing.s8,
                  ),
                  child: Text(
                    '没有未完成的事',
                    style: AppType.body.copyWith(color: p.onSurfaceVariant),
                  ),
                )
              else
                for (var i = 0; i < active.length; i++)
                  StaggeredEntrance(
                    index: i,
                    child: _TodoRow(todo: active[i]),
                  ),
              // 已完成分区
              if (done.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, AppSpacing.s8, AppSpacing.page, 0,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _doneExpanded = !_doneExpanded),
                    child: Row(
                      children: [
                        Text(
                          '已完成 · ${done.length}',
                          style: AppType.caption.copyWith(
                            color: p.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        PhosphorIcon(
                          _doneExpanded
                              ? PhosphorIconsRegular.caretUp
                              : PhosphorIconsRegular.caretDown,
                          size: 14,
                          color: p.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_doneExpanded)
                  for (final t in done) _TodoRow(todo: t),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionDuration.fast,
        curve: MotionCurve.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.rSm),
        ),
        child: Text(
          label,
          style: AppType.label.copyWith(
            color: selected ? p.onPrimary : p.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

class _TodoRow extends ConsumerWidget {
  const _TodoRow({required this.todo});
  final Todo todo;

  static int _today() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final overdue = !todo.done && todo.dueDay != null && todo.dueDay! < _today();
    final dueToday = todo.dueDay == _today();
    final dueText = todo.dueDay == null
        ? null
        : (dueToday
            ? '今天'
            : _fmtDay(todo.dueDay!));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, 0, AppSpacing.page, AppSpacing.s8,
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.rLg),
          onLongPress: () => _edit(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPad),
            child: Row(
              children: [
                // 勾选框
                PressableScale(
                  onTap: () => ref
                      .read(todoRepoProvider)
                      .toggle(id: todo.id, done: !todo.done),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: todo.done ? p.primary : Colors.transparent,
                      border: Border.all(
                        color: todo.done ? p.primary : p.onSurfaceVariant,
                        width: 1.5,
                      ),
                    ),
                    child: todo.done
                        ? PhosphorIcon(
                            PhosphorIconsFill.check,
                            size: 14,
                            color: p.onPrimary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: AppType.body.copyWith(
                          color: todo.done ? p.onSurfaceVariant : p.onSurface,
                          decoration: todo.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (dueText != null)
                        Text(
                          dueText,
                          style: AppType.caption.copyWith(
                            color: overdue
                                ? p.error
                                : (todo.done ? p.onSurfaceVariant : p.primary),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _edit(context, ref),
                  child: PhosphorIcon(
                    PhosphorIconsRegular.pencilSimple,
                    size: 16,
                    color: p.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _edit(BuildContext context, WidgetRef ref) {
    showTodoAddSheet(context, existing: todo);
  }

  static String _fmtDay(int day) {
    final d = DateTime(day ~/ 10000, (day ~/ 100) % 100, day % 100);
    final n = DateTime.now();
    final diff = DateTime(n.year, n.month, n.day).difference(d).inDays;
    if (diff == -1) return '明天';
    if (diff == 0) return '今天';
    return '${d.month}月${d.day}日';
  }
}