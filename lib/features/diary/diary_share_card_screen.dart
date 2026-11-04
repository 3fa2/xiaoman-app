import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../design/tokens.dart';
import '../../di/providers.dart';
import '../../domain/models/diary.dart';
import '../shared/widgets.dart';

/// 日记分享卡片（v5.8）：把单篇日记渲染成竖版长图，可保存/分享。
/// 设计：雾蓝纸面 + 日期页眉 + 心情胶囊 + 大标题 + 正文（超长截断）
/// + 底部小满水印。截图用 RepaintBoundary.toImage（3x 像素密度）。
class DiaryShareCardScreen extends ConsumerStatefulWidget {
  const DiaryShareCardScreen({super.key, required this.diaryId});

  final int diaryId;

  @override
  ConsumerState<DiaryShareCardScreen> createState() =>
      _DiaryShareCardScreenState();
}

class _DiaryShareCardScreenState extends ConsumerState<DiaryShareCardScreen> {
  final _boundaryKey = GlobalKey();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: p.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('日记卡片'),
        actions: [
          IconButton(
            tooltip: '分享图片',
            onPressed: _exporting ? null : () => _share(dark: dark),
            icon: PhosphorIcon(
              PhosphorIconsRegular.shareNetwork,
              color: p.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Diary?>(
          future: ref.read(diaryRepoProvider).getById(widget.diaryId),
          builder: (context, snap) {
            final diary = snap.data;
            if (diary == null) {
              return const EmptyState(
                icon: PhosphorIconsRegular.notebook,
                title: '日记不存在或已被删除',
                hint: '从日记详情页右上角可以重新生成卡片',
              );
            }
            return StreamBuilder<List<Mood>>(
              stream: ref.watch(diaryRepoProvider).watchMoods(),
              builder: (context, moodSnap) {
                final moods = {
                  for (final m in (moodSnap.data ?? const <Mood>[])) m.id: m,
                };
                final mood = diary.moodId == null
                    ? null
                    : moods[diary.moodId];
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: FittedBox(
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: _DiaryCard(diary: diary, mood: mood),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _share({required bool dark}) async {
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _exporting = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw Exception('截图失败');
      final docs = await getApplicationDocumentsDirectory();
      final n = DateTime.now();
      final file = File(
        '${docs.path}/xiaoman-card-'
        '${n.year}${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}-${n.millisecondsSinceEpoch % 100000}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '来自小满 · 我的日记',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成卡片失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.diary, this.mood});

  final Diary diary;
  final Mood? mood;

  static const _cardW = 400.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark ? darkPalette : lightPalette;
    final d = DateTime(
      diary.dateDay ~/ 10000, (diary.dateDay ~/ 100) % 100, diary.dateDay % 100,
    );
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    // 正文截断：卡片是展示件，超长正文放不下（提示去 App 看全文）
    final content = diary.content.length > 600
        ? '${diary.content.substring(0, 600)}…'
        : diary.content;

    return Container(
      width: _cardW,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
      color: palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页眉：小满 · 日期
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.primary, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '小满',
                style: AppType.label.copyWith(color: palette.primary),
              ),
              const Spacer(),
              Text(
                '${d.year}年${d.month}月${d.day}日 · ${weekdays[d.weekday - 1]}',
                style: AppType.caption.copyWith(color: palette.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 心情
          if (mood != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: MoodPalette.colorOf(mood!.hue, dark: dark)
                    .withAlpha(60),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                mood!.name,
                style: AppType.label.copyWith(
                  color: MoodPalette.colorOf(mood!.hue, dark: dark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // 标题
          if (diary.title.isNotEmpty) ...[
            Text(
              diary.title,
              style: AppType.title.copyWith(
                color: palette.ink,
                height: 1.4,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 正文
          Text(
            content.isEmpty ? '（心情打卡）' : content,
            style: AppType.bodyLoose.copyWith(
              color: palette.ink,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 28),
          // 页脚：水印 + 篇幅提示
          Divider(color: palette.hairline),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '满而未满，刚刚好',
                style: AppType.caption.copyWith(color: palette.inkFaint),
              ),
              const Spacer(),
              if (diary.content.length > 600)
                Text(
                  '全文见小满 App',
                  style: AppType.caption.copyWith(color: palette.inkFaint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
