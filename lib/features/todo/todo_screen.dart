import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/todo.dart';
import '../shared/widgets.dart';
import 'todo_add_sheet.dart';

/// 待办主页（v5.0.2 · 效果图美化）：筛选条 + 未完成（装饰条卡）+ 已完成折叠。
/// 配色沿用雾蓝体系；形态对齐参考截图：左侧竖条、圆形勾选框、大圆角卡片。
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

enum _Filter { all, active, overdue, today, week, done }

enum _SortBy { created, dueDay }

class _TodoScreenState extends ConsumerState<TodoScreen> {
  _Filter _filter = _Filter.all;
  _SortBy _sortBy = _SortBy.created;
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
        title: StreamBuilder<List<Todo>>(
          stream: stream,
          builder: (context, snap) {
            final total = (snap.data ?? const <Todo>[]).length;
            return Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '待办'),
                  if (total > 0) ...[
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: '共 $total 条',
                      style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
              style: AppType.title.copyWith(color: p.onSurface),
            );
          },
        ),
        actions: [
          PopupMenuButton<_SortBy>(
            icon: PhosphorIcon(
              PhosphorIconsRegular.dotsThreeVertical,
              size: 22,
              color: p.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.rMd),
            ),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: _SortBy.created,
                child: Row(
                  children: [
                    PhosphorIcon(
                      _sortBy == _SortBy.created
                          ? PhosphorIconsFill.check
                          : PhosphorIconsRegular.clockClockwise,
                      size: 18,
                      color: _sortBy == _SortBy.created ? p.primary : p.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Text('按添加顺序', style: AppType.body.copyWith(color: p.onSurface)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortBy.dueDay,
                child: Row(
                  children: [
                    PhosphorIcon(
                      _sortBy == _SortBy.dueDay
                          ? PhosphorIconsFill.check
                          : PhosphorIconsRegular.calendarBlank,
                      size: 18,
                      color: _sortBy == _SortBy.dueDay ? p.primary : p.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Text('按截止日', style: AppType.body.copyWith(color: p.onSurface)),
                  ],
                ),
              ),
            ],
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
          var active = all.where((t) => !t.done && matches(t)).toList();
          var done = all.where((t) => t.done && matches(t)).toList();
          // 排序
          int byCreated(Todo a, Todo b) => b.createdAt.compareTo(a.createdAt);
          int byDue(Todo a, Todo b) {
            final ad = a.dueDay;
            final bd = b.dueDay;
            if (ad == null && bd == null) return byCreated(a, b);
            if (ad == null) return 1; // 无截止日排后
            if (bd == null) return -1;
            return ad.compareTo(bd);
          }
          active.sort(_sortBy == _SortBy.dueDay ? byDue : byCreated);
          done.sort(byCreated);
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page, 0, AppSpacing.page, AppSpacing.s8,
                      ),
                      child: _TodoRow(todo: active[i]),
                    ),
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
                  for (final t in done)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page, AppSpacing.s8, AppSpacing.page, 0,
                      ),
                      child: _TodoRow(todo: t),
                    ),
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

  static String _fmtDay(int day) {
    final d = DateTime(day ~/ 10000, (day ~/ 100) % 100, day % 100);
    final n = DateTime.now();
    final diff = DateTime(n.year, n.month, n.day).difference(d).inDays;
    if (diff == -1) return '明天';
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${d.month}月${d.day}日';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    final today = _today();
    final overdue = !todo.done && todo.dueDay != null && todo.dueDay! < today;
    final dueToday = todo.dueDay == today;
    final dueText = todo.dueDay == null
        ? null
        : (dueToday ? '今天' : _fmtDay(todo.dueDay!));
    final accent = todo.done ? p.outline : p.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        onLongPress: () => showTodoAddSheet(context, existing: todo),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPad, vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              // 左侧装饰竖条
              Container(
                width: 3,
                height: 32,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadii.rSm),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              // 标题 + 截止小字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: AppType.body.copyWith(
                        color: todo.done ? p.onSurfaceVariant : p.onSurface,
                        decoration: todo.done ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dueText != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        dueText,
                        style: AppType.caption.copyWith(
                          color: overdue
                              ? p.error
                              : (todo.done ? p.onSurfaceVariant : p.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              // 圆形勾选框
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
                      color: todo.done ? p.primary : p.outline,
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
            ],
          ),
        ),
      ),
    );
  }
}