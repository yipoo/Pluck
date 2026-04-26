# Snap (代号)

> **一句话**:Mac 上隐私优先的截图 + OCR + 剪贴板套件,所有数据本地处理,数据不上云。
>
> ⚠️ `snap` 是临时代号。正式发布前需要换名 + 注册商标 / 域名。候选见 [docs/PRD.md](docs/PRD.md#命名候选)。

## 它是什么

这是 [MyClaude/MARKET_RESEARCH.md](../MARKET_RESEARCH.md) 中 **#3** 切入点的实现 — Mac 端隐私优先的 OCR / 截图 / 剪贴板全能工具,定位"PixPin 进阶版":差异化是**全本地处理 + 一站式工作流 + AI 增强**。

目标用户:Mac 重度用户(知识工作者、设计师、开发者、律师、医生);v1 仅 Mac,Windows 列入 v2 路线图。

## 仓库导航

```
snap/
├── README.md                ← 你现在在这
├── docs/
│   ├── PRD.md               ← 产品需求文档(MVP 范围、功能列表、用户故事)
│   ├── TECH_DESIGN.md       ← 技术选型与架构
│   ├── ROADMAP.md           ← 8 周冲刺计划(每周任务 + 验收标准)
│   └── SETUP.md             ← 本地开发环境搭建 + Xcode 转换指南
├── Package.swift            ← Swift Package 定义(可 swift build / swift run)
├── Sources/Snap/            ← 源码骨架(Services / Models / Views)
└── Tests/SnapTests/         ← 单测骨架
```

## 快速开始

```bash
# 1. 验证环境(需要 Xcode 15+ / macOS 14+ / Swift 5.9+)
swift --version

# 2. 构建
swift build

# 3. 运行(开发模式,会显示 Dock 图标 — 正式发布需 Xcode 项目 + Info.plist 设 LSUIElement)
swift run Snap

# 4. 跑测试
swift test
```

完整步骤(包括如何转成 Xcode 项目用于签名 / 公证 / 上架)见 [docs/SETUP.md](docs/SETUP.md)。

## 当前进度

| 阶段 | 状态 |
|------|------|
| 市场调研 | ✅ 完成([../MARKET_RESEARCH.md](../MARKET_RESEARCH.md)) |
| PRD + 技术设计 | ✅ 完成 |
| 项目骨架 + 仓库初始化 | ✅ 完成 |
| Sprint 1(Week 1-2) | 🚧 待开始 |

下一步:按 [docs/ROADMAP.md](docs/ROADMAP.md) 启动 Sprint 1。

## 关键决策记录(简版)

- **平台**:v1 仅 Mac(macOS 14+),Win 推迟到 v2
- **技术栈**:SwiftUI + AppKit + Swift Package(开发用)→ Xcode 项目(发布用)
- **OCR**:Apple Vision Framework(原生、免费、中文质量好)
- **存储**:GRDB(SQLite Swift 包装)
- **分发**:**自有官网下载 + 海外公司主体**(绕开 ICP 备案 + Mac App Store 审核束缚)
- **商业模式**:¥98 买断 + ¥48/年 Pro 订阅
- **代码仓库可见性**:暂定 private,商业产品

详情见 [docs/TECH_DESIGN.md](docs/TECH_DESIGN.md)。
