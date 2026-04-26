# SETUP — 本地开发环境与 Xcode 工程搭建

本文档解释:
1. 如何在本仓库直接 `swift build` / `swift test`(快速验证代码)
2. 如何把它升级成完整的 Xcode App 项目(用于签名、公证、发布)

---

## 0. 环境要求

| 工具 | 版本 |
|------|------|
| macOS | **14.0+**(Sonoma 或更新) |
| Xcode | **15.0+** |
| Swift | **5.9+**(随 Xcode) |
| Apple Silicon Mac | 推荐(Vision OCR 性能差距 3 倍) |
| Apple Developer Program | $99/年(W7 公证前必须有) |

验证:

```bash
sw_vers
xcodebuild -version
swift --version
```

---

## 1. 阶段 A — Swift Package 模式(W1 立即可用)

### 用途

- 验证代码编译通过
- 跑单元测试
- 在 Xcode 中以 Package 形式打开,享受代码补全与重构

### 命令

```bash
cd /Users/dinglei/MyClaude/pluck
swift build         # 构建(产物在 .build/)
swift test          # 跑测试
swift run Pluck      # 运行可执行(开发期会显示 Dock 图标,正常)
```

### 在 Xcode 中打开

```bash
open Package.swift
```

Xcode 会以"Package"形式打开,可以编辑 / 构建 / 跑测试,但**不能直接 Archive 上架**。要发布必须按下面阶段 B 操作。

### 限制

- `swift run` 启动的不是真正的 .app bundle,缺少 `Info.plist` 关键键(如 `LSUIElement`),所以会显示 Dock 图标
- 不能配置 entitlements(沙盒、屏幕录制、Apple Developer Team)
- 不能签名 / 公证

---

## 2. 阶段 B — 升级为 Xcode App 项目(W1 末或 W2 初)

### 步骤

#### 2.1 在 Xcode 创建 macOS App Target

1. **File → New → Project → macOS → App**
2. Product Name:`Pluck`
3. Team:你的 Apple Developer Team(可后填)
4. Organization Identifier:`com.dinglei`(改成你自己的)
5. Bundle Identifier 自动:`com.dinglei.pluck`
6. Interface:**SwiftUI**
7. Language:**Swift**
8. 取消勾选 "Use Core Data"、"Include Tests"(我们已有 Tests/)
9. 保存到 `/Users/dinglei/MyClaude/pluck/App/`

#### 2.2 把现有 Package 作为 Local Dependency

1. 在 Xcode 项目的 **General → Frameworks, Libraries** 中点 `+`
2. **Add Other → Add Package Dependency → Add Local**
3. 选择 `/Users/dinglei/MyClaude/pluck/`(本仓库根)
4. 勾选 `Pluck` library product

#### 2.3 替换 App Target 的入口文件

把 Xcode 自动生成的 `PluckApp.swift` 内容替换为引用 Package 的 App:

```swift
import SwiftUI
import Pluck   // 我们 Package 里的库

@main
struct PluckAppMain: App {
    var body: some Scene {
        PluckAppScene()       // Package 暴露的 Scene
    }
}
```

(对应需要在 Package 里把 `App.swift` 的 Scene 抽成可复用的 `PluckAppScene`,见代码注释)

#### 2.4 配置 Info.plist

在 App Target 的 Info 选项卡添加:

| Key | Type | Value | 说明 |
|-----|------|-------|------|
| `LSUIElement` | Boolean | `YES` | 隐藏 Dock 图标(纯菜单栏 App) |
| `NSScreenCaptureUsageDescription` | String | "Pluck 需要屏幕录制权限以截图" | 屏幕录制权限弹窗文案 |
| `NSAppleEventsUsageDescription` | String | "用于剪贴板检测" | (如需)|

#### 2.5 entitlements

新建 `Pluck.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <!-- 注意:不申请 com.apple.security.network.client(隐私优先) -->
</dict>
</plist>
```

在 Build Settings → Signing → Code Signing Entitlements 指向这个文件。

#### 2.6 PrivacyInfo.xcprivacy

新建文件,内容见 [TECH_DESIGN.md §5.3](TECH_DESIGN.md)。

#### 2.7 验证

```bash
# 在 Xcode 里 Run(⌘R)
# 期望:菜单栏出现图标,Dock 无图标,App 正常运行
```

---

## 3. 阶段 C — 签名 / 公证 / 发布(W7-W8)

### 3.1 注册 Apple Developer

1. 访问 https://developer.apple.com/programs/
2. 个人 / 公司 / 组织 三选一(个人 $99/年)
3. 验证身份 + 付费(等待 1-7 天)

### 3.2 在 Xcode 配置 Signing

1. Xcode → Project → Signing & Capabilities
2. 勾选 "Automatically manage signing"
3. Team 选你的开发者账号

### 3.3 Archive + Distribute

```
Product → Archive
→ Distribute App
→ Developer ID(选 Direct Distribution)
→ 上传供 Apple 公证(Notarization)
→ 等待 5-30 分钟
→ Export
```

### 3.4 生成 DMG

用 [create-dmg](https://github.com/sindresorhus/create-dmg):

```bash
brew install create-dmg
create-dmg Pluck.app
```

### 3.5 Sparkle 自动更新

参考 https://sparkle-project.org/documentation/ ,关键步骤:
1. 添加 Sparkle SPM 依赖
2. 生成 EdDSA 密钥对(`generate_keys`)
3. 把公钥写入 Info.plist(`SUPublicEDKey`)
4. 把 appcast.xml 上传到自有 CDN
5. 每次发布更新 appcast.xml

---

## 4. 常见问题

### Q1:`swift build` 报错 "no such module 'AppKit'"

A:确保 `Package.swift` 的 platforms 字段包含 `.macOS(.v14)`。

### Q2:首次截图没反应

A:macOS 14+ 需要在 系统设置 → 隐私与安全性 → 屏幕录制 中授予 Pluck 权限,再退出 App 重启。

### Q3:Xcode 打开 Package 后看不到 App Target

A:这是预期的 — Package 模式只能跑 executable target,要发布 App 必须在 Xcode 里另建 App project(本文档 §2)。

### Q4:`MenuBarExtra` 不显示图标

A:确认 `LSUIElement = YES` 已在 Info.plist 设置;Xcode Run 时一定要从 App Target 启动,不要从 Library Scheme。

### Q5:GitHub Actions CI 失败

A:确保 runner 是 `macos-14` 或更新;Package 模式下不需要 Apple Developer 账号也能 build / test。

---

## 5. 推荐的开发循环(每天)

```
1. git pull
2. swift build && swift test          (验证基线绿)
3. 写代码 + 单测(Services 层在 Package 里)
4. 在 Xcode 里 ⌘R 跑 App,手工验证
5. git commit  (小步快跑,1-3 个文件 / 一次)
6. push(可选,在 W8 内测前不强求)
```

---

## 6. 何时该把代码 push 到远端

建议:
- **W1 初**:创建 GitHub private repo,push 当前骨架(便于跨机器开发 + 备份)
- **W7 末**:启用 GitHub Actions CI(免费 macOS minutes 够用)
- **v0.1.0 发布后**:考虑是否开源部分模块(OCR wrapper、HotKey wrapper 等)以引流
