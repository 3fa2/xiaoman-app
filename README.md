---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: 'd326edd7-92e7-4487-8ca8-2520c34d7456'
  PropagateID: 'd326edd7-92e7-4487-8ca8-2520c34d7456'
  ReservedCode1: '03f8e167-5a2e-4c7c-a4ce-cd06691c0284'
  ReservedCode2: '03f8e167-5a2e-4c7c-a4ce-cd06691c0284'
---

# 小满 · xiaoman-app

本地优先的日记 · 备忘 · 日程 Android 应用（Flutter）。

> 满而未满，刚刚好。

**纯本地存储，零网络请求，零账号体系**——数据只在你自己的手机上。

## 功能

### 日记
- 心情打卡（8 个预设 + 自定义心情/颜色，支持补记昨天）
- 多日记本归类、标签、全文搜索（SQLite FTS5）
- 日历视图（有日记的日期显示心情色点）
- 照片/视频/实况照片（Live Photo）附加，全屏预览
- 崩溃恢复草稿、自动保存（2s 去抖 + 生命周期兜底）

### 备忘
- Markdown 正文、标签、置顶、多笔记本（16 色）
- 待办清单子项（可打勾）
- 全文搜索

### 日程
- 模板 + 实例分离架构：重复规则改一次，未来实例自动重建
- 9 种重复规则：不重复（单天）/ 连续几天（时间段，如节假日）/ 每天 / 每隔 N 天 / 每周（选周几）/ 每月第 N 个周几 / 每月某日 / 每年
- 精确闹钟提醒（提前量可配），重启自动重建，国产 ROM 后台限制三重兜底
- 手动编辑的实例与模板分离（detach），skip 某天走 EXDATE 可撤销

### 通用
- 导出/导入 JSON 备份（覆盖恢复，含 FTS 重建）
- 密码锁 + 生物识别（指纹/面容）
- 浅色/深色主题，Material 3
- Android 8+ 自适应图标，Android 13+ 主题化图标

## 技术栈

| 层 | 选型 |
|---|---|
| 框架 | Flutter (Dart 3) |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 数据库 | Drift (SQLite) + FTS5 外部内容全文索引 + 触发器同步 |
| 通知/闹钟 | flutter_local_notifications + 原生 MethodChannel 精确闹钟持久化 |
| 架构 | feature-first：`lib/features/{home,diary,notes,schedule,settings}` → `domain` ← `data` |

设计约束（详见 `DECISIONS.md`）：
- 骨架无彩色，颜色只给内容（心情/笔记本/日程），一个全局强调色
- 单文件 ≤ 300 行，domain 层纯净（不 import Flutter）
- 自定义架构守护脚本：`dart run tool/check_architecture.dart`

## 构建

```bash
flutter pub get
flutter test                       # 58 个测试
dart run tool/check_architecture.dart
flutter build apk --release
```

产物：`build/app/outputs/flutter-apk/app-release.apk`

- 不需要任何 API key，克隆即构建
- `android/key.properties` 与签名密钥不入库，release 签名自行配置（参考 [Flutter 官方文档](https://docs.flutter.dev/deployment/android)）

## 项目结构

```
lib/
├── app/            # AppShell、路由表
├── design/         # 设计令牌（色板/间距/字号/动效，唯一真源）
├── di/             # Riverpod providers
├── domain/         # 纯 Dart 模型 + 仓库接口 + 服务（生成器/RRULE）
├── data/           # Drift 表 + 仓库实现 + 备份/通知服务
└── features/       # 页面（home/diary/notes/schedule/settings/shared）
```

## 隐私

- 应用声明 `INTERNET` 权限仅供调试期构建工具使用，运行期无任何网络请求
- 所有数据（日记/媒体/日程）存于应用私有目录，不上传任何服务器
- 备份文件由你自行导出保存

## License

[MIT](LICENSE)

> AI生成