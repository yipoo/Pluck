# Pluck

> **一句话**:Mac 上隐私优先的截图 + OCR + 剪贴板套件,所有数据本地处理,数据不上云。
>
> 🏷️ 项目代号已升为正式名 **Pluck**(2026-04-26)。

## 它是什么

[MARKET_RESEARCH.md](MARKET_RESEARCH.md) 中 **#3** 切入点的实现 — Mac 端隐私优先的 OCR / 截图 / 剪贴板全能工具,定位"PixPin 进阶版":差异化 = **全本地处理 + 一站式工作流**。

目标用户:Mac 重度用户(知识工作者、设计师、开发者、律师、医生);v1 仅 Mac,Windows 列入 v2 路线图。

## 仓库导航

```
pluck/
├── README.md                     ← 你现在在这
├── MARKET_RESEARCH.md            ← 市场调研底稿(12 候选 + Top 3)
├── HANDOFF.md                    ← 交接文档:已完成 vs 待用户操作
├── docs/
│   ├── PRD.md                    ← 产品需求文档(MVP 范围、用户故事)
│   ├── TECH_DESIGN.md            ← 技术选型与架构
│   ├── ROADMAP.md                ← 8 周冲刺计划(W1-W7 已落代码,W8 待你)
│   └── SETUP.md                  ← Xcode 工程搭建 + 签名 + 发布指南
├── Package.swift                 ← Swift Package(零外部依赖)
├── Sources/Pluck/
│   ├── App.swift                 ← @main + AppDelegate
│   ├── AppState.swift            ← 全局状态 + 主链路编排
│   ├── Services/
│   │   ├── HotkeyManager.swift   ← Carbon 全局热键
│   │   ├── ScreenCaptureService.swift  ← ScreenCaptureKit 截图
│   │   ├── OCRService.swift      ← Vision OCR(中英文)
│   │   ├── ClipboardMonitor.swift ← 0.5s 轮询监听 NSPasteboard
│   │   ├── Storage.swift         ← SQLite3 持久化(纯系统)
│   │   ├── SettingsStore.swift   ← UserDefaults 设置
│   │   └── NotificationService.swift ← 系统通知
│   ├── Models/
│   │   ├── ClipboardItem.swift
│   │   └── Snapshot.swift
│   └── Views/
│       ├── MenuBarContentView.swift
│       ├── HistoryView.swift
│       ├── HistoryWindowController.swift
│       ├── RegionSelectionView.swift
│       ├── RegionSelectionController.swift
│       ├── SettingsView.swift
│       ├── OnboardingView.swift
│       └── OnboardingWindowController.swift
└── Tests/PluckTests/PluckTests.swift   ← 13 个测试,全绿
```

## 快速开始

```bash
# 1. 验证环境(需要 Xcode 15+ / macOS 14+ / Swift 5.9+)
swift --version

# 2. 构建
swift build

# 3. 运行(开发模式;会显示 Dock 图标 — 正式发布需 Xcode App Target,见 SETUP.md)
swift run Pluck

# 4. 跑测试(13 个,全绿)
swift test
```

完整发布步骤(Xcode App Target、签名、公证、DMG)见 [docs/SETUP.md](docs/SETUP.md)。

## 当前进度(v0.1.0-dev)

| 阶段 | 状态 | 备注 |
|------|------|------|
| 市场调研 | ✅ | [MARKET_RESEARCH.md](MARKET_RESEARCH.md) |
| PRD + 技术设计 | ✅ | [docs/](docs/) |
| 项目骨架 + git init | ✅ | commit `60adbdd` |
| 改名 Snap → Pluck | ✅ | commit `a2aa6aa` |
| **Sprint 1-3 (W1-W6) 代码实现** | ✅ | 见 ROADMAP "进度同步" 一节 |
| **单元测试(13 个)** | ✅ | OCR / Storage / Models / Settings 全覆盖 |
| Onboarding | ✅ | 首次启动展示隐私 + 热键 + 权限三步引导 |
| **Sprint 4 (W7-W8) — Xcode 工程 / 签名 / 公证 / 发布** | 🚧 | **需要你本人操作**(见 [HANDOFF.md](HANDOFF.md)) |
| 内测发布 | ⏸ | 等 Xcode App Target + Apple Developer + 官网 |

## 已实现功能(v0.1.0 MVP)

- ✅ 全局热键 ⌃⌥A 区域截图 → OCR → 剪贴板(端到端打通)
- ✅ 全局热键 ⌃⌥V 打开剪贴板历史窗口
- ✅ 区域选择 overlay(SwiftUI + NSWindow,ESC 取消)
- ✅ Apple Vision OCR(中英文,完全本地)
- ✅ NSPasteboard 0.5s 轮询监听 + SQLite3 持久化
- ✅ 历史搜索(LIKE 子串,支持中文)
- ✅ 设置面板:通用 / 热键 / 隐私 / 关于 4 Tab
- ✅ 首次启动 3 步 Onboarding(隐私承诺 / 热键 / 权限)
- ✅ 系统通知(OCR 完成提示)
- ✅ 启动项(SMAppService,需 .app bundle 才生效)
- ✅ 严格离线开关(隐私优先,默认开)

## 关键技术决策

- **平台**:v1 仅 macOS 14+;Windows 推迟到 v2
- **依赖**:**零外部依赖** — 仅用 Apple 系统框架(SwiftUI / AppKit / Carbon / ScreenCaptureKit / Vision / SQLite3 / UserNotifications)
- **OCR**:Apple Vision(免费、原生、中文质量好)
- **存储**:系统 SQLite3 直接调用(无 GRDB);未来按规模再升级 FTS5
- **全局热键**:Carbon `RegisterEventHotKey`(无需 Accessibility)
- **分发**(用户决策):**自有官网下载 + 海外公司主体**(绕开 ICP 备案)
- **商业模式**(用户决策):¥98 买断 + ¥48/年 Pro 订阅 + ¥298 终身

详细见 [docs/TECH_DESIGN.md](docs/TECH_DESIGN.md)。

## 你接下来要做什么

读 [HANDOFF.md](HANDOFF.md) — 它列出:
- 已经写好的代码可以直接 `swift build && swift run` 验证
- 你需要在 Xcode 里做的事(创建 App Target、配 Info.plist + entitlements + Privacy + Icon)
- 注册 Apple Developer + 签名 + 公证 + DMG + 官网 + 内测的步骤
