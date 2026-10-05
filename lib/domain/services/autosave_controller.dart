import 'dart:async';

import 'package:synchronized/synchronized.dart';

import '../models/media.dart';
import '../repositories/repositories.dart';

/// 保存状态机（Saber 模式）：UI 只反映真实状态，绝不撒谎。
enum SaveStatus { idle, dirty, saving, saved, error }

/// 自动保存控制器（P0-1 核心）。
///
/// 设计要点（全部来自行业验证过的做法）：
/// - 保存逻辑不依赖 BuildContext / ref：构造注入 repository，dispose 后依然可完成
/// - Mutex 互斥防重入（MoeMemos：autosaveMutex.withLock）
/// - flush() 可 await：退出守卫 PopScope 等 flush 完成再 pop
/// - 绝不吞异常：失败置 SaveStatus.error，UI 必须显示"保存失败"
/// - 整实体脏检查（NotallyX）：无变化不写库
/// - 最小长度护栏（Markor）：未加载完成不保存，防覆盖成空
/// - 草稿兜底（MoeMemos）：每次变更写 drafts，成功后清除
class AutosaveController {
  AutosaveController({
    required EditorRepository repo,
    required this.draftOwnerType,
    this.debounce = const Duration(seconds: 2),
    this.minContentLength = 0,
    this.onSaved,
  }) : _repo = repo;

  final EditorRepository _repo;
  final MediaOwner draftOwnerType;
  final Duration debounce;
  final int minContentLength;

  /// 保存成功后回调（新建首存回填 id，页面用于级联操作）
  final void Function(int id)? onSaved;

  final _lock = Lock();
  Timer? _debounceTimer;
  bool _disposed = false;

  // ---- 状态 ----
  SaveStatus _status = SaveStatus.idle;
  DateTime? _lastSavedAt;
  Object? _error;
  final _listeners = <void Function()>[];

  SaveStatus get status => _status;
  DateTime? get lastSavedAt => _lastSavedAt;
  Object? get error => _error;

  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);

  void _set(SaveStatus s, {DateTime? at, Object? err}) {
    if (_disposed) return;
    _status = s;
    _lastSavedAt = at ?? _lastSavedAt;
    _error = err;
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  // ---- 基线（整实体脏检查）----
  int? _entityId; // null = 新建
  String _baselineTitle = '';
  String _baselineContent = '';
  int? _baselineMoodOrExtra;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 编辑器加载数据后调用：记录基线，开启保存能力
  void loadBaseline({
    required int? entityId,
    required String title,
    required String content,
    int? extra,
  }) {
    _entityId = entityId;
    _baselineTitle = title;
    _baselineContent = content;
    _baselineMoodOrExtra = extra;
    _loaded = true;
  }

  bool _isModified(String title, String content, int? extra) =>
      title != _baselineTitle ||
      content != _baselineContent ||
      extra != _baselineMoodOrExtra;

  /// 用户输入变化（编辑器 onChanged）
  void onChanged({
    required String title,
    required String content,
    int? extra,
  }) {
    if (!_loaded || _disposed) return;
    if (!_isModified(title, content, extra)) return;
    _set(SaveStatus.dirty);
    // 草稿兜底：立即写（轻量 JSON，不做 debounce，崩溃时最多丢几个字）
    _repo.saveDraft(
      ownerType: draftOwnerType,
      ownerId: _entityId ?? -1,
      payload: _draftPayload(title, content, extra),
    );
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      saveNow(title: title, content: content, extra: extra);
    });
  }

  String _draftPayload(String title, String content, int? extra) {
    String esc(String s) => s
        .replaceAll('\\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        // \r/\t 不转义会产出非法 JSON（jsonDecode 抛错），恢复正则也在 \r 处截断
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '{"title":"${esc(title)}","content":"${esc(content)}",'
        '"extra":${extra ?? 'null'}}';
  }

  /// 立即保存（去抖到点 / flush / 手动触发共用入口）。
  /// Lock 串行排队；重复调用靠基线检查幂等跳过。
  Future<void> saveNow({
    required String title,
    required String content,
    int? extra,
  }) async {
    if (!_loaded || _disposed) return;
    _debounceTimer?.cancel();

    await _lock.synchronized(() async {
      if (_disposed) return;
      // 无变化不写库（NotallyX 整实体脏检查）
      if (!_isModified(title, content, extra)) {
        if (_status == SaveStatus.dirty || _status == SaveStatus.saving) {
          _set(SaveStatus.saved, at: _lastSavedAt ?? DateTime.now());
        }
        return;
      }
      // 最小长度护栏：防止"编辑器还没加载完把已有内容覆盖成空"
      if (content.length < minContentLength) return;

      _set(SaveStatus.saving);
      try {
        final id = await _repo.save(
          id: _entityId,
          title: title,
          content: content,
          extra: extra,
        );
        if (_entityId == null) {
          _entityId = id;
          onSaved?.call(id);
          // 首存成功：清掉"新建中"的 -1 草稿，
          // 否则每次新建都弹上一篇已保存日记的旧草稿（恢复还会造成内容重复）
          await _repo.clearDraft(ownerType: draftOwnerType, ownerId: -1);
        }
        _baselineTitle = title;
        _baselineContent = content;
        _baselineMoodOrExtra = extra;
        _set(SaveStatus.saved, at: DateTime.now());
        await _repo.clearDraft(ownerType: draftOwnerType, ownerId: _entityId!);
      } catch (e) {
        // ★ 绝不吞异常：失败必须可见
        _set(SaveStatus.error, err: e);
      }
    });
  }

  /// 退出守卫调用：可 await，保证落库完成
  Future<void> flush({
    required String title,
    required String content,
    int? extra,
  }) async {
    if (_status == SaveStatus.dirty || _status == SaveStatus.idle) {
      await saveNow(title: title, content: content, extra: extra);
    }
  }

  /// dispose 只做清理，不发起新写入（写入由 flush 完成）
  void dispose() {
    _debounceTimer?.cancel();
    _listeners.clear();
    _disposed = true;
  }
}
