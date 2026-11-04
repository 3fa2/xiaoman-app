import 'package:flutter/material.dart';

/// ============================================================
/// 动效体系 v4（MOTION_INTENSITY: 6）
/// 原则：丝滑 = 快 + 顺，不是长。任何转场不超过 420ms。
/// 纪律：只动 transform / opacity；动画期间禁止 setState；
///       转场靠 pageTransitionsTheme 的 DelegatedTransition（预测式返回），
///       页面内容子树零重建；reduceMotion 时全部降级。
/// ============================================================

abstract final class MotionDuration {
  static const instant = Duration(milliseconds: 100); // 按下反馈
  static const fast = Duration(milliseconds: 150); // 图标/颜色/勾选/开关
  static const base = Duration(milliseconds: 250); // 组件展开收起、chip 选中
  static const page = Duration(milliseconds: 300); // 页面转场
  static const hero = Duration(milliseconds: 420); // 共享元素 / 大面板
  static const stagger = Duration(milliseconds: 40); // 列表项级联间隔
}

abstract final class MotionCurve {
  /// M3 standard：通用，两端加减速
  static const standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// M3 emphasized decelerate：进场（快进慢停）
  static const enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// M3 emphasized accelerate：离场（慢起快走）
  static const exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// 弹簧：只用于跟手回弹与选中反馈
  static const springMass = 1.0;
  static const springStiffness = 380.0;
  static const springDamping = 30.0;
}

/// Tab 切换：Fade-Through（旧页淡出缩放 → 新页淡入）。
/// 实现：AppShell 用 PageTransitionSwitcher 包 KeyedSubtree(index)。
/// 离场 90ms exit；入场 210ms enter；总 300ms。
/// 理由：状态转换，感知"换了内容域"，不制造方向错觉。

/// 页面 push/pop：theme 里 PredictiveBackPageTransitionsBuilder（跟手渐显）。
/// 决策记录：预测式返回与自定义 Shared Axis 在 Flutter 互斥（CustomTransitionPage
/// 会绕过 theme builder），选跟手渐显（体感更强）。

/// Hero：日记卡片 → 详情。tag = 'diary-cover-{id}'，飞行 420ms。
/// 坑：Hero 子树内禁 Opacity（saveLayer）；目标页首帧必须能渲染同名 Hero；
/// 列表滚动中不触发。

/// 底部弹窗：showModalBottomSheet 自带跟手拖拽（拖动实时映射，松手按速度判定），
/// 关闭 200ms exit。不跟手的弹窗 = 卡。

/// 列表入场：fade + translateY(8→0)，180ms，级联 40ms/项，最多 6 项，
/// 仅首次播放（_hasAnimatedIn），滚动回来不重播。见 StaggeredEntrance。

/// 按压反馈：scale 1→0.98，100ms，standard。见 PressableScale。

/// 无障碍降级：MediaQuery.disableAnimationsOf(context) 为 true 时，
/// 页面转场瞬时、列表直接显示、按压只留颜色变化；拖拽跟手保留（交互非装饰）。
bool isReduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);
