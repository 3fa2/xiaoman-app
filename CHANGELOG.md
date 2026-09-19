---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: '82b21085-177b-4ea5-be24-85bccc20deb5'
  PropagateID: '82b21085-177b-4ea5-be24-85bccc20deb5'
  ReservedCode1: 'bc254d8c-ac39-44cc-9b3d-3365336c4be4'
  ReservedCode2: 'bc254d8c-ac39-44cc-9b3d-3365336c4be4'
---

# CHANGELOG — 三位一体 v4

## v4.2.0+14（2026-09-19）· 真机体验反馈全量改造

**产品定位决策**：主打「日记 + 心情」（做细做深），备忘/日程做辅助（够用即停）。
依据：v4 的 P0-1 是日记编辑器，实况照片/心情体系均为日记服务，App 命名以日记居首。

### 一、快速见效（样式与反馈）

- **FAB 按页区分**：日记页 ✍️notePencil / 备忘页 📁folderPlus / 笔记列表 ✏️pencilSimple / 日程页 📅calendarPlus，全部走统一 AppFab 组件（weight 1.5 + tooltip），一套设计不再"两套拼接"
- **日历选中高亮**：primary 实底圆 + 白字（原 primaryContainer 太浅看不出选中），今天加主色描边圈
- **心情打卡选中**：选中 chip 心情色描边 + 加粗 + ✓ 图标，打卡结果一眼可见
- **小字按钮统一**：新增 TextActionButton（AppType.label + primary + ›箭头），"全部/去日程"不再忽大忽小
- **空态引导**：EmptyState 支持快捷示例 chips——备忘空页一键建「灵感/待办/读书笔记」笔记本，日程空页一键加「晚上复盘/午休」时间块

### 二、核心体验

- **首页总览**：加「今日日程」区块头（完整列出今日剩余，不再只 3 条）+ **近 7 天心情点带**（有记录填色、没记录空心、今天主色描边）+ 最近日记带心情点
- **日记标签（新功能）**：schema v2 加 tags 列（csv，onUpgrade addColumn 保留旧数据）→ 编辑器标签 chips（+底部弹窗添加，实体未建时暂存首存后补写）→ 详情页显示 → 搜索页标签 FilterChip 过滤 → LIKE 搜索覆盖标签
- **统计入口说明**：日记页右上角图标改为带文字的「心情统计」按钮
- **备忘待办**：修复"新建笔记时待办清单整块隐藏"的入口 bug——新建即可输入，第一条待办自动创建笔记实体（复用日记编辑器 _ensureEntityId 模式）；入口文案改「待办清单（可打勾）」
- **备忘全局搜索**：新增 /notes/search 全局搜索页（跨笔记本搜标题/正文/标签），入口在备忘主页 AppBar 放大镜
- **日程拖拽**：时间轴块长按竖直拖动改时间（15 分钟吸附 + 顶部时间提示浮层 + 拖动中主色描边），保留时长与提醒提前量，模板实例自动分离

### 已有但易被忽略的功能（本轮只是更显眼，非新增）

- 日记插图/实况照片（编辑器工具栏相机）、编辑器内选心情（「记个心情」行）、笔记本颜色（5 色）、日程提醒（编辑页「提前 X 分钟」chips）、时间轴视图、重复模板

### 质量与发版

- 测试 **48/48 全过**（新增 1 项：日记标签 setTags 落库 + csv 读回 + 标签搜索）
- `dart analyze` 0 error / 0 warning（8 条 info 与基线相同）；架构检查 0 违规
- schemaVersion 1→2（diaries 加 tags 列，旧数据保留）
- APK 验签 CN=Trinity；交付副本 `E:\DeepSeek\apk\三位一体-v4.2.0.apk`

## v4.1.0+13（2026-09-19）· 真机反馈热修

用户真机反馈两项修复：

- **日记日历星期标签被裁切**：`diary_calendar_screen.dart` 的 TableCalendar 未传 `daysOfWeekHeight`，默认 16.0 装不下中文"周X"两字标签导致垂直裁切 → 加高至 30
- **生物识别不可用**：`MainActivity.kt` 继承 `FlutterActivity`，而 local_auth 的 Android 实现要求宿主为 `FlutterFragmentActivity`（否则抛 no_fragment_activity 且异常被锁屏 UI 静默吞掉）→ 改继承 `FlutterFragmentActivity`
- 版本号规则生效：pubspec.yaml 与 android/local.properties 同步递增（4.1.0+13）
- 测试 47/47 全过；APK 验签 CN=Trinity；交付副本 `E:\DeepSeek\apk\三位一体-v4.1.0.apk`

## v4.0.0+12（2026-09-19）

本次为 **v4 全量重做**（对应《落地方案.md》《详细方案.md》两份方案的执行记录）。
工作区：`E:\DeepSeek\apk\trinity`（新项目）· 参考旧项目：`E:\trinity_build`（v3.0.0+11，已打 tag `v3.0.0-final-freeze` 冻结）。

### 已验证（构建级 + 单元测试级）

**M0 环境与安全网**
- JDK 17 已就位（Eclipse Adoptium 17.0.20，进程级 JAVA_HOME，未改系统设置）
- 旧项目打 tag `v3.0.0-final-freeze`；签名密钥备份至 `E:\DeepSeek\apk\_backup\`
- 工具链：Flutter 3.47.4 / Dart 3.13.3 / Gradle 8.14.3 / AGP 8.12.0 / Kotlin 2.2.20（对齐 v3 已验证组合）

**M1 设计真源（`lib/design/`）**
- `tokens.dart`：雾蓝主色 #3D6B8E（浅）/ #7FA8C9（深）+ 冷中性灰骨架；禁纯黑纯白；圆角 4 档（8/12/18/28）；间距 4pt 基准；字号 6 档补全行高字距；心情色 8 预设（饱和度 0.32，不再整圈彩虹）；笔记本色 5+primary；日程色 4 个低饱和
- `theme.dart`：M3 去默认化 ThemeData（AppBar 无阴影不染色、卡片 1px hairline 描边无阴影、输入框 label 常驻上方、PredictiveBackPageTransitionsBuilder、底部导航 64 高 primarySoft 药丸）
- `motion.dart`：M3 motion token（100/150/250/300/420/40ms）+ 标准曲线 + 动效纪律清单 + reduceMotion 降级

**M2 数据层（`lib/data/`）**
- Drift 10 表：diaries/moods/media_items（统一媒体表 ★）/notebooks/notes/todo_items/schedule_templates/schedule_instances/drafts/settings
- FTS5 全文索引（external content + 触发器同步；≥3 字 MATCH，短词回退 LIKE）
- WAL checkpoint 工具（导出备份前必须 checkpoint，NotallyX 教训）
- schema 可自由重构（旧数据不保留，无迁移包袱）

**M3 P0-1 自动保存重做（`lib/domain/services/autosave_controller.dart`）★ 最高优先级**
- 保存逻辑脱离 Widget：构造注入 repo，不依赖 BuildContext/ref，dispose 后依然可完成
- Mutex 串行防重入（synchronized 包 Lock）+ 整实体脏检查（无变化不写库）
- flush() 可 await：PopScope 退出守卫（保存中不许走，dirty 先 flush 再 pop）
- 生命周期兜底：inactive/paused 立即落库（不再依赖 dispose）
- 最小长度护栏（防"没加载完就覆盖成空"）+ 草稿表兜底（崩溃可恢复，成功后清除）
- UI 状态机五态：idle/dirty/saving/saved/error —— **保存失败必须可见，UI 绝不撒谎**

**M4 P0-2 日程提醒可靠性（`lib/data/services/notification_service.dart` + Kotlin 原生件）**
- Manifest 补齐：SCHEDULE_EXACT_ALARM + USE_EXACT_ALARM + RECEIVE_BOOT_COMPLETED
- 三层可靠性：① 插件 zonedSchedule（exactAllowWhileIdle）② 原生 AlarmPersistence（SharedPreferences JSON）+ BootReceiver 在 重启/更新/时间变更/时区变更/日期变更 后重建 ③ App 启动 syncAll() 全量重建（uhabits #1509 兜底）
- 权限不可用降级 inexactAllowWhileIdle + UI 警告条，不静默失败
- 时区跟随系统（不再写死 Asia/Shanghai）
- vivo 专项：设置页中文引导卡片（自启动/后台高耗电/不受限电池/锁定后台），诚实告知厂商限制无法绕过

**M5 P0-3 实况照片（`lib/data/services/live_photo_importer.dart`）**
- 统一模型 LivePhoto{coverImagePath, videoPath}，两种形态导入归一：
  - vivo 双文件（X200 Pro mini 主力形态）：同目录同名 .mp4 直接配对
  - 标准单文件 Motion Photo（GCamera:MotionPhoto / MicroVideo V1）：XMP 解析 + videoOffset = size - Length + ftyp 校验 + EOI 兜底搜索，拆出视频
- 播放 = 长按直接播自己的 mp4（完全绕开格式地狱）
- 列表只渲染 coverPath，Image.file 带 cacheWidth（性能纪律）

**M6 表现层全部重做（14 页面 + 共享组件库）**
- 底部 4 tab（StatefulShellRoute.indexedStack 保活）+ Fade-Through 转场
- 页面转场：PredictiveBackPageTransitionsBuilder（Android 15 侧滑返回跟手渐显）
- Hero 共享元素：日记卡片 → 详情（tag: diary-cover-{id}）
- StaggeredEntrance 列表入场（级联 40ms 最多 6 项，仅首次播放）
- PressableScale 按压反馈（scale 0.98，reduceMotion 降级为无 scale）
- 日程时间轴：0-24h Stack+Positioned、重叠块贪心分列、当前时间线、完成划线
- 每屏空态/加载态（骨架）/错误态齐全；心情色/笔记本色/日程色只在数据组件内出现

### 测试与质量

- **45/45 测试全过**，其中硬门禁：
  - 测试 A：输入 → 立刻 pop（flush await）→ 内容还在 ✓
  - 测试 A2：保存中到达的第二次输入合并保存（防重入）✓
  - 测试 C：Repository 抛异常 → 状态必须是 error，绝不 saved ✓
  - 测试 C2：失败后草稿仍在（可恢复）✓
  - 测试 D：空编辑器退出不产生垃圾记录 ✓
- rrule 8 项（DAILY/WEEKLY/MONTHLY 第n个周几/MONTHLY 某日/YEARLY/EXDATE/窗口裁剪/build）
- 生成引擎 7 项（幂等/skip-on-conflict/detach 保留/禁用模板/shouldDrop/exdates）
- 实况照片 3 项（vivo 双文件/MicroVideo 单文件拆解/普通图 null）
- 仓储 15 项（CRUD/FTS5 中英/软删联动/detach 语义/EXDATE/级联删除）
- 架构检查 `dart run tool/check_architecture.dart`：**0 违规**
  - domain 禁 Flutter ✓ features 禁直连 data ✓ features 禁裸色值 ✓
  - **v3 的行数契约（单文件≤300行/build≤80行/函数≤50行）已废除**
- `dart analyze`：0 error / 0 warning，剩 8 条 info（2 条 deprecated API 提示、4 条 BuildContext 异步间隙提示、2 条未使用变量类），不影响构建与运行，后续清理

### 发版

- 版本 4.0.0+12 · applicationId **com.trinity.app**（新包名，与 v3 是两个独立 App，v3 需手动卸载）
- 签名：`trinity-release.keystore`（CN=Trinity，SHA-256 732a14bf...，与 v3 同钥）
- APK：`build/app/outputs/flutter-apk/app-release.apk`（71.7MB），交付副本 `E:\DeepSeek\apk\三位一体-v4.0.0.apk`

### 未实测项（无真机，诚实声明）

- 真机提醒：5 分钟后响 / 重启后仍响（代码三层兜底已实现 + 测试通过，但需真机验证）
- 实况照片真机导入：F 盘 1469 组双文件样本未在真机走通全链路
- 预测式返回跟手渐显 / 120Hz 帧时间（DevTools 截图）——需真机 + `flutter run --profile`
- vivo 后台保活实测
- 锁屏生物识别真机验证

> AI生成