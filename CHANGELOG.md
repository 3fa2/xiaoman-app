---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: 'db02e04a-ef7d-4963-9a83-7cc68c1899a1'
  PropagateID: 'db02e04a-ef7d-4963-9a83-7cc68c1899a1'
  ReservedCode1: '41cf4f7b-a6bf-4fa1-8706-9c7c030c66d5'
  ReservedCode2: '41cf4f7b-a6bf-4fa1-8706-9c7c030c66d5'
---

# CHANGELOG — 小满（原「三位一体」）

## v5.0.4+29（2026-10-05）· 全量代码审查修复 13 项（P1×7 + P2×4 + P3 小修）

两个并行深度审查（数据/领域/原生层 + UI 层全 50 个 Dart 文件 + 9 个 Kotlin 文件逐行通读）后集中修复：

### 高危（数据丢失 / 功能失效）
- **备份/恢复不含独立待办表**：导出 11 表漏 `todos`、导入漏清 → 换机恢复待办全丢且旧待办残留（v4.3.3 修过的"备份缺表"在新增表时复发）→ 导出补 `todos`，导入补清空 + 回插
- **删除重复日程的单个实例会复活**：走物理删除、EXDATE 是死代码，下次 regenerate 按规则重新生成 → 模板实例删除改走 `skipTemplateOccurrence`（该日记为例外，其他日期不受影响）
- **拖动/编辑过的模板实例会在原时段重复生成副本**：生成器 `ownExisting` 排除了 detached 实例，防重复只靠时间重叠冲突——拖到不重叠时段后，下次启动在原时段再生成一个块 → `ownExisting` 改为含 detach（按日期）；新增回归测试"拖走后不补生成"（修复前必红）
- **新设密码锁要等进程重启才生效**：LockGate 只在启动读库，设置页写库后不更新内存态 → 写库后同步 `gate.load()` 并立即上锁跳锁屏（输一次新 PIN）；关闭密码锁同步解除
- **小组件 pending 勾选队列永不清除**：队列里的陈旧 id 会在下次启动把用户在 App 内的取消勾选改回去 → Flutter 推送权威数据时原生侧清空队列（App 没运行时队列照常保留给 drain）
- **小组件未完成数封顶 8**：Dart 只推 8 条且原生按缓存列表 count → 推送附加真实 `count`，`TodoWidgetStore` 独立存储并在 toggle 时同步增减
- **日程日视图标记完成不重排提醒**：已完成块的闹钟照响（幽灵通知）→ `setStatus` 后补 `syncNow()`

### 中危（边缘场景）
- 导入备份后不重建提醒/小组件 → 导入成功后自动 `syncNow`
- 新建日记一进选图就创建空占位实体，取消选择留空日记行 → 改为先选完媒体再建实体（顺带消除该处 analyze 提示）
- 首页心情打卡"读"取最新带心情篇、"写"固定打当天第一篇，同日多篇时点心情看似无效 → 写入目标对齐读取逻辑
- 草稿 payload 漏转义 `\r`/`\t`：粘贴 Windows 换行内容后草稿 JSON 非法，恢复时在首个 `\r` 处截断 → 补转义

### 小修
- 日记/备忘搜索加请求序号守卫（慢查询不再覆盖新查询结果）；日记详情对已删除日记显示空态而非永久骨架屏

### 构建注
- **本机有两个 pub 缓存**：`E:\pub-cache` 内是针对 Flutter 3.47 `final IconData` 手动补丁过的 phosphor_flutter 2.1.0（9/14 补），原始缓存上的同版本包无法通过 AOT 编译 → **构建必须 `set PUB_CACHE=E:\pub-cache`**，否则 kernel_snapshot 必挂。长期解法：升级 phosphor_flutter 或把补丁固化为 fork + dependency_overrides
- 测试 59/59 全过（新增 1 个防回归）；analyze 0 error / 0 warning（10 条 info）；架构检查 0 违规；版本 5.0.4+29（pubspec + local.properties 双写）

⚠️ 未实测项（无真机，待装机复验）：换机导入备份后待办完整、删除重复日程次日不复活、拖动日程次日不重复、桌面小组件勾选/取消勾选与 App 内一致、设置 PIN 后立即锁屏

## v5.0.3+28（2026-10-04）· 小组件数据方案重做（SharedPreferences 缓存）

- **根因定位**：v5.0.0~v5.0.2 小组件直读 trinity.sqlite 始终读不到数据——drift_flutter 用 sqlite3 (dart:ffi) + WAL 模式写库，新数据在 WAL 文件里，小组件用 Android SQLiteDatabase 打开主库时可能读不到 WAL 中的最新数据；v5.0.2 虽修了路径（app_flutter/trinity.sqlite）但 WAL 问题仍在
- **方案改为 SharedPreferences 缓存**（彻底绕开 SQLite 直读）：
  - Flutter 侧待办数据变化时通过 `trinity/widget` channel 推送 JSON 到原生 SharedPreferences
  - 小组件从 SharedPreferences 读缓存数据渲染（不再直读 SQLite）
  - 勾选操作：小组件先在缓存中翻转 done（即时视觉反馈），再通过 channel 通知 Flutter 执行真正的 toggle；App 没运行时标记到待同步队列，App 下次启动时 drainPending 同步
- **修复勾选广播未注册**：Manifest 的 widget receiver 只注册了 APPWIDGET_UPDATE，缺少 ACTION_TOGGLE → 勾选广播根本没被收到；两个 receiver 都补上 ACTION_TOGGLE intent-filter
- 新增 TodoWidgetStore（SharedPreferences 存取）+ WidgetChannelBridge（Provider → Flutter channel 桥）
- 版本 5.0.3+28；测试 58/58；analyze 0 error/0 warning；架构 0 违规

⚠️ 未实测项：小组件添加后实时刷新、桌面勾选、App 没运行时勾选的待同步（待装机复验）

## v5.0.2+27（2026-10-04）· 待办页美化 + 小组件读库 bug 修复

- **修复小组件读库路径（真 bug）**：添加待办后小组件仍显示"全部完成"——根因是 drift_flutter 的 `driftDatabase(name:'trinity')` 把库存在 `getApplicationDocumentsDirectory()`（即 `/data/data/<pkg>/app_flutter/trinity.sqlite`），而小组件 Kotlin 侧用的是 `getDatabasePath()`（`databases/trinity.sqlite`），路径不对、文件不存在，查询永远为空 → Kotlin 改为多候选路径探测（app_flutter 优先 + databases 兜底），现在能正确读到 drift 写入的待办
- **待办页美化（按参考截图的形态，配色沿用雾蓝体系）**：
  - 每条待办改成"左侧装饰竖条 + 标题/截止小字 + 右侧圆形勾选框"的卡片形态；未完成竖条雾蓝、已完成竖条灰色，划线文字弱化
  - 截止日显示在标题下（今天/明天/昨天/月日，过期标红）
  - AppBar 标题加"共 N 条"计数；右上角 ⋮ 弹排序菜单（按添加顺序 / 按截止日）
- **小组件按参考截图重做样式（4x2 / 2x2）**：
  - 头部改"大数字 + 「待办」小字 + 右上圆形大[+]按钮"（[+] 圆形雾蓝底 30dp、白色加号，替代之前过小的文字加号）
  - 条目改成"装饰竖条 + 标题 + 空心圆勾选框"的圆角小卡，与待办页视觉统一
  - 浅深两套色板同步加 `widget_item_bg` / `widget_add_fg`
- 版本 5.0.2+27；测试 58/58；analyze 0 error/0 warning；架构 0 违规

⚠️ 未实测项同前：小组件真实桌面添加/勾选/刷新（路径 bug 已修，待装机复验）、待办提醒真机响铃

## v5.0.1+26（2026-10-04）· 首页 Bento 布局 + 小组件加载修复

- **首页改成 S2 Bento 布局**（沿用此前确认过的"4 版页面结构方案对比"里的第 2 版，配色仍是 v4 雾蓝、不动 token 与数据层）：
  - 全宽「此刻心情」卡：今天/昨天切换 + 近 7 天点带 + 心情快速打卡（补昨天照旧）
  - 不等高网格：左「今日日记」高卡（今日篇数 + 时间线行，空态可点新建）｜右竖排「今日日程」（剩余 N 项 + 下一项时间，点击进日程）和「待办」（未完成 N + 前两条，点击切待办 tab）
- **桌面小组件加载报错修复（真 bug）**：桌面上添加小组件显示"Problem loading widget"——RemoteViews 布局里用了裸 `<View>` 和 `<Space>`，这两类不在 AppWidget 支持的白名单里，系统加载布局直接抛异常 → 勾选圈全部改成 TextView（空文本 + 圆环 drawable），占位 Space 改成 LinearLayout；两种规格同步修复
- 版本 5.0.1+26；测试 58/58；analyze 0 error/0 warning；架构 0 违规

⚠️ 未实测项同 v5.0.0：小组件在真实桌面上的添加/勾选/刷新表现、待办提醒真机响铃、[+] 冷启动直达（本轮已修 RemoteViews 布局错误，需装机复验）

## v5.0.0+25（2026-10-04）· 独立待办 + 桌面小组件

- **底部导航改版**：首页 / 日记 / **待办** / 备忘——待办首次成为一级页面；日程从 tab 摘除（功能与数据全保留，入口在设置页「日程管理」和首页卡片，push 进入可返回）
- **独立待办**（全新功能，与备忘笔记里的清单子项无关）：
  - 新建/编辑弹窗：标题 + 截止（无期限/今天/明天/选日期）+ 提醒（到点/提前 10/30/60 分钟）
  - 待办页：筛选条（全部/进行中/已过期/今天/最近 7/已完成）+ 未完成列表 + 已完成折叠分区 + 点勾选框完成/恢复 + 长按或铅笔编辑
  - schema v5→v6：新增 todos 表（id/title/done/dueDay/remindBefore/sortOrder/createdAt/updatedAt），迁移自动建表，旧数据零影响
- **桌面小组件**（4x2 列表型 / 2x2 数字型两种规格）：
  - 4x2：未完成数 + 最近 3 条，点条目直接在桌面勾掉，[+] 快捷记一条
  - 2x2：大数字未完成数 + 最近 2 条
  - 数据通道：原生 Kotlin 直读 trinity.sqlite（同进程，WAL 并发安全）；勾选直写会触发 drift 表触发器——App 内列表自动同步刷新，反向同理
  - 刷新四路保活：App 内数据变化 / 桌面勾选 / 重启重建（BootReceiver 顺手刷）/ 每 30 分钟系统兜底
  - [+] 打开 App 直达待办页并弹出添加框（锁屏中降级为只导航）
  - 小组件事务走独立 MethodChannel `trinity/widget`；`trinity/alarms` 通道一行未动
- **待办提醒接入三层兜底**（与日程同一套可靠性设计）：
  - 截止日当天 09:00 提醒（可选提前 10/30/60 分钟），未完成的才排，完成/删除自动取消；待办变化即全量重建
  - 插件层精确闹钟 + 原生持久层（重启重建）+ 每次启动全量重建，与日程一致
  - 新通知渠道 `trinity_todo`「待办提醒」；`trinity_schedule` 渠道 id 红线未动
  - 待办通知 id 加 1000000 偏移防与日程实例撞号；原生兜底通知补 App 图标大图
- 测试日期漂移修复：repositories_test 写死 202609 月份，到 10 月必挂 → 改动态取当前月

测试 58/58 全过；analyze 0 error/0 warning；架构检查 0 违规；版本 5.0.0+25（pubspec + local.properties 双写）

⚠️ 未实测项（无模拟器/真机环境，待装机验证）：小组件在真实桌面上的添加/勾选/刷新表现、待办提醒真机到点响铃、[+] 按钮冷启动直达路径

## v4.8.0+24（2026-09-20）· 单次/时间段日程 + 日程颜色加深

- **单次日程终于能进日程表了（真 bug）**：模板选"不重复"保存后永远不显示——旧架构只认重复规则（rrule），rrule 为空的模板被生成器直接跳过，模板表连日期字段都没有 → schema v4→v5 给模板加 startDate/endDate；"不重复"现在要求选日期，生成当天一个实例
- **新增"连续几天"重复选项**：解决"中秋 25/26/27 这段时间要做的事"——原来只能"每天"（无限重复）或"不重复"（单天），没有时间段概念 → 选起止日期后每天各生成一个实例，生成器按窗口交集裁剪（跨年时间段也不会白循环）；重复规则也支持 startDate/endDate 作为可选范围过滤（UI 暂不暴露，架构就绪）
- 模板列表摘要适配：单次显示"2026年9月25日 · 单次"，时间段显示"9月25日–9月27日 · 每天"
- **日程颜色加深**：8 个日程色饱和度 0.15-0.25 → 0.38-0.45、亮度略降（用户反馈左侧分类竖条与白卡片对比度太低分不清），浅深两套同步，色相不变
- 模板编辑弹窗色板 4 色 → 8 色（原来只渲染了前 4 个，与时间块编辑器不一致）
- schemaVersion 4→5 迁移：addColumn startDate/endDate（旧数据不受影响）；旧版"不重复"模板（无日期信息）保持不生成、不崩溃，重新编辑保存选日期后即生效

测试 58/58 全过（新增 4：单次生成/连续几天/老模板兼容/重复+范围过滤）；analyze 0 error/0 warning；架构检查 0 违规；版本 4.8.0+24

## v4.7.0+23（2026-09-20）· 后台名字修正 + 颜色扩充 + 自定义心情

- **后台任务名字改「小满」**：最近任务/后台卡片一直显示"三位一体"——Flutter 把 MaterialApp.title 设为 Android 任务描述（TaskDescription），Manifest label 改了但 title 漏了 → main.dart title 改"小满"。顺带清理其余残留：测试提醒通知标题、生物识别解锁理由、设置页自启动指引、pubspec description
- **笔记本/日记本色板 9 → 16 色**：低饱和基调不变，补齐色相环空缺区（珊瑚/琥珀/松绿/湖绿/天蓝/紫藤/玫瑰）。只尾部追加——colorIndex 按下标存库，重排会错位已有数据；日记本和备忘笔记本两处色板选择器自动跟随
- **心情颜色重排 + 饱和度提升**：旧版平静 175/难过 210/疲惫 220 三个 hue 挤在蓝青区几乎分不清 → 重排为色环均布（开心 50 金黄/期待 130 绿/平静 190 青/感动 330 玫粉/疲惫 260 蓝紫/难过 215 蓝/焦虑 25 橙/生气 0 红），饱和度 0.32→0.40 更鲜明
  - schemaVersion 3→4 迁移按名字刷新已有库的预设心情 hue，升级后立即生效（无需重装）
- **自定义心情**：心情弹窗新增"＋ 自定义"入口——输入名字 + 12 色点选色相 → addMood（isPreset=false 排在预设后面）；长按自定义心情可删除（先解除日记引用再删行，预设行拒绝删除）
- 备注：用户报的"备忘的子备忘加备忘没反应"经代码复核为 v4.6.0 已修问题（onSubmitted async + await + 失败恢复输入），本轮代码未再改动，待装 v4.6.0+ 新包验证

测试 54/54 全过（新增 1：addMood/deleteMood 引用置空/预设保护）；analyze 0 error/0 warning（11 条历史 info）；版本 4.7.0+23

## v4.6.0+22（2026-09-20）· 导入数据 + 四项真机反馈修复

- **设置页新增「导入数据」**：原来只有导出没有导入，换机/重装后备份文件进不来
  - 走 Android SAF 系统文件选择器选 JSON 备份（零新依赖，MainActivity 加 trinity/backup MethodChannel：pickJsonFile/readFile）
  - 导入核心 `importFromJsonString`（可测纯方法）：清 11 表 → `Row.fromJson + insertOnConflictUpdate` 覆盖恢复 → FTS rebuild（清表后触发器不回填索引，必须手动 rebuild）→ 返回日记/笔记/日程条数统计
  - 导入前弹确认框（明示"会覆盖当前数据"），完成后 SnackBar 显示统计
  - **心情种子防丢**：旧备份/手改 JSON 缺 moods 键时心情表会被清空 → 导入后 moods 为空自动重播种 8 个预设（AppDatabase 新增 seedMoodsIfEmpty）
  - 新增 2 个回归测试：roundtrip（导出结构 JSON → 弄脏库 → 导入 → 数据完整 + FTS 可搜 + 脏数据消失）、空 JSON 容错
- **备忘编辑器标题被裁切**：同 v4.3.1 日记编辑器同款问题——浮动 label 配 InputBorder.none 被输入框上边缘裁切 → 改 hint「标题（可不填）」+ never
- **待办清单加不进**：onSubmitted 里 async 未 await，输入框清了但条目没落库 → 改 async + await + 失败恢复输入
- **日历点标识按日记有无**：原来所有日期都画点；现在有日记才显示（有心情→心情色，无心情→灰点），无日记不显示
- **首页心情打卡支持补昨天**：打卡组件加「今天/昨天」切换，昨天忘打卡可补
- 备注：用户反馈"备忘页 FAB 重叠+半个'备'字"经代码检查为正常（note_list 只有一个 FAB），疑似手机上是旧版本，待装机验证

测试 53/53 全过（新增 2）；版本 4.6.0+22（pubspec + local.properties 同步）

## v4.5.0+21（2026-09-20）· 定名「小满」+ 换包名 + 换图标

按《详细方案.md》§1.12 定稿执行（上架备案准备）：

- **应用名**：三位一体 → **小满**（取「满而未满，刚刚好」之意；Manifest label 已改）
- **包名**：com.trinity.app → **com.xiaoman.app**（applicationId + namespace + Kotlin 目录与 package 声明迁移，4 个 kt 文件；MethodChannel 标识 trinity/alarms 不变，不影响功能）
  ⚠️ 新旧是两个独立 App：装机后旧「三位一体」需手动卸载，数据不迁移（方案已确认此路径）
- **图标**：方案定稿图形「几乎满的圆 + 55° 缺口细弧」（雾蓝 #3D6B8E 单色，图形占画布 54% 落在自适应安全区）。5 套 mipmap 密度 + 自适应（anydpi-v26）+ Android 13+ 主题化 monochrome 全套替换，资源来自 E:\DeepSeek\apk\icons\android\（make_android_assets.py 产物，verify_icons.py 几何校验 16 张全过）
- 版本 4.5.0+21；测试 51/51；APK 验签 CN=Trinity（沿用原密钥，升级兼容性不变）
- 构建注：pub get 因代理离线失败 → flutter pub get --offline 用本地缓存解析后正常构建

## v4.4.0+20（2026-09-19）· 实况照片预览从 Dialog 改为页面路由

- **侧滑退出黑屏修复**：全屏预览（图片/视频）从 Dialog.fullscreen 改为标准 PageRoute。Dialog 承受不了系统预测式返回手势——侧滑时 Dialog 被瞬间 dismiss，视频画面生命周期错乱导致黑屏/错误页。页面路由走标准 pop 转场，退出动画期间画面仍在
- **打开转场动画**：fade + scale（0.88→1），250ms standard 曲线；关闭 150ms，手感自然
- **视频预览页自管 controller**：预览页 StatefulWidget 持有/初始化/释放 VideoPlayerController，不再由调用方传 controller 进来。侧滑返回时页面 dispose 自动清理，不会泄漏
- **封面占位不黑闪**：视频初始化期间先显示封面图（precache 过），初始化完成切视频，转场全程有画面
- 图片预览同样改 PageRoute + precache，转场期间图片已就绪
- 视频/图片加载失败显示占位图标，不再黑屏
- 详情页/编辑器不再持有 VideoPlayerController，调用更简洁

测试 51/51 全过；analyze 0 error/0 warning；APK 验签 CN=Trinity

## v4.3.3+19（2026-09-19）· 第二轮全库巡检（双审查通道），修复 13 处

两个并行深度审查（页面层 + 数据服务层）交叉核实，修复确认的问题：

### 高危（丢数据 / 核心功能失效）
- **笔记标签和置顶被自动保存冲掉**：EditorRepository.save（打字触发的自动保存）update 路径全量写 tags/pinned → 空标签+取消置顶覆盖原值 → update 只写标题/正文/归本，tags/pinned 不再触碰（新增回归测试）
- **重复模板的提醒永远不响**：regenerate() 插入实例漏写 remindAt（P0-2 对模板路径完全失效）→ 按"午夜+开始-提前量"公式补写（新增回归测试）
- **打完字 2 秒内退出丢编辑**：PopScope 只拦"saving"，dirty 直接放行导致 flush 永不执行 → dirty 也拦截，flush 后手动 pop（日记+备忘两个编辑器）
- **已删除日程到点仍弹通知（幽灵闹钟）**：提醒两层都只增不删 → Dart 侧 syncAll 先 cancelAll 再排；原生 setAll 先 cancel 旧持久列表的全部闹钟

### 中危（功能错误）
- 编辑日程只改标题也会清掉提醒（_remindBefore 回填 0）→ 从 remindAt 反推提前量回填
- 新建日记/笔记首存后 -1 草稿不清理 → 每次新建都弹上一篇旧草稿（恢复还会内容重复）→ 首存成功即清
- 草稿恢复正则在转义引号处截断（正文含引号恢复不全）→ 改 jsonDecode（旧正则兜底）
- 备忘编辑已有笔记时 tags/pinned 变更从不上库（_flushNote 拿不到 id）→ id 取 widget.noteId ?? _savedId
- 锁屏 PIN 验证：await 后无 mounted（生物识别先解锁时崩）+ 输入竞态（等 hash 时删键误判）→ pin 快照 + mounted 检查
- 设置页"关闭密码锁"后仍显示"已开启"（空字符串误判）→ isNotEmpty 判断
- 备忘搜索输入纯空格永远卡骨架屏 → trim 判断
- 实况照片单文件拆解写到源文件旁（无扩展名源文件会被视频字节覆写、相册目录多半不可写）→ 改写系统临时目录
- 备份缺 diary_notebooks/drafts/settings 且 schemaVersion 硬编码 → 补全三表 + 读实际版本

测试 51/51 全过（新增 2 个防回归）；analyze 0 error/0 warning；APK 验签 CN=Trinity

## v4.3.2+18（2026-09-19）· 代码巡检查出 4 个 bug

全量代码审查（近期多轮改动文件 + 危险模式扫描），修复 4 个真实 bug：

- **新建日记"先加标签/选本再打字"会丢标签和归本**：暂存的 tags/notebookId 只在"导入媒体"时补写；若用户先加标签再输入正文，自动保存首建实体时暂存内容不会落库 → onSaved 回调补写（与 _ensureEntityId 同一套逻辑）
- **纯心情打卡的日记被误标"图片日记"**：当天列表卡片占位文案未判断是否真有媒体 → 卡片重构进 FutureBuilder，按媒体有无显示"图片日记"/"心情打卡"
- **首页心情取值不稳定**：同一天写多篇日记时，打卡选中态和 7 天心情点带取"列表第一篇"的心情（顺序不保证），可能出现打卡显示错误/点带颜色跳变 → 改取"最新创建且带心情的一篇"
- **视频/实况缩略图强解包可能崩**：10 处 `coverPath!`/`thumbPath!` 强解，视频无缩略图路径时 File(null) 直接崩溃 → 详情页/编辑器/列表卡片统一加 null 守卫 + 加载失败占位框 + errorBuilder
- 测试 49/49 全过；analyze 0 error/0 warning（11 条 info 为 const/deprecated 建议，不阻塞）
- APK 验签 CN=Trinity

## v4.3.1+17（2026-09-19）· 三个真机 bug 热修

- **编辑器标题被裁切**：标题输入框用浮动 label（theme 全局 FloatingLabelBehavior.always），长文案"标题（可不填，留空显示日期）"被输入框上边缘裁切只露下半截 → 改 hint 常驻 + never，输入后消失
- **实况照片点击没反应**：_play/_playLivePhoto 无容错，videoPath 为 null 或文件失效时 `File(path!)` 抛异常被吞 → 增加存在性检查 + try-catch，视频缺失/初始化失败回退全屏图片（点击必有反馈）；视频类型播放入口补回（v4.2.1 改造时误丢）；详情页实况照片加"实况"角标
- **当天列表纯图片日记空白**：卡片只渲染标题/正文/标签，纯图片日记无文字可显 → 卡片右侧加媒体缩略图（第一张 56px，视频用 thumb），无标题无正文时显示"图片日记"占位
- 测试 49/49 全过；analyze 0 error/0 warning；APK 验签 CN=Trinity

## v4.3.0+16（2026-09-19）· "大改"四项需求

用户笔记截图反馈四项，全部完成：

- **多日记本（核心新功能）**：自建分类（碎碎念/认知日记/…），schema v3 新增 diary_notebooks 表 + diaries.notebookId（旧数据保留，全部变"未归本"）。日记页左侧抽屉：所有日记/各日记本（色点+篇数）/新建，长按重命名换色或删除（删除本不删日记）。编辑器加"归入日记本"选择行；从某本点 FAB 新建自动归入该本
- **"无题"去掉**：详情页无标题时头部直接显示日期（M月d日 EEEE），不再显示"无题"；编辑器标题 label 改"标题（可不填，留空显示日期）"
- **日程"每隔几天"补回**：模板编辑下拉新增"每隔几天"（2-30 天，INTERVAL）；数据层早已支持（rrule_test 的 DAILY INTERVAL=3），是 v4 重做时 UI 丢失
- **颜色扩充**：日程色 4→8（灰玫瑰/灰青/姜黄/石蓝），笔记本色/日记本色板 5→8（陶棕/灰青/橄榄）；日程编辑颜色选择改 Wrap 自适应

测试 49/49 全过（新增日记本测试：建本+归属过滤+删除本日记变未归本）；analyze 0 error/0 warning；架构 0 违规；schemaVersion 2→3；APK 验签 CN=Trinity。

## v4.2.1+15（2026-09-19）· 实况照片预览热修

- **预览留白修复**：实况照片/视频预览从底部弹窗（上方留白近 1/3 屏、两侧灰色）改为**全屏黑底沉浸式**（Dialog.fullscreen，竖屏撑满高/横屏撑满宽，点任意处关闭），详情页与编辑器共用 showFullscreenVideo/showFullscreenImage
- **普通图片可点开全屏查看**：详情页与编辑器的图片缩略图新增 tap → 全屏查看（InteractiveViewer 双指缩放 4x）
- **提示文案条件化**：详情页底部"实况照片长按播放"原为常驻（无论有无媒体都显示），改为仅有实况照片时显示，文案更新为"实况照片点按/长按播放，图片点开可双指缩放"
- 实况照片点按/长按均可播放（原仅长按）
- 测试 48/48 全过；analyze 0 error/0 warning；APK 验签 CN=Trinity

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