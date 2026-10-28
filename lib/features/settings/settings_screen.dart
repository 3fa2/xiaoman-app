import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../design/version.dart';
import '../../di/providers.dart';
import '../shared/widgets.dart';
import 'lock_hash.dart';

/// 设置：外观（浅/深/跟系统）、锁屏、通知权限引导（含 vivo 中文指引）、
/// 备份导出、关于。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasPin = false;
  bool _exactOk = true;
  bool _notifGranted = true;
  bool _diaryRemind = false; // v5.3 写日记提醒
  String _diaryRemindTime = '22:00';
  bool _autoBackup = true; // v5.3 每日自动备份
  List<FileSystemEntity> _autoBackups = const [];
  String? _backupDirLabel; // v5.8 用户备份目录（显示用）

  @override
  void initState() {
    super.initState();
    _check();
    _loadBackupDir();
  }

  Future<void> _loadBackupDir() async {
    final provider = ref.read(autoBackupProvider);
    final uri = await provider.backupDirUri();
    final sync = await provider.treeSyncStatus();
    if (!mounted) return;
    // tree uri 形如 content://com.android.externalstorage.documents/tree/primary%3ABackup
    // 展示最后一段可读名（primary:Backup → Backup）
    String? label;
    if (uri != null && uri.isNotEmpty) {
      final marker = 'tree/';
      final i = uri.indexOf(marker);
      if (i != -1) {
        final seg = Uri.decodeComponent(uri.substring(i + marker.length));
        label = seg.split(':').last;
        if (label.isEmpty) label = '已选目录';
      } else {
        label = '已选目录';
      }
      // 最近一次同步结果（v5.8.1：失败要可见，不能让用户以为已同步）
      if (sync == 'fail') label = '$label（上次同步失败）';
    }
    setState(() => _backupDirLabel = label);
  }

  Future<void> _check() async {
    final hasPin = await ref.read(settingsRepoProvider).get('lock_pin_hash');
    final exact = await ref.read(notificationServiceProvider).canExact();
    final notif = await Permission.notification.isGranted;
    final remind = await ref.read(settingsRepoProvider).get('diary_remind_enabled');
    final remindTime =
        await ref.read(settingsRepoProvider).get('diary_remind_time') ?? '22:00';
    final auto = await ref.read(autoBackupProvider).isEnabled();
    final backups = await ref.read(autoBackupProvider).listBackups();
    if (mounted) {
      setState(() {
        // 空字符串 = 已关闭锁（set('lock_pin_hash', '')），不算开启
        _hasPin = hasPin != null && hasPin.isNotEmpty;
        _exactOk = exact;
        _notifGranted = notif;
        _diaryRemind = remind == '1';
        _diaryRemindTime = remindTime;
        _autoBackup = auto;
        _autoBackups = backups;
      });
    }
  }

  Future<void> _setDiaryRemind(bool v) async {
    setState(() => _diaryRemind = v);
    await ref.read(settingsRepoProvider).set('diary_remind_enabled', v ? '1' : '0');
    unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());
  }

  Future<void> _pickDiaryTime() async {
    final parts = _diaryRemindTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 22,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
    );
    if (picked == null) return;
    final t =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _diaryRemindTime = t);
    await ref.read(settingsRepoProvider).set('diary_remind_time', t);
    unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());
  }

  Future<void> _setAutoBackup(bool v) async {
    setState(() => _autoBackup = v);
    await ref.read(autoBackupProvider).setEnabled(v);
  }

  Future<void> _runAutoBackupNow() async {
    try {
      final path = await ref.read(autoBackupProvider).runNow();
      await _check();
      _loadBackupDir();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已备份：${path.split('/').last}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败：$e')),
        );
      }
    }
  }

  static String _autoBackupLabel(FileSystemEntity f) {
    final name = f.path.split(Platform.pathSeparator).last;
    return name.replaceAll('auto-backup-', '').replaceAll('.json', '');
  }

  Future<void> _restoreAutoBackup(FileSystemEntity f) async {
    final ok = await showConfirmSheet(
      context,
      title: '恢复「${_autoBackupLabel(f)}」？',
      message: '当前所有日记、备忘、日程、待办会被这份备份覆盖',
    );
    if (!ok || !mounted) return;
    // 恢复前强制快照当前数据（与手动导入同一纪律）：
    // 备份可能比当前数据旧，覆盖前留一条后悔路
    try {
      await ref.read(autoBackupProvider).runNow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复前备份失败，已取消恢复：$e')),
        );
      }
      return;
    }
    try {
      await ref.read(autoBackupProvider).restoreFrom(f.path);
      await _check();
      unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已从自动备份恢复')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：$e')),
        );
      }
    }
  }

  Future<void> _exportMarkdown() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成 Markdown…')),
      );
      await ref.read(backupProvider).shareMarkdown();
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final dynamicColor = ref.watch(dynamicColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.listBottom,
        ),
        children: [
          const SectionHeader('外观'),
          Card(
            child: Column(
              children: [
                for (final (label, mode) in const <(String, ThemeModeOption)>[
                  ('跟系统', ThemeModeOption.system),
                  ('浅色', ThemeModeOption.light),
                  ('深色', ThemeModeOption.dark),
                ])
                  RadioListTile<ThemeModeOption>(
                    title: Text(label, style: AppType.body.copyWith(color: p.onSurface)),
                    value: mode,
                    groupValue: ThemeModeOption.from(themeMode),
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(themeModeProvider.notifier).set(v.toThemeMode());
                    },
                  ),
                // Material You（Android 12+）：骨架跟随壁纸取色，内容色板不动
                if (dynamicColor.supported) ...[
                  const Divider(indent: AppSpacing.cardPad),
                  SwitchListTile(
                    title: Text(
                      '跟随系统取色',
                      style: AppType.body.copyWith(color: p.onSurface),
                    ),
                    subtitle: Text(
                      'Material You：界面骨架跟随壁纸配色（Android 12+），心情与日程色保持原样',
                      style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                    ),
                    value: dynamicColor.enabled,
                    onChanged: (v) =>
                        ref.read(dynamicColorProvider.notifier).setEnabled(v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.block),
          const SectionHeader('锁屏'),
          Card(
            child: ListTile(
              leading: PhosphorIcon(
                _hasPin
                    ? PhosphorIconsFill.lockSimple
                    : PhosphorIconsRegular.lockSimpleOpen,
                color: p.onSurfaceVariant,
              ),
              title: Text(
                _hasPin ? '已开启密码锁（6 位 PIN）' : '开启密码锁',
                style: AppType.body.copyWith(color: p.onSurface),
              ),
              subtitle: Text(
                _hasPin ? '打开 App 时需要解锁（支持生物识别）' : '打开 App 时先解锁',
                style: AppType.caption.copyWith(color: p.onSurfaceVariant),
              ),
              trailing: TextButton(
                onPressed: () => _editPin(context),
                child: Text(_hasPin ? '修改' : '设置'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.block),
          const SectionHeader('日程提醒'),
          Card(
            child: Column(
              children: [
                // v5.0：日程从底部 tab 摘除，这里保留全功能入口
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.calendarBlank,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '日程管理',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '查看 / 新建 / 编辑日程，与首页入口相同',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/schedule'),
                ),
                const Divider(indent: AppSpacing.cardPad),
                ListTile(
                  leading: PhosphorIcon(
                    _notifGranted
                        ? PhosphorIconsFill.bellSimple
                        : PhosphorIconsRegular.bellSimpleSlash,
                    color: _notifGranted ? p.primary : p.error,
                  ),
                  title: Text(
                    _notifGranted ? '通知权限已授予' : '通知权限未开启',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  trailing: _notifGranted
                      ? null
                      : TextButton(
                          onPressed: () async {
                            await Permission.notification.request();
                            _check();
                          },
                          child: const Text('去开启'),
                        ),
                ),
                ListTile(
                  leading: PhosphorIcon(
                    _exactOk
                        ? PhosphorIconsFill.alarm
                        : PhosphorIconsRegular.alarm,
                    color: _exactOk ? p.primary : p.error,
                  ),
                  title: Text(
                    _exactOk ? '精确闹钟已授权' : '精确闹钟未授权（提醒可能延迟）',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  trailing: _exactOk
                      ? TextButton(
                          onPressed: () =>
                              ref.read(notificationServiceProvider).testNow(),
                          child: const Text('测试'),
                        )
                      : TextButton(
                          onPressed: () => openAppSettings(),
                          child: const Text('去授权'),
                        ),
                ),
                // v5.3：每日写日记提醒
                const Divider(indent: AppSpacing.cardPad),
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.penNib,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '写日记提醒',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    _diaryRemind ? '每天 $_diaryRemindTime 提醒，点通知直达编辑器' : '每天固定时间提醒你写两笔',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_diaryRemind)
                        TextButton(
                          onPressed: _pickDiaryTime,
                          child: Text(
                            _diaryRemindTime,
                            style: AppType.label.copyWith(color: p.primary),
                          ),
                        ),
                      Switch(value: _diaryRemind, onChanged: _setDiaryRemind),
                    ],
                  ),
                ),
                const Divider(indent: AppSpacing.cardPad),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vivo / 其他国产手机后台限制：请手动开启以下开关，否则提醒可能不响',
                        style: AppType.label.copyWith(color: p.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        '1. 设置 → 应用 → 小满 → 自启动：允许\n'
                        '2. 电池 → 后台耗电：允许后台高耗电\n'
                        '3. 电池 → 不受限制（或「无限制」）\n'
                        '4. 多任务卡片下拉 → 锁定\n'
                        '5. 通知权限全部打开\n\n'
                        '即便如此，系统仍可能在极端省电时延迟提醒，这是厂商限制，App 侧无法绕过。'
                        '已做三重兜底：精确闹钟 + 重启自动重建 + 每次打开 App 重建全部提醒。',
                        style: AppType.caption.copyWith(
                          color: p.onSurfaceVariant, height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.block),
          const SectionHeader('备份'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.export,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '导出全部数据（JSON）',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '日记、备忘、日程、心情，分享到任意应用保存',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  onTap: () async {
                    await ref.read(backupProvider).shareBackup();
                  },
                ),
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.package,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '导出完整备份（含图片视频）',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '数据 + 媒体文件打成一个 zip，换机不丢图；文件大，耐心等',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  onTap: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('正在打包（含媒体），请稍候…')),
                      );
                      await ref.read(backupProvider).shareFullBackup();
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('导出失败：$e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.fileText,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '导出日记（Markdown）',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '按月分节的 .md 文件，含心情与标签，方便转移和打印',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  onTap: _exportMarkdown,
                ),
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.downloadSimple,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '导入数据（恢复备份）',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '从 JSON 备份文件恢复，会覆盖当前数据',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  onTap: () => _importData(context, ref),
                ),
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.archive,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '从完整备份恢复（含媒体）',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '选「导出完整备份」生成的 zip，数据+图片视频一起回来',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  onTap: () => _importFullBackup(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.block),
          const SectionHeader('数据安全'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.trash,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '回收站（日记·备忘）',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '删掉的内容保留 30 天，可恢复',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.openDiaryTrash(),
                ),
                const Divider(indent: AppSpacing.cardPad),
                ListTile(
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.shieldCheck,
                    color: p.onSurfaceVariant,
                  ),
                  title: Text(
                    '每日自动备份',
                    style: AppType.body.copyWith(color: p.onSurface),
                  ),
                  subtitle: Text(
                    '打开 App 时静默备份到本机，保留最近 7 份，防损坏防误删',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  trailing: Switch(
                    value: _autoBackup,
                    onChanged: (v) {
                      _setAutoBackup(v);
                      _check();
                    },
                  ),
                ),
                ListTile(
                  leading: const SizedBox(width: 24),
                  title: Text(
                    '立即备份一份',
                    style: AppType.body.copyWith(color: p.primary),
                  ),
                  onTap: _runAutoBackupNow,
                ),
                const Divider(indent: AppSpacing.cardPad),
                ListTile(
                  leading: const SizedBox(width: 24),
                  title: Text(
                    _backupDirLabel ?? '备份到用户目录（网盘/文档）',
                    style: AppType.body.copyWith(
                      color: _backupDirLabel == null
                          ? p.primary
                          : p.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _backupDirLabel == null
                        ? '选一个文件夹（如网盘同步目录），每日自动备份多存一份，卸载也不丢'
                        : '每日自动备份会同步一份到这里；点此可更换目录',
                    style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                  ),
                  trailing: (_backupDirLabel != null)
                      ? TextButton(
                          onPressed: () async {
                            await ref
                                .read(autoBackupProvider)
                                .setBackupDirUri(null);
                            _loadBackupDir();
                          },
                          child: const Text('停用'),
                        )
                      : null,
                  onTap: () async {
                    try {
                      final uri =
                          await ref.read(autoBackupProvider).pickBackupDir();
                      if (uri != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已开启用户目录备份')),
                        );
                      }
                      _loadBackupDir();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('选择目录失败：$e')),
                        );
                      }
                    }
                  },
                ),
                // 最近备份可点恢复（自动备份在私有目录，SAF 选不到，必须从这里进）
                for (final f in _autoBackups.take(3))
                  ListTile(
                    leading: const SizedBox(width: 24),
                    dense: true,
                    title: Text(
                      _autoBackupLabel(f),
                      style: AppType.caption.copyWith(color: p.onSurface),
                    ),
                    trailing: TextButton(
                      onPressed: () => _restoreAutoBackup(f),
                      child: const Text('恢复'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.block),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.rSm),
              onTap: _showChangelog,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Text(
                  '小满 v$appVersionName · 本地数据，不联网 · 点此看更新记录',
                  style: AppType.caption.copyWith(color: p.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 应用内更新日志（v5.8.1）：CHANGELOG.md 随包发布，轻量行解析展示。
  /// 纯本地，不联网。
  Future<void> _showChangelog() async {
    String raw;
    try {
      raw = await rootBundle.loadString('CHANGELOG.md');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新记录加载失败')),
      );
      return;
    }
    // 跳过首尾 --- 包裹的 front matter（AIGC 合规元数据，不展示给用户）
    var lines = raw.split('\n');
    if (lines.isNotEmpty && lines.first.trim() == '---') {
      final end = lines.indexWhere((l) => l.trim() == '---', 1);
      if (end != -1) lines = lines.sublist(end + 1);
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24,
          ),
          children: [for (final line in lines) _changelogLine(ctx, line)],
        ),
      ),
    );
  }

  /// CHANGELOG 轻量解析：## → 版本标题，### → 小节，- → 列表点，其余正文
  Widget _changelogLine(BuildContext ctx, String line) {
    final p = Theme.of(ctx).colorScheme;
    final t = line.trimRight();
    if (t.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: AppSpacing.s4),
        child: Text(
          t.substring(3),
          style: AppType.headline.copyWith(color: p.onSurface),
        ),
      );
    }
    if (t.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8, bottom: AppSpacing.s4),
        child: Text(
          t.substring(4),
          style: AppType.label.copyWith(color: p.primary),
        ),
      );
    }
    if (t.startsWith('- ') || t.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: _changelogInline(t.substring(2), p),
            ),
          ],
        ),
      );
    }
    if (t.startsWith('#') || t.startsWith('>') || t.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: _changelogInline(t, p),
    );
  }

  /// 行内 **加粗** 与 `代码` 的轻量处理
  Widget _changelogInline(String text, ColorScheme p) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    var cursor = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      final bold = m.group(1);
      if (bold != null) {
        spans.add(TextSpan(
          text: bold,
          style: AppType.caption.copyWith(color: p.onSurface, fontWeight: FontWeight.w600),
        ));
      } else {
        spans.add(TextSpan(
          text: m.group(2),
          style: AppType.caption.copyWith(color: p.onSurface),
        ));
      }
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: AppType.caption.copyWith(color: p.onSurfaceVariant),
      ),
    );
  }

  Future<void> _editPin(BuildContext context) async {
    final p = Theme.of(context).colorScheme;
    final pinCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page, 0, AppSpacing.page,
          AppSpacing.s24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _hasPin ? '设置新密码（6 位数字）' : '设置密码（6 位数字）',
              style: AppType.headline.copyWith(color: p.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: pinCtrl,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: AppType.title.copyWith(color: p.onSurface),
              decoration: const InputDecoration(labelText: '密码'),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('保存'),
            ),
            if (_hasPin)
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  '关闭密码锁',
                  style: AppType.label.copyWith(color: p.error),
                ),
              ),
          ],
        ),
      ),
    );
    if (ok == null) return;
    final repo = ref.read(settingsRepoProvider);
    final gate = ref.read(lockGateProvider);
    if (ok) {
      final pin = pinCtrl.text.trim();
      if (pin.length != 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('必须是 6 位数字')),
          );
        }
        return;
      }
      final hash = sha256Hex(pin);
      await repo.set('lock_pin_hash', hash);
      // LockGate 只在启动时读库：这里必须同步内存态，否则本次进程内锁不生效。
      // 立即上锁并跳锁屏（输一次刚设的 PIN），后台切回即受保护。
      await gate.load(hash);
      gate.unlocked = false;
      if (mounted) ref.read(routerProvider).refresh();
    } else {
      await repo.set('lock_pin_hash', '');
      await gate.load('');
      if (mounted) ref.read(routerProvider).refresh();
    }
    _check();
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      title: '导入数据会覆盖当前内容',
      message: '当前所有日记、备忘、日程会被替换为备份文件里的内容，无法撤销',
    );
    if (!confirmed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在导入…')),
    );

    try {
      // 导入前强制快照当前数据：覆盖不可逆，留一条后悔路
      try {
        await ref.read(autoBackupProvider).runNow();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导入前备份失败，已取消导入：$e')),
          );
        }
        return;
      }
      final result = await ref.read(backupProvider).importFromJsonFile();
      // 导入覆盖了日程实例：已排闹钟还是旧数据的，必须全量重建
      await ref.read(reminderWarningsProvider.notifier).syncNow();
      // 导入会覆盖 settings（含提醒/自动备份配置）：刷新本页状态
      await _check();
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '导入完成：${result.diaries} 篇日记、${result.notes} 条备忘、${result.schedules} 个日程',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    }
  }

  Future<void> _importFullBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      title: '从完整备份恢复会覆盖当前内容',
      message: '当前所有日记、备忘、日程、媒体引用会被替换，恢复前会先自动快照',
    );
    if (!confirmed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在恢复（解包媒体 + 导数据），请稍候…')),
    );

    try {
      // 恢复前强制快照当前数据（与手动导入同一纪律）
      try {
        await ref.read(autoBackupProvider).runNow();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('恢复前备份失败，已取消恢复：$e')),
          );
        }
        return;
      }
      final result = await ref.read(backupProvider).importFullBackup();
      await ref.read(reminderWarningsProvider.notifier).syncNow();
      await _check();
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '恢复完成：${result.diaries} 篇日记、${result.notes} 条备忘、'
              '${result.schedules} 个日程、${result.media} 个媒体文件',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：$e')),
        );
      }
    }
  }
}

enum ThemeModeOption {
  system, light, dark;

  ThemeMode toThemeMode() => switch (this) {
        ThemeModeOption.system => ThemeMode.system,
        ThemeModeOption.light => ThemeMode.light,
        ThemeModeOption.dark => ThemeMode.dark,
      };

  static ThemeModeOption from(ThemeMode m) => switch (m) {
        ThemeMode.system => ThemeModeOption.system,
        ThemeMode.light => ThemeModeOption.light,
        ThemeMode.dark => ThemeModeOption.dark,
      };
}
