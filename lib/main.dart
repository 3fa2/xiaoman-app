import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/router.dart';
import 'app/widget_sync.dart';
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
  // ★ intl 中文日期符号必须显式初始化，否则 DateFormat(.., 'zh_CN') 抛
  //   LocaleDataException（首页白屏根因）
  await initializeDateFormatting('zh_CN');
  Intl.defaultLocale = 'zh_CN';

  // release 下页面崩溃默认渲染空白；改为显示错误摘要，方便定位
  ErrorWidget.builder = (details) => _CalmErrorPage(details: details);

  runApp(const ProviderScope(child: TrinityApp()));
}

/// 兜底错误页（骨架灰阶，显示异常摘要；不引用任何可能再崩的业务代码）
class _CalmErrorPage extends StatelessWidget {
  const _CalmErrorPage({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final msg = '${details.exception}';
    final clipped = msg.length > 400 ? '${msg.substring(0, 400)}…' : msg;
    return Material(
      color: lightPalette.canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '页面出错了',
                    style: AppType.title.copyWith(color: lightPalette.ink),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    clipped,
                    style: AppType.caption.copyWith(
                      color: lightPalette.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  /// 1. 锁屏 hash 加载（决定首帧是否重定向锁屏）
  /// 2. 通知初始化  3. 日程 regenerate（滚动窗口）
  /// 4. 提醒全量重建（uhabits #1509 兜底，不阻塞首帧）
  /// 5. 小组件同步（v5.0）：订阅数据变化刷桌面小组件 + 补取小组件入口动作
  /// 每步独立容错：一步失败不影响后续
  Future<void> _bootstrap() async {
    final router = ref.read(routerProvider);
    final gate = ref.read(lockGateProvider);
    gate.onLoaded = () => router.refresh();

    String? pinHash;
    try {
      pinHash = await ref.read(settingsRepoProvider).get('lock_pin_hash');
    } catch (e) {
      // 读不到就当没设锁，不阻塞启动
    }
    await gate.load(pinHash);

    try {
      await NotificationService.instance.init();
    } catch (e) {
      // 通知不可用：日程页会显示警告条，不阻塞启动
    }
    try {
      await ref.read(scheduleRepoProvider).regenerate();
    } catch (e) {
      // 生成失败：下次打开日程页重试
    }
    unawaited(ref.read(reminderWarningsProvider.notifier).syncNow());

    try {
      WidgetSync.attach(ref);
      await WidgetSync.drainLaunchAction(ref);
    } catch (e) {
      // 小组件事务不影响启动
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '小满',
      theme: buildAppTheme(lightPalette, dark: false),
      darkTheme: buildAppTheme(darkPalette, dark: true),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
