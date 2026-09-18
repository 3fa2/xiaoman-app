---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: 'e9fac10c-7430-4e84-b003-0fb1858091ca'
  PropagateID: 'e9fac10c-7430-4e84-b003-0fb1858091ca'
  ReservedCode1: 'c78f8556-95dd-4874-b926-218661eb230d'
  ReservedCode2: 'c78f8556-95dd-4874-b926-218661eb230d'
---

# DECISIONS.md — 三位一体 v4 设计与技术决策记录

> 交接说明：本文件记录 v4 重做过程中的关键取舍及理由，供后续迭代参考。
> 用户授权模式："期间要我定方向的选择最优选项"，以下决策均按方案推荐/行业惯例取最优解。

## D1 · applicationId：com.example.trinity → com.trinity.app

- 现状：v3 用脚手架默认 `com.example.trinity`，正式 App 不该用。
- 决定：改为 `com.trinity.app`。
- 代价：新旧是两个独立 App，旧 v3 需手动卸载（旧数据本来就不保留，用户已确认）。
- 保留：同一 `trinity-release.keystore`（CN=Trinity），未来同包名升级无忧。

## D2 · 主色三选一：雾蓝 #3D6B8E

方案给了三个候选（雾蓝/鼠尾草绿/石墨青），按推荐选雾蓝：安静、中性、耐看，饱和度 40% 远低于 80% 上限，符合"骨架无彩色、颜色只给内容"总纲。

## D3 · M1 视觉 gate：按推荐方案直接铺开

方案原设计为"3 屏视觉稿用户点头才铺开"。用户本次授权"选最优选项、一次性做完"，故直接按方案 §1/§2 规范全量实现，未中途等待确认。若视觉不满意，token 层（design/tokens.dart）是唯一改动点。

## D4 · 预测式返回 > 自定义 Shared Axis（二者在 Flutter 互斥）

- 方案 §2.2 要求 push/pop 用 Shared Axis，同时要求 Android 14+ 预测式返回"不做等于白做"。
- 技术事实：`CustomTransitionPage`（自定义转场）会绕过 `PageTransitionsTheme`（预测式返回载体），两者只能选一。
- 决定：统一 MaterialPage + `PredictiveBackPageTransitionsBuilder`（跟手渐显体感更强，且 Android 15 原生）。Shared Axis 转场代码保留在 motion.dart 备用（改回 CustomTransitionPage 即启用）。

## D5 · 全文搜索：FTS5 trigram 弃用，unicode61 + 短词 LIKE 回退

- trigram 分词支持中文子串但要求查询 ≥3 字符；unicode61 对中文整串分词。
- 决定：≥3 字走 FTS MATCH（unicode61 分词的英文/数字场景），中文短词回退 LIKE 全表扫（个人数据量级 ≤1 万条，可接受）。
- 注意：FTS 查询词用双引号包裹防注入（_ftsQuery）。

## D6 · 重启后提醒的可靠性：原生持久化三层兜底

- flutter_local_notifications 的闹钟在重启后失效（AlarmManager 不跨重启），插件无内置重建。
- 方案 A（纯 Dart 延迟重建）：重启后到 App 下次启动前提醒全丢，不可接受。
- 决定（三层）：
  1. Flutter 侧排插件闹钟（exactAllowWhileIdle）
  2. MethodChannel 同步计划到原生 SharedPreferences（AlarmPersistence.kt），BootReceiver 在 BOOT_COMPLETED / MY_PACKAGE_REPLACED / TIME_SET / TIMEZONE_CHANGED / DATE_CHANGED 五类事件重建（AlarmManager 原生发通知，AlarmReceiver.kt）
  3. App 启动 syncAll() 全量重建（uhabits #1509 兜底）
- 权限不可用时降级 setAndAllowWhileIdle（原生）+ inexactAllowWhileIdle（插件）+ UI 警告条。

## D7 · Drift 列名禁止与类型构造函数同名（踩坑记录）

`TodoItems` 表曾有 `TextColumn get text => text()();` —— 列名 text 与 drift 类型构造函数 text() 同名，getter 自引用导致 drift_dev 解析器把调用当 tear-off，报 `FunctionExpressionInvocationImpl is not a subtype of MethodInvocation`，生成器静默输出空壳 .g.dart。
修复：列名改 `body`。已在 schema.dart 顶部写警告注释。排查耗时较长，特此记录。

## D8 · Dart 私有成员不能跨文件的 mixin 生效（踩坑记录）

`mixin DraftMixin { AppDatabase get _db; }` 与实现类在不同文件——Dart 的 `_db` 是库私有，跨文件不匹配，导致 "Missing concrete implementations" 幽灵错误。
修复：mixin 抽象成员改公共名 `driftDb`，实现类 `AppDatabase get driftDb => _db;`。

## D9 · drift 行类与 domain 模型重名：@DataClassName 后缀 Row

Drift 生成类与 domain 纯模型（Diary/Note/Notebook/MediaItem/Draft 等）同名冲突。所有表加 `@DataClassName('XxxRow')`，repo 层做 row→model 映射，domain 层保持零 drift 依赖。

## D10 · 行数契约废除，保留架构检查

v3 的 `tool/check_architecture.dart` 强制单文件 ≤300 行 / build ≤80 行 / 函数 ≤50 行，把 theme 拆成 12 个碎片、home 拆成 6 个文件，一致性无法维护（"丑"的结构性原因之一）。
v4 废除行数契约，保留三条有架构意义的检查：domain 禁 Flutter / features 禁直连 data / features 禁裸色值。

## D11 · media 导入时机：新建未落库时先强制落一条占位记录

新建日记未保存时选媒体，媒体会挂到 id=-1 丢失关联。修复：`_ensureEntityId()` 在导入媒体前若无实体 id 则先落库（并同步 controller 基线），媒体流随 id 刷新。

## D12 · 时区：跟随系统而非写死

v3 写死 `tz.getLocation('Asia/Shanghai')`。v4 启动时按系统 UTC 偏移匹配时区库（480 分钟 → Asia/Shanghai，其余匹配同名 offset）。不引入 device_info_plus（减依赖）。

## D13 · RadioListTile / speech localeId deprecated（遗留 info）

Flutter 3.47 弃用 RadioListTile.groupValue/onChanged（改用 RadioGroup 祖先）、speech_to_text 弃用 listen(localeId:)（改用 SpeechListenOptions）。本次未迁移（info 级，不影响功能），下个小版本处理。

## D14 · 未引入的依赖与理由

- `motion_photos`（ente）：单文件路线，与双文件主力形态不匹配，弃用
- `flutter_animate` / rive / lottie：动效全部用 Flutter 内置 + animations 包，拒绝额外动画框架
- `rrule`（Dart 包）：自研 RFC5545 子集引擎（DAILY/WEEKLY/MONTHLY 第n个周几/MONTHLY 某日/YEARLY/EXDATE），更可控且零依赖
- `device_info_plus`：时区用偏移匹配即可
- GPL 代码（StoryPad 等）：只读思路，未拷代码

> AI生成