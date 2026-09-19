import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../design/tokens.dart';
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

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final hasPin = await ref.read(settingsRepoProvider).get('lock_pin_hash');
    final exact = await ref.read(notificationServiceProvider).canExact();
    final notif = await Permission.notification.isGranted;
    if (mounted) {
      setState(() {
        // 空字符串 = 已关闭锁（set('lock_pin_hash', '')），不算开启
        _hasPin = hasPin != null && hasPin.isNotEmpty;
        _exactOk = exact;
        _notifGranted = notif;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

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
                        '1. 设置 → 应用 → 三位一体 → 自启动：允许\n'
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
            child: ListTile(
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
          ),
          const SizedBox(height: AppSpacing.block),
          Center(
            child: Text(
              '三位一体 v4.0.0 · 本地数据，不联网',
              style: AppType.caption.copyWith(color: p.onSurfaceVariant),
            ),
          ),
        ],
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
      await repo.set('lock_pin_hash', sha256Hex(pin));
    } else {
      await repo.set('lock_pin_hash', '');
    }
    _check();
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
