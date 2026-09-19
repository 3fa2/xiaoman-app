import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/router.dart';
import '../../design/tokens.dart';
import '../../di/providers.dart';
import 'lock_hash.dart';

/// 锁屏：6 位 PIN + 生物识别 fallback。
/// PIN 的 sha256 存 settings（lock_pin_hash），LockGate 在启动时加载。
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _error = false;
  final _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: '解锁三位一体',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (ok && mounted) _unlock();
    } on PlatformException {
      // 生物识别不可用：走 PIN
    }
  }

  void _unlock() {
    ref.read(lockGateProvider).unlocked = true;
    context.go('/home');
  }

  Future<void> _onKey(String digit) async {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = false;
    });
    if (_pin.length != 6) return;
    // await 前快照：等待期间用户可能按删除键改短 _pin，导致误判
    final pin = _pin;
    final pinHash = await ref.read(settingsRepoProvider).get('lock_pin_hash');
    // await 期间可能已被生物识别解锁并跳转（widget 已 dispose）
    if (!mounted) return;
    final input = sha256Hex(pin);
    if (pinHash == input) {
      _unlock();
    } else {
      setState(() {
        _pin = '';
        _error = true;
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text('输入密码', style: AppType.title.copyWith(color: p.onSurface)),
            const SizedBox(height: AppSpacing.s8),
            if (_error)
              Text(
                '密码不对，再试一次',
                style: AppType.caption.copyWith(color: p.error),
              ),
            const SizedBox(height: AppSpacing.s24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 6; i++)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length ? p.primary : p.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            const Spacer(flex: 2),
            _Keypad(
              onKey: _onKey,
              onDelete: () {
                if (_pin.isNotEmpty) {
                  setState(() => _pin = _pin.substring(0, _pin.length - 1));
                }
              },
              onBiometric: _tryBiometric,
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onKey,
    required this.onDelete,
    required this.onBiometric,
  });

  final void Function(String) onKey;
  final VoidCallback onDelete;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme;
    Widget key(String label, VoidCallback? onTap) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.rMd),
          child: Container(
            width: 72,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadii.rMd),
              border: Border.all(color: p.outlineVariant),
            ),
            child: Text(
              label,
              style: AppType.title.copyWith(color: p.onSurface),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            key('1', () => onKey('1')),
            key('2', () => onKey('2')),
            key('3', () => onKey('3')),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            key('4', () => onKey('4')),
            key('5', () => onKey('5')),
            key('6', () => onKey('6')),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            key('7', () => onKey('7')),
            key('8', () => onKey('8')),
            key('9', () => onKey('9')),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            key(' ', null),
            key('0', () => onKey('0')),
            key('⌫', onDelete),
          ],
        ),
        TextButton(onPressed: onBiometric, child: const Text('用生物识别解锁')),
      ],
    );
  }
}
