import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'design/theme.dart';
import 'design/tokens.dart';
import 'data/services/notification_service.dart';
import 'di/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 竖屏 + 沉浸式边缘（骨架无彩色：systemNavigationBar 透明）
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const ProviderScope(child: TrinityApp()));
}

class TrinityApp extends ConsumerStatefulWidget {
  const TrinityApp({super.key});

  @override
  ConsumerState<TrinityApp> createState() => _TrinityAppState();
}

class _TrinityAppState extends ConsumerState<TrinityApp> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 启动序列：
  /// 1. 通知初始化  2. 锁屏 hash 加载  3. 日程 regenerate（滚动窗口）
  /// 4. 提醒全量重建（uhabits #1509 兜底，不阻塞首帧）
  Future<void> _bootstrap() async {
    await NotificationService.instance.init();
    final settings = ref.read(settingsRepoProvider);
    final pinHash = await settings.get('lock_pin_hash');
    await ref.read(lockGateProvider).load(pinHash);
    final scheduler = ref.read(scheduleRepoProvider);
    await scheduler.regenerate();
    unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '三位一体',
      theme: buildAppTheme(lightPalette, dark: false),
      darkTheme: buildAppTheme(darkPalette, dark: true),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
