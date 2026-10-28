import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // 数据流只在 initState 订阅一次（在 build 里 watchAll 会每次生成新流，
  // StreamBuilder 重订阅 → 每次点筛选/排序都闪骨架屏、滚动归顶）。
  StreamSubscription<List<Todo>>? _sub;
  List<Todo> _all = const [];
  bool _loaded = false;

  // 撒花：只由「进行中数量从 >0 变 0」的那次数据发射触发；
  // 出现新的进行中事项即复位（取消勾选可复现）。
  // 切筛选档不碰数据流，不会误触发；重开 App 首次发射 prev=false 也不撒。
  int _activeCount = 0;
  bool _prevHadActive = false;
  bool _celebrating = false;

  // 勾选动画：翻转后让条目原位停留一拍播完过渡动画，再回流到目标分区。
  // （条目跨分区迁移会重建 element，隐式动画直接跳终态 = 动画白做。）
  final Map<int, bool> _holdInSection = {}; // id -> 停留显示在未完成区?
  final Map<int, Timer> _holdTimers = {};

  @override
  void initState() {
    super.initState();
    _loadSort();
    _sub = ref.read(todoRepoProvider).watchAll().listen((list) {
      if (!mounted) return;
      final active = list.where((t) => !t.done).length;
      setState(() {
        _all = list;
        _loaded = true;
        _activeCount = active;
        if (list.isNotEmpty && active == 0 && _prevHadActive) {
          _celebrating = true; // 闩住，banner 不随下一次重建消失
        }
        if (active > 0) _celebrating = false; // 复位：可再次庆祝
        _prevHadActive = active > 0;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final t in _holdTimers.values) {
      t.cancel();
    }
    super.dispose();
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

  void _syncReminders() {
    // 待办增删改后重排提醒：新建当天到期的待办要能按时响（启动兜底之外的路径）
    ref.read(reminderWarningsProvider.notifier).syncNow();
  }

  void _toggleTodo(Todo t) {
    HapticFeedback.mediumImpact();
    // 原位停留播完动画再回流（见 _holdInSection 注释）
    _holdInSection[t.id] = !t.done;
    _holdTimers[t.id]?.cancel();
    _holdTimers[t.id] = Timer(const Duration(milliseconds: 420), () {
      _holdTimers.remove(t.id);
      if (!mounted) return;
      setState(() => _holdInSection.remove(t.id));
    });
    ref.read(todoRepoProvider).toggle(id: t.id, done: !t.done);
    _syncReminders();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '待办'),
              if (_all.isNotEmpty) ...[
                const TextSpan(text: '  '),
                TextSpan(
                  text: '共 ${_all.length} 条',
                  style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                ),
              ],
            ],
          ),
          style: AppType.title.copyWith(color: p.onSurface),
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
                _syncReminders();
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
      body: !_loaded
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: SkeletonList(),
            )
          : Builder(builder: (context) {
              if (_all.isEmpty) {
                return const EmptyState(
                  icon: PhosphorIconsRegular.listChecks,
                  title: '还没有待办',
                  hint: '点右下角加一个，或从桌面小组件直接记',
                );
              }
              // 分区显示：被「原位播动画」按住的条目留在原分区并绕过筛选档
              // （否则「进行中」档勾选时条目立即消失，动画被截断；见 _toggleTodo）
              bool matches(Todo t) => switch (_filter) {
                    _Filter.all => true,
                    _Filter.active => !t.done,
                    _Filter.done => t.done,
                  };
              var active = _all.where((t) {
                if (_holdInSection.containsKey(t.id)) {
                  return _holdInSection[t.id]!;
                }
                return !t.done && matches(t);
              }).toList();
              var done = _all.where((t) {
                if (_holdInSection.containsKey(t.id)) {
                  return !_holdInSection[t.id]!;
                }
                return t.done && matches(t);
              }).toList();
              // 排序
              int byCreated(Todo a, Todo b) =>
                  b.createdAt.compareTo(a.createdAt);
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
              final total = _all.length;
              // 各筛选的准确计数：全部=含已完成总数；进行中/已完成独立计数
              final doneCount = total - _activeCount;
              // 庆祝横幅：数据层判定（见 _sub.listen），且全部清掉后收起
              final celebrate =
                  _celebrating && _activeCount == 0 && _all.isNotEmpty;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  0, AppSpacing.s8, 0, AppSpacing.listBottom,
                ),
                children: [
                  if (celebrate) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Center(
                      child: ConfettiBurst(size: 150),
                    ),
                    Text(
                      '全部完成，休息一下',
                      textAlign: TextAlign.center,
                      style: AppType.label.copyWith(color: p.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                  ],
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
                          label: '进行中 $_activeCount',
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
                  else if (done.isEmpty && _filter == _Filter.done)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.page, vertical: AppSpacing.s8,
                      ),
                      child: Text(
                        '还没有完成的事',
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
                          child: _TodoRow(
                            todo: active[i],
                            onToggle: () => _toggleTodo(active[i]),
                          ),
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
                          child: Dismissible(
                            key: ValueKey('done-${t.id}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              HapticFeedback.mediumImpact();
                              await ref.read(todoRepoProvider).delete(t.id);
                              _syncReminders();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已删除「${t.title}」'),
                                  action: SnackBarAction(
                                    label: '撤销',
                                    onPressed: () {
                                      if (!mounted) return;
                                      // 按原状态（已完成）原样恢复
                                      ref.read(todoRepoProvider).add(
                                            title: t.title,
                                            dueDay: t.dueDay,
                                            remindBefore: t.remindBefore,
                                            repeat: t.repeat,
                                            done: true,
                                          );
                                      _syncReminders();
                                    },
                                  ),
                                ),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(
                                right: AppSpacing.cardPad,
                              ),
                              decoration: BoxDecoration(
                                color: p.errorContainer,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.rLg),
                              ),
                              child: PhosphorIcon(
                                PhosphorIconsRegular.trash,
                                color: p.onErrorContainer,
                              ),
                            ),
                            child: _TodoRow(
                              todo: t,
                              onToggle: () => _toggleTodo(t),
                              inDoneSection: true,
                            ),
                          ),
                        ),
                  ],
                ],
              );
            }),
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
  const _TodoRow({
    required this.todo,
    required this.onToggle,
    this.inDoneSection = false,
  });
  final Todo todo;

  /// 勾选框点击（触感 + 原位动画停留 + 落库由上层统一处理）
  final VoidCallback onToggle;

  /// 是否显示在已完成分区（控制删除按钮可见性；原位动画停留期间不显示）
  final bool inDoneSection;

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
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: MotionCurve.standard,
                      style: AppType.body.copyWith(
                        color: todo.done ? p.onSurfaceVariant : p.onSurface,
                        decoration: todo.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      child: Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
              // 圆形勾选框（勾选时颜色/填充平滑过渡 + 图标弹入 + 触感反馈）
              PressableScale(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: MotionCurve.standard,
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
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 250),
                    curve: todo.done
                        ? MotionCurve.standard
                        : Curves.easeOut,
                    scale: todo.done ? 1 : 0,
                    child: PhosphorIcon(
                      PhosphorIconsFill.check,
                      size: 14,
                      color: p.onPrimary,
                    ),
                  ),
                ),
              ),
              // 已完成事项：可删除（进行中的不显示，避免误删）
              if (inDoneSection)
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
                    ref.read(reminderWarningsProvider.notifier).syncNow();
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