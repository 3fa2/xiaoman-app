import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trinity/data/db/database.dart';
import 'package:trinity/di/providers.dart';
import 'package:trinity/features/diary/diary_editor_screen.dart';

/// 硬门禁（用户真机反馈复现）：输入后 2 秒去抖窗口内点「完成」，
/// PopScope 必须拦截并 flush——丢字 = P0。
void main() {
  late AppDatabase db;

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: DiaryEditorScreen(diaryId: null)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('输入后立刻点完成（去抖窗口内）→ 内容必须落库', (tester) async {
    await pumpEditor(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2)); // 标题 + 正文
    await tester.enterText(fields.last, 'race');
    await tester.pump(); // onChanged → dirty（不推进 2 秒）

    // dirty 态必须可见（UI 不撒谎）
    expect(find.text('编辑中，停顿 2 秒自动保存'), findsOneWidget);

    // 立刻点完成：PopScope 拦截 → flush → 手动 pop
    await tester.tap(find.text('完成'));
    await tester.pump();
    await tester.pumpAndSettle();
    // drift 落库是真异步：给真实时间提交
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );

    final rows = await db.select(db.diaries).get();
    expect(rows, isNotEmpty, reason: '2 秒内点完成必须保存');
    expect(rows.first.content, 'race');
  });

  testWidgets('连续输入两次后立刻点完成 → 两次输入都不能丢', (tester) async {
    await pumpEditor(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.last, '第一段');
    await tester.pump();
    await tester.enterText(fields.last, '第一段第二段');
    await tester.pump();

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );

    final rows = await db.select(db.diaries).get();
    expect(rows, isNotEmpty);
    expect(rows.first.content, '第一段第二段');
  });
}
