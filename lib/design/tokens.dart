import 'package:flutter/material.dart';

/// ============================================================
/// 三位一体 v4 · 设计真源（唯一真源）
/// 总纲三条铁律：
///   ① 骨架无彩色：导航/按钮/卡片/列表/文字一律中性灰阶
///   ② 颜色只给内容：彩色只出现在心情/笔记本/日程数据组件内，绝不外溢
///   ③ 一个强调色：全 App 只有 primary 一个交互强调色
/// 页面禁止写裸色值/裸圆角/裸间距，一律引用本文件。
/// ============================================================

/// 浅深两套中性骨架色（禁纯黑 #000000 / 纯白 #FFFFFF）
@immutable
class Palette {
  final Color canvas; // 页面底
  final Color canvasAlt; // 凹陷区 / 输入框填充 / 未选中控件
  final Color surface; // 卡片 / 列表容器
  final Color surfaceAlt; // 次级卡片 / hover
  final Color ink; // 主文字
  final Color inkSoft; // 次要文字 / 图标默认
  final Color inkFaint; // 辅助文字 / 时间戳
  final Color hairline; // 1px 描边 / 分隔线
  final Color primary; // 唯一强调色（雾蓝 HSL 205° 40% 40%）
  final Color onPrimary;
  final Color primarySoft; // 选中底 / chip 底
  final Color danger;
  final Color success;

  const Palette({
    required this.canvas,
    required this.canvasAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.hairline,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.danger,
    required this.success,
  });
}

const lightPalette = Palette(
  canvas: Color(0xFFF5F6F8),
  canvasAlt: Color(0xFFEDEFF2),
  surface: Color(0xFFFBFBFC),
  surfaceAlt: Color(0xFFF0F2F5),
  ink: Color(0xFF191C1F),
  inkSoft: Color(0xFF5A6068),
  inkFaint: Color(0xFF8B9199),
  hairline: Color(0xFFE2E5E9),
  primary: Color(0xFF3D6B8E),
  onPrimary: Color(0xFFFFFFFF),
  primarySoft: Color(0xFFE3EBF1),
  danger: Color(0xFFB0554B),
  success: Color(0xFF3F6F55),
);

const darkPalette = Palette(
  canvas: Color(0xFF14171A),
  canvasAlt: Color(0xFF1A1E22),
  surface: Color(0xFF1E2226),
  surfaceAlt: Color(0xFF24282D),
  ink: Color(0xFFE7E9EB),
  inkSoft: Color(0xFFA3A9B0),
  inkFaint: Color(0xFF767C84),
  hairline: Color(0xFF2B3036),
  primary: Color(0xFF7FA8C9),
  onPrimary: Color(0xFF0E1A24),
  primarySoft: Color(0xFF233542),
  danger: Color(0xFFD08A80),
  success: Color(0xFF7FB295),
);

/// 圆角：全 App 只允许这 4 档
/// （圆形头像/心情点/勾选用 StadiumBorder，单独一类不计档位）
abstract final class AppRadii {
  static const rSm = 8.0; // chip / 标签 / 小控件
  static const rMd = 12.0; // 输入框 / 按钮
  static const rLg = 18.0; // 卡片 / 列表容器
  static const rXl = 28.0; // 底部弹窗 / 大面板
}

/// 间距：4pt 基准
abstract final class AppSpacing {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;

  static const page = 20.0; // 页面左右内边距
  static const block = 24.0; // 区块间距
  static const withinBlock = 12.0; // 区块内元素间距
  static const cardPad = 16.0; // 卡片内边距
  static const listBottom = 96.0; // 列表底部留白（避让 FAB + 底部导航）
}

/// 字号 6 档（补全行高/字距）
abstract final class AppType {
  static const display = TextStyle(
    fontSize: 28, height: 1.20, letterSpacing: -0.4, fontWeight: FontWeight.w600,
  );
  static const title = TextStyle(
    fontSize: 21, height: 1.30, letterSpacing: -0.2, fontWeight: FontWeight.w600,
  );
  static const headline = TextStyle(
    fontSize: 16, height: 1.40, fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(fontSize: 15, height: 1.60);
  static const bodyLoose = TextStyle(fontSize: 15, height: 1.75); // 日记正文
  static const label = TextStyle(
    fontSize: 13, height: 1.40, letterSpacing: 0.1, fontWeight: FontWeight.w500,
  );
  static const caption = TextStyle(
    fontSize: 11.5, height: 1.30, letterSpacing: 0.2,
  );
}

/// 心情色：8 个预设（语义 + 色相），饱和度统一 0.40。
///
/// v4.7.0：hue 重排拉开区分度（旧版平静 175/难过 210/疲惫 220 三个挤在蓝青区），
/// 饱和度 0.32→0.40 让颜色更鲜明。⚠️ 种子同步维护在 database.dart _seedMoods，
/// schema v3→v4 迁移按名字刷新已有库的预设行，两处 + 迁移共三处同步改。
///
/// 使用边界（必须遵守）：
/// 1. 只在 MoodPicker / MoodChip / MoodDot / 趋势图里用
/// 2. 绝不用于 AppBar、底部导航、FAB、按钮、标题、卡片边框
/// 3. 列表里心情只用一个小圆点 + 文字，不做整行染色
abstract final class MoodPalette {
  static const presets = <(String, double)>[
    ('开心', 50), ('期待', 130), ('平静', 190), ('感动', 330),
    ('疲惫', 260), ('难过', 215), ('焦虑', 25), ('生气', 0),
  ];

  static Color colorOf(double hue, {required bool dark}) =>
      HSLColor.fromAHSL(1, hue, 0.40, dark ? 0.56 : 0.62).toColor();

  /// 自定义心情的选色盘：色环均布 12 个色相
  static const customHues = <double>[
    0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330,
  ];
}

/// 笔记本色 / 日记本色：16 + null（跟 primary），饱和度 <= 35%。
/// v4.7.0：从 9 色扩到 16 色。⚠️ 只允许尾部追加——colorIndex 按下标存库，
/// 重排会错位已有数据。
/// 只在卡片色点/色板选择器里用。
abstract final class NotebookPalette {
  /// 0 = null（跟 primary），1-15 为预设
  static const presets = <Color?>[
    null,
    Color(0xFF7C93A8), // 雾蓝灰
    Color(0xFF7F9B84), // 鼠尾草
    Color(0xFFB08A6E), // 燕麦
    Color(0xFF9C8296), // 灰紫
    Color(0xFF8A96A8), // 岩灰
    Color(0xFFA89080), // 陶棕
    Color(0xFF7E97A0), // 灰青
    Color(0xFF9B8F7C), // 橄榄
    // ---- v4.7.0 追加（色相环补空缺区）----
    Color(0xFFB07F72), // 珊瑚
    Color(0xFFB2955A), // 琥珀
    Color(0xFF6FA285), // 松绿
    Color(0xFF79A5A0), // 湖绿
    Color(0xFF6E93BD), // 天蓝
    Color(0xFF8D85B5), // 紫藤
    Color(0xFFA87F8F), // 玫瑰
  ];

  static Color resolve(int index, {required bool dark}) {
    final base = presets[index.clamp(0, presets.length - 1)];
    if (base == null) return dark ? darkPalette.primary : lightPalette.primary;
    return base;
  }
}

/// 日程色：8 个，饱和度低，只在日程块内出现
abstract final class SchedulePalette {
  static const lightColors = <Color>[
    Color(0xFF6E8CA8), // 雾蓝
    Color(0xFF7FA08A), // 苔绿
    Color(0xFFA89380), // 陶灰
    Color(0xFF8E8AA8), // 雾紫
    Color(0xFFA8878B), // 灰玫瑰
    Color(0xFF8AA0A8), // 灰青
    Color(0xFFA89E80), // 姜黄
    Color(0xFF889BAA), // 石蓝
  ];
  static const darkColors = <Color>[
    Color(0xFF8FA9C2),
    Color(0xFF93B3A0),
    Color(0xFFB9A795),
    Color(0xFFA3A0BE),
    Color(0xFFBEA0A4),
    Color(0xFFA2B5BC),
    Color(0xFFBFB490),
    Color(0xFF9DAFBF),
  ];

  static Color of(int index, {required bool dark}) {
    final list = dark ? darkColors : lightColors;
    return list[index.clamp(0, list.length - 1)];
  }
}
