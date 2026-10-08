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

enum _Filter { all, active, done }

enum _SortBy { created, dueDay }

class _TodoScreenState extends ConsumerState<TodoScreen> {
  _Filter _filter = _Filter.all;
  _SortBy _sortBy = _SortBy.created;
  bool _doneExpanded = false;

  static const _sortKey = 'todo_sort';

  @override
  void initState() {
    super.initState();
    _loadSort();
  }

  Future<void> _loadSort() async {
    final v = await ref.read(settingsRepoProvider).get(_sortKey);
    if (!mounted || v == null) return;
    setState(() {
      _sortBy =
          v == _SortBy.dueDay.name ? _SortBy.dueDay : _SortBy.created;
    });
  }

  Future<void> _setSort(_SortBy v) async {
    setState(() => _sortBy = v);
    await ref.read(settingsRepoProvider).set(_sortKey, v.name);
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
          PopupMenuButton<Object>(
            icon: PhosphorIcon(
              PhosphorIconsRegular.dotsThreeVertical,
              size: 22,
              color: p.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.rMd),
            ),
            onSelected: (v) async {
              if (v == 'clear_done') {
                final ok = await showConfirmSheet(
                  context,
                  title: '清空全部已完成？',
                  message: '所有已完成事项将被删除，找不回来',
                );
                if (!ok) return;
                final count = await ref.read(todoRepoProvider).clearDone();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已清空 $count 条已完成')),
                  );
                }
                return;
              }
              await _setSort(v as _SortBy);
            },
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
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear_done',
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.trash,
                      size: 18,
                      color: p.error,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Text('清空已完成', style: AppType.body.copyWith(color: p.error)),
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
          bool matches(Todo t) => switch (_filter) {
                _Filter.all => true,
                _Filter.active => !t.done,
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
          // 各筛选的准确计数：全部=含已完成总数；进行中/已完成独立计数
          final activeCount = all.where((t) => !t.done).length;
          final doneCount = all.where((t) => t.done).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              0, AppSpacing.s8, 0, AppSpacing.listBottom,
            ),
            children: [
              // 筛选条（v5.4.3：收敛为 3 档，每档显示准确计数）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Row(
                  children: [
                    _FilterChip(
                      label: '全部 $total',
                      selected: _filter == _Filter.all,
                      onTap: () => setState(() => _filter = _Filter.all),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _FilterChip(
                      label: '进行中 $activeCount',
                      selected: _filter == _Filter.active,
                      onTap: () => setState(() => _filter = _Filter.active),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _FilterChip(
                      label: '已完成 $doneCount',
                      selected: _filter == _Filter.done,
                      onTap: () => setState(() => _filter = _Filter.done),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              // 未完成列表（选「已完成」档时本来就该为空，不再显示提示）
              if (active.isEmpty && _filter != _Filter.done)
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
    final repeatText = switch (todo.repeat) {
      'daily' => '每天',
      'weekly' => '每周',
      'monthly' => '每月',
      _ => null,
    };
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
                    if (dueText != null || repeatText != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Row(
                        children: [
                          if (dueText != null)
                            Text(
                              dueText,
                              style: AppType.caption.copyWith(
                                color: overdue
                                    ? p.error
                                    : (todo.done ? p.onSurfaceVariant : p.primary),
                              ),
                            ),
                          if (repeatText != null) ...[
                            const SizedBox(width: AppSpacing.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s4, vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: p.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(AppRadii.rSm),
                              ),
                              child: Text(
                                '循环 · $repeatText',
                                style: AppType.caption.copyWith(
                                  color: p.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
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
              // 已完成事项：可删除（进行中的不显示，避免误删）
              if (todo.done)
                IconButton(
                  tooltip: '删除',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final ok = await showConfirmSheet(
                      context,
                      title: '删除这条待办？',
                      message: '已完成事项删除后找不回来',
                    );
                    if (!ok) return;
                    await ref.read(todoRepoProvider).delete(todo.id);
                  },
                  icon: PhosphorIcon(
                    PhosphorIconsRegular.trash,
                    size: 18,
                    color: p.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}