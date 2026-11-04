import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../shared/widgets.dart';

/// 标签管理（v5.9）：全部标签 + 使用计数，点按跳搜索页按该标签预过滤。
/// 入口：日记搜索页 AppBar。数据从 watchAll 现场汇总（个人量级足够）。
class DiaryTagsScreen extends ConsumerWidget {
  const DiaryTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('标签')),
      body: StreamBuilder(
        stream: ref.watch(diaryRepoProvider).watchAll(),
        builder: (context, snap) {
          final diaries = snap.data ?? const [];
          if (snap.connectionState == ConnectionState.waiting &&
              diaries.isEmpty) {
            return const SkeletonList();
          }
          // 汇总：tag -> 使用次数（回收站条目已被 watchAll 排除）
          final counts = <String, int>{};
          for (final d in diaries) {
            for (final t in d.tags) {
              counts[t] = (counts[t] ?? 0) + 1;
            }
          }
          final tags = counts.keys.toList()..sort();
          if (tags.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsRegular.tag,
              title: '还没有标签',
              hint: '在日记编辑器里加标签，它们会汇总在这里',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.s8, AppSpacing.page,
              AppSpacing.listBottom,
            ),
            itemCount: tags.length,
            itemBuilder: (context, i) {
              final tag = tags[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.rLg),
                    onTap: () => context.push(
                      '/diary/search?q=${Uri.encodeComponent(tag)}',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPad),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIconsRegular.tag,
                            size: 18,
                            color: p.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Text(
                              tag,
                              style: AppType.body.copyWith(color: p.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${counts[tag]} 篇',
                            style: AppType.caption.copyWith(
                              color: p.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Icon(Icons.chevron_right,
                              size: 18, color: p.onSurfaceVariant),
                        ],
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
}
