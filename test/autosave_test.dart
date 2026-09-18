import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/domain/models/media.dart';
import 'package:trinity/domain/repositories/repositories.dart';
import 'package:trinity/domain/services/autosave_controller.dart';

/// P0-1 硬门禁：测试 A（输入→立刻返回→内容还在）与
/// 测试 C（Repository 抛异常 → UI 必须显示"保存失败"且不得显示"已保存"）
/// 在 controller 层验证；widget 集成由冒烟测试覆盖。

class FakeEditorRepo implements EditorRepository {
  FakeEditorRepo({this.failSaves = false});

  final bool failSaves;
  final savedPayloads = <({int? id, String title, String content, int? extra})>[];
  final drafts = <int, String>{};
  var nextId = 100;

  @override
  Future<int> save({
    required int? id,
    required String title,
    required String content,
    required int? extra,
  }) async {
    if (failSaves) throw StateError('db locked');
    final newId = id ?? nextId++;
    savedPayloads.add((id: newId, title: title, content: content, extra: extra));
    return newId;
  }

  @override
  Future<void> saveDraft({
    required MediaOwner ownerType,
    required int ownerId,
    required String payload,
  }) async {
    drafts[ownerId] = payload;
  }

  @override
  Future<void> clearDraft({
    required MediaOwner ownerType,
    required int ownerId,
  }) async {
    drafts.remove(ownerId);
  }

  @override
  Future<Draft?> findDraft({
    required MediaOwner ownerType,
    required int ownerId,
  }) async {
    final p = drafts[ownerId];
    if (p == null) return null;
    return Draft(
      id: 0,
      ownerType: ownerType,
      ownerId: ownerId,
      payload: p,
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  test('测试 A：输入 → 立刻 pop（flush await）→ 重新打开内容还在', () async {
    final repo = FakeEditorRepo();
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
      debounce: const Duration(hours: 1), // 去抖未到点也要 flush 出去
    );
    c.loadBaseline(entityId: 7, title: '', content: '', extra: null);
    c.onChanged(title: '标题', content: '今天写了很长的一段话，绝不能丢。', extra: null);
    // 用户立刻按返回：PopScope 调 flush（await）
    await c.flush(title: '标题', content: '今天写了很长的一段话，绝不能丢。', extra: null);
    // 重新打开（查库）
    expect(repo.savedPayloads, isNotEmpty);
    expect(repo.savedPayloads.last.content, '今天写了很长的一段话，绝不能丢。');
    expect(c.status, SaveStatus.saved);
    c.dispose();
  });

  test('测试 A2：保存中到达的第二次输入在锁释放后合并保存（Mutex 防重入）', () async {
    final repo = FakeEditorRepo();
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
      debounce: const Duration(milliseconds: 10),
    );
    c.loadBaseline(entityId: 7, title: '', content: '', extra: null);
    c.onChanged(title: '', content: '第一段', extra: null);
    // debounce 到点触发 saveNow（异步进行中）
    await Future<void>.delayed(const Duration(milliseconds: 30));
    c.onChanged(title: '', content: '第一段第二段', extra: null);
    await c.flush(title: '', content: '第一段第二段', extra: null);
    final last = repo.savedPayloads.last;
    expect(last.content, '第一段第二段');
    c.dispose();
  });

  test('测试 C：Repository 抛异常 → 状态必须是 error，绝不 saved', () async {
    final repo = FakeEditorRepo(failSaves: true);
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
    );
    c.loadBaseline(entityId: 7, title: '', content: '', extra: null);
    c.onChanged(title: 'x', content: 'y', extra: null);
    await c.flush(title: 'x', content: 'y', extra: null);
    expect(c.status, SaveStatus.error);
    expect(c.error, isNotNull);
    c.dispose();
  });

  test('测试 C2：失败后草稿仍在（崩溃/失败兜底可恢复）', () async {
    final repo = FakeEditorRepo(failSaves: true);
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
    );
    c.loadBaseline(entityId: 7, title: '', content: '', extra: null);
    c.onChanged(title: '', content: '还没保存成功的草稿', extra: null);
    await c.flush(title: '', content: '还没保存成功的草稿', extra: null);
    expect(repo.drafts[7], contains('还没保存成功的草稿'));
    c.dispose();
  });

  test('测试 D：空编辑器（无变化）→ 退出不产生垃圾记录', () async {
    final repo = FakeEditorRepo();
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
    );
    c.loadBaseline(entityId: null, title: '', content: '', extra: null);
    await c.flush(title: '', content: '', extra: null);
    expect(repo.savedPayloads, isEmpty);
    c.dispose();
  });

  test('整实体脏检查：内容改回原文 → 不写库', () async {
    final repo = FakeEditorRepo();
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
    );
    c.loadBaseline(entityId: 7, title: 'T', content: 'C', extra: null);
    c.onChanged(title: 'T2', content: 'C', extra: null); // dirty
    c.onChanged(title: 'T', content: 'C', extra: null); // 改回
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await c.flush(title: 'T', content: 'C', extra: null);
    expect(repo.savedPayloads, isEmpty);
    expect(c.status, SaveStatus.saved);
    c.dispose();
  });

  test('最小长度护栏：空内容不覆盖', () async {
    final repo = FakeEditorRepo();
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
      minContentLength: 1,
    );
    c.loadBaseline(entityId: 7, title: '', content: '原文有内容', extra: null);
    c.onChanged(title: '', content: '', extra: null);
    await c.flush(title: '', content: '', extra: null);
    expect(repo.savedPayloads, isEmpty);
    c.dispose();
  });

  test('保存成功后清草稿', () async {
    final repo = FakeEditorRepo();
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
    );
    c.loadBaseline(entityId: 7, title: '', content: '', extra: null);
    c.onChanged(title: 'ok', content: 'done', extra: null);
    await c.flush(title: 'ok', content: 'done', extra: null);
    expect(repo.drafts[7], isNull);
    c.dispose();
  });

  test('dispose 后不再通知与保存（不发起新写入）', () async {
    final repo = FakeEditorRepo();
    final c = AutosaveController(
      repo: repo,
      draftOwnerType: MediaOwner.diary,
    );
    c.loadBaseline(entityId: null, title: '', content: '', extra: null);
    c.dispose();
    c.onChanged(title: 'after', content: 'dispose', extra: null);
    await c.flush(title: 'after', content: 'dispose', extra: null);
    expect(repo.savedPayloads, isEmpty);
  });
}
