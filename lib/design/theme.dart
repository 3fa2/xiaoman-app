import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'tokens.dart';

/// M3 去默认化：浅深双主题，全部走 tokens。
/// 反 AI-tell：AppBar 无阴影不染色、按钮对比度 AA、无纯黑纯白。
ThemeData buildAppTheme(Palette p, {required bool dark}) {
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primarySoft,
    onPrimaryContainer: dark ? p.ink : p.primary,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    surface: p.canvas,
    onSurface: p.ink,
    surfaceContainerHighest: p.canvasAlt,
    onSurfaceVariant: p.inkSoft,
    outline: p.hairline,
    outlineVariant: p.hairline,
    error: p.danger,
    onError: dark ? const Color(0xFF241110) : const Color(0xFFFDF6F5),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.canvas,
    splashFactory: InkSparkle.splashFactory,
    // Android 14+ 预测式返回：上一个页面跟手渐显（决策：预测式返回优先于自定义 Shared Axis）
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      displaySmall: AppType.display,
      titleLarge: AppType.title,
      titleMedium: AppType.headline,
      bodyMedium: AppType.body,
      bodySmall: AppType.label,
      labelSmall: AppType.caption,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: p.canvas,
      foregroundColor: p.ink,
      centerTitle: false,
      titleTextStyle: AppType.title.copyWith(color: p.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: p.canvas,
      indicatorColor: p.primarySoft,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(AppType.caption.copyWith(color: p.inkSoft)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? p.primary : p.inkFaint,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.rLg),
        side: BorderSide(color: p.hairline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.canvasAlt,
      // label 常驻输入框上方，禁止 placeholder 当 label
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPad, vertical: AppSpacing.s12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.rMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.rMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.rMd),
        borderSide: BorderSide(color: p.primary, width: 1.5),
      ),
      hintStyle: AppType.body.copyWith(color: p.inkFaint),
      labelStyle: AppType.label.copyWith(color: p.inkSoft),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rSm)),
      side: BorderSide.none,
      backgroundColor: p.canvasAlt,
      selectedColor: p.primarySoft,
      labelStyle: AppType.label.copyWith(color: p.inkSoft),
      secondaryLabelStyle: AppType.label.copyWith(color: p.primary),
    ),
    dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.rXl)),
      ),
      showDragHandle: true,
      dragHandleColor: p.hairline,
      dragHandleSize: const Size(36, 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rLg)),
      titleTextStyle: AppType.headline.copyWith(color: p.ink),
      contentTextStyle: AppType.body.copyWith(color: p.inkSoft),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.ink,
      contentTextStyle: AppType.label.copyWith(color: p.canvas),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rMd)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        textStyle: AppType.label,
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rMd)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        textStyle: AppType.label,
        side: BorderSide(color: p.hairline),
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rMd)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: AppType.label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rMd)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rLg)),
      elevation: 2,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.inkFaint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.primary : p.canvasAlt,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.primary : Colors.transparent,
      ),
      side: BorderSide(color: p.inkFaint),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.rSm / 2)),
    ),
  );
}

/// table_calendar 取色载体（该包参数散装，统一在此收敛，页面直接构造使用）
class CalendarThemeData {
  final Color background, header, selectedFill, selectedText, todayFill;
  final Color dayText, weekdayText, outsideText, hairline;
  const CalendarThemeData({
    required this.background,
    required this.header,
    required this.selectedFill,
    required this.selectedText,
    required this.todayFill,
    required this.dayText,
    required this.weekdayText,
    required this.outsideText,
    required this.hairline,
  });
}
