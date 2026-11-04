import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xiaoman/data/db/database.dart';
import 'package:xiaoman/di/providers.dart';
import 'package:xiaoman/features/notes/note_editor_screen.dart';

/// 硬门禁（P0 回归）：已有笔记的标签必须落库。
/// 修复前根因：_controllerEntityId() 只看 _savedId（仅新建首存回填），
/// 打开已有笔记时恒为 null → _flushNote 空转 → 标签 100% 静默丢失。
void main() {
  late AppDatabase db;

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> seedNote() async {
    final now = DateTime.now();
    final nbId = await db.into(db.notebooks).insert(
          NotebooksCompanion.insert(
            name: '默认',
            colorIndex: 0,
            sortOrder: 0,
            createdAt: now,
          ),
        );
    return db.into(db.notes).insert(
          NotesCompanion.insert(
            notebookId: nbId,
            title: const Value('一条已有笔记'),
            content: const Value('正文内容'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> pumpEditor(WidgetTester tester, int? noteId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(home: NoteEditorScreen(noteId: noteId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleDb(WidgetTester tester) async {
    // drift 落库是真异步：给真实时间提交
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
  }

  testWidgets('已有笔记：加标签 → 点完成 → 标签必须在库里', (tester) async {
    final id = await seedNote();
    await pumpEditor(tester, id);

    // 打开标签弹窗 → 输入 → 回车（_addTag 立即窄写）
    await tester.tap(find.text('加标签'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.last, '重要');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await settleDb(tester);

    final note =
        await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle();
    expect(note.tags, contains('重要'),
        reason: '已有笔记加标签必须立即落库，不能等完成按钮兜底');

    // 点完成退出：整行写回不丢标签
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await settleDb(tester);

    final after =
        await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle();
    expect(after.tags, contains('重要'), reason: '完成后标签仍在');
    expect(after.content, '正文内容', reason: '退出 flush 不丢正文');
  });

  testWidgets('新建笔记：先加标签再打字 → 完成 → 标签随首存补写', (tester) async {
    await pumpEditor(tester, null);

    // 先加标签（实体未建，暂存在 state）
    await tester.tap(find.text('加标签'));
    await tester.pumpAndSettle();
    final sheetField = find.byType(TextField).last;
    await tester.enterText(sheetField, '灵感');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // 再输入正文触发自动保存通道
    final fields = find.byType(TextField);
    await tester.enterText(fields.last, '新建的内容');
    await tester.pump();

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await settleDb(tester);

    final rows = await db.select(db.notes).get();
    expect(rows, isNotEmpty, reason: '完成必须落库');
    expect(rows.first.content, '新建的内容');
    expect(rows.first.tags, contains('灵感'),
        reason: '暂存标签必须在首存后补写（onSaved 通道）');
  });
}
