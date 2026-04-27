# HANDOFF — Pluck v0.1.0 交接文档

**起草时间**:2026-04-27
**当前 git HEAD**:Sprint 1-3 代码完成,等待你接手 Sprint 4(工程化 / 发布)

---

## 0. 现在能做什么(立即验证)

```bash
cd /Users/dinglei/MyClaude/pluck
swift build       # 干净通过
swift test        # 13/13 通过(含 OCR、Storage CRUD、Settings 等)
swift run Pluck   # 启动菜单栏 App(开发模式)
```

⚠️ `swift run` 模式下**会显示 Dock 图标**(因为没有 Info.plist 的 `LSUIElement`);全局热键、屏幕录制权限、系统通知**也大概率失效**(因为没有正式 bundle id)。这些都需要 Xcode App Target 才能正常工作 — 这是 macOS 的限制,不是代码 bug。

---

## 1. 已完成的代码(零外部依赖)

### Services 层(纯逻辑,可单测)

| 文件 | 实现内容 | 关键 API |
|------|---------|---------|
| `HotkeyManager.swift` | Carbon `RegisterEventHotKey` 全局热键 + Combo 类型 + 显示串 | `Carbon.HIToolbox` |
| `ScreenCaptureService.swift` | ScreenCaptureKit 截屏 + 单显示器区域抓图 + Retina 缩放 + 权限检查 | `ScreenCaptureKit.SCScreenshotManager` |
| `OCRService.swift` | Apple Vision 异步 OCR + 中英文配置 + TextBlock 结构化结果 | `Vision.VNRecognizeTextRequest` |
| `ClipboardMonitor.swift` | 0.5s 轮询 NSPasteboard + 跳过自己写入 + 跳过 ConcealedType | `NSPasteboard` |
| `Storage.swift` | 系统 SQLite3 直调 + 表结构 + LIKE 子串搜索 + 数量限制 + 测试用 init | `import SQLite3` |
| `SettingsStore.swift` | UserDefaults 持久化 + Combo JSON 编码 + Combine 发布 | `UserDefaults` |
| `NotificationService.swift` | UNUserNotificationCenter 封装(OCR 完成、错误) | `UserNotifications` |

### Views 层

| 文件 | 内容 |
|------|------|
| `MenuBarContentView.swift` | 菜单栏弹窗:截图/历史/设置/退出 + 状态行 |
| `HistoryView.swift` | 双 Tab(剪贴板/截图)+ 防抖搜索 + 单击复制 + Finder 跳转 |
| `HistoryWindowController.swift` | 管理历史 NSWindow 生命周期 + toggle |
| `RegionSelectionView.swift` | 全屏蒙层 + 拖动选区 + 尺寸标签 + 中央提示 |
| `RegionSelectionController.swift` | borderless OverlayWindow + ESC 取消 |
| `SettingsView.swift` | 4 Tab:通用 / 热键 / 隐私 / 关于 + 清空确认弹窗 |
| `OnboardingView.swift` | 3 步引导:隐私承诺 → 热键 → 屏幕录制权限 |
| `OnboardingWindowController.swift` | 首次启动展示 |

### App 编排

| 文件 | 内容 |
|------|------|
| `App.swift` | `@main` SwiftUI App + AppDelegate + 通知权限请求 + bootstrap 钩子 |
| `AppState.swift` | 全局状态 + 服务实例化 + 主链路(captureRegion / handleClipboard / refreshHistory)+ 热键变更监听 |

### 测试(13 个,全绿)

| 测试 | 验证 |
|------|------|
| `testClipboardItemEncodingRoundtrip` | 模型 JSON 编解码 |
| `testSnapshotInit` | 模型默认值 |
| `testAppStateInitialization` | AppState 初始状态(MainActor) |
| `testStorageDirectoryCreation` | 目录创建 |
| `testStorageInsertAndReadClipboard` | INSERT + SELECT |
| `testStorageFTSSearch` | LIKE 中文搜索("调研" / "隐私") |
| `testStorageEnforceClipboardLimit` | DELETE 超额最旧 |
| `testStorageClearAll` | 清空 |
| `testStorageInsertAndReadSnapshot` | snapshot CRUD + annotations BLOB |
| `testHotkeyDescriptorDisplayString` | "⌃⌥A" 字符串 |
| `testHotkeyDescriptorEncodingRoundtrip` | 设置编解码 |
| `testOCRRecognizesRenderedEnglish` | 程序渲染图 → Vision 识别 → 文字校验 |
| `testOCRReturnsEmptyForBlankImage` | 空图返空 |

### 主链路(端到端工作流)

```
用户按 ⌃⌥A
  → HotkeyManager(Carbon)触发 captureRegion
  → AppState.captureRegion()
  → RegionSelectionController 弹出全屏 overlay
  → 用户拖动选区 → 返回 CGRect
  → ScreenCaptureService.captureRegion(rect:) → CGImage
  → 写 PNG 到 ~/Library/Application Support/Pluck/snapshots/<uuid>.png
  → OCRService.recognize(image:) → 文本 + Block
  → ClipboardMonitor.writeOwn(text:) → NSPasteboard(带 ownWriteMarker 防自我捕获)
  → Storage.insertSnapshot(snap)
  → AppState.refreshHistory() → UI 刷新
  → NotificationService.ocrDone(charCount:) → 系统通知
```

---

## 2. 你接下来要做的事(Sprint 4 = W7-W8)

### 2.1 必做(发布的硬门槛)

#### A. 在 Xcode 创建 App Target(2-4 小时)

按 [docs/SETUP.md §2](docs/SETUP.md#2-阶段-b--升级为-xcode-app-项目w1-末或-w2-初) 操作。要点:

1. Xcode → File → New → Project → macOS → App
2. Product Name:`Pluck`,Bundle ID:`com.dinglei.pluck`(或你的反向域名)
3. 在 Project Settings 添加本 Package 作为 Local Package Dependency
4. App Target 的 `PluckApp.swift` 改为引用 Package(SETUP.md §2.3 有模板)
5. 把 `App.swift` 里 `PluckApp` 改名为 `PluckLibraryEntry` 或类似(避免和 Xcode 生成的 `@main` 冲突)— 或者干脆**删掉 Sources/Pluck/App.swift 的 `@main`**,把所有 Scene 抽成 `static var rootScene: some Scene { ... }` 让 Xcode App Target 调用

#### B. 配 Info.plist + entitlements(30 分钟)

按 SETUP.md §2.4 - §2.5 添加:

- `LSUIElement = YES`(隐藏 Dock 图标 — 关键!)
- `NSScreenCaptureUsageDescription` = "Pluck 需要屏幕录制权限以做截图 OCR"
- `Pluck.entitlements`:
  - `com.apple.security.app-sandbox = YES`
  - `com.apple.security.files.user-selected.read-write = YES`
  - **不要** 申请 `network.client`(产品定位是离线)

#### C. PrivacyInfo.xcprivacy(15 分钟)

新建文件,内容见 [docs/TECH_DESIGN.md §5.3](docs/TECH_DESIGN.md)。`NSPrivacyTracking = false`,`NSPrivacyCollectedDataTypes` 留空。

#### D. App Icon(1-3 小时)

用 [IconKitchen](https://icon.kitchen/) 或找设计师做。需要 1024×1024 主图 → Xcode AppIcon.appiconset 自动生成各尺寸。

#### E. 注册 Apple Developer Program($99/年,1-7 天)

https://developer.apple.com/programs/ → 填资料 → 等审核。**这是签名 + 公证的前置**。

#### F. Archive + 公证(每次 5-30 分钟)

```
Xcode → Product → Archive
  → Distribute App
  → Developer ID(Direct Distribution)
  → 上传给 Apple 公证
  → 等绿勾(5-30 分钟)
  → Export → 得到 Pluck.app
```

#### G. 打 DMG + 上传 CDN(1 小时)

```bash
brew install create-dmg
create-dmg Pluck.app
# 把 .dmg 上传到自有 CDN / 七牛 / Cloudflare R2 / GitHub Releases
```

#### H. Sparkle 自动更新接入(2-4 小时)

参考 https://sparkle-project.org/documentation/。要点:
1. 在 Xcode 加 Sparkle SPM 依赖
2. `bin/generate_keys` 生成 EdDSA 密钥对(私钥**绝不进 git**)
3. 公钥写进 Info.plist 的 `SUPublicEDKey`
4. 每次发版生成 `appcast.xml` 上传到 CDN
5. App 启动时检查更新

#### I. 自有官网(4-8 小时)

最快路径:Vercel + Astro / Next.js 静态页。最少要有:
- 首页(产品介绍 + DMG 下载链接)
- 隐私政策(明确"严格离线")
- 反馈邮箱 / Telegram / 即刻 链接

### 2.2 可选(发布后可补)

- 内测群拉 50 人(V2EX / 小红书 / 即刻 / 少数派)
- 写少数派或公众号软文
- GitHub Issues / Linear 收反馈
- 多语言(英文 / 繁中)
- HotKey 自定义录制 UI(目前只能恢复默认)
- 长截图、标注、贴图(v0.2 范围,见 PRD)

---

## 3. 待你决策的开放问题

按重要性:

| # | 问题 | 何时必须决 |
|---|------|----------|
| 1 | **Apple Developer 账号注册**(个人 vs 公司主体) | 公证前(2.1.E) |
| 2 | **海外公司主体形式**(新加坡 / 香港 / 美国 LLC) | 接 Paddle 收款前 |
| 3 | **域名**(pluck.app / pluck.cn / getpluck.com)+ 商标查询 | 官网上线前 |
| 4 | **GitHub 远端仓库**(personal vs org;public vs private) | 想跨机器开发 / CI 前 |
| 5 | **Sparkle EdDSA 密钥保管位置**(1Password / Bitwarden / 硬件密钥) | 第一次发版前 |
| 6 | **官网技术栈**(Astro / Next / 自己写) | 启动 2.1.I 时 |

---

## 4. 已知设计取舍(供你权衡)

| 取舍 | 当前选择 | 何时重新评估 |
|------|---------|-------------|
| 多显示器支持 | v1 只主显示器 | 用户反馈强烈时 |
| FTS5 全文搜索 | v1 用 LIKE(中文 tokenizer 复杂) | 历史 > 5000 条时 |
| 截屏 API | ScreenCaptureKit(macOS 12.3+) | 不重新评估 |
| 全局热键自定义 UI | v1 只能恢复默认 | v0.2 加录制 UI |
| 错误展示 | NSError + 系统通知 | 用户反馈难定位时 |
| 崩溃上报 | 不接(隐私) | v1.0 自建后再说 |
| iCloud 同步 | 不做 | v2.0 |
| AI 增强 | 不做 | v0.3 |
| 标注画布 | 不做 | v0.2 |
| 长截图 | 不做 | v0.2 |

---

## 5. 我没有做但你可能想做的事

- **CI**:`.github/workflows/ci.yml` 跑 `swift test` — 只要 push GitHub 我可以帮加
- **发布脚本**:`bin/release.sh` 自动 archive + notarize + DMG + 上传(等你 GitHub repo 就绪后)
- **Localizable.xcstrings**:简体 + 英文双语字符串目录 — 当前所有文案中文硬编码,需要改成本地化键
- **状态栏图标自定义**:用 SF Symbol 也行;有设计师可换 PNG/PDF
- **AI 增强模式开关**:目前隐私 Tab 只是显示,实际 AI 接入待 v0.3 规划

---

## 6. 异常排查速查

| 现象 | 原因 | 解决 |
|------|------|------|
| `swift run Pluck` 没菜单栏图标 | 缺 Info.plist 配置 / Dock 图标抢焦点 | 用 Xcode App Target 跑 |
| 全局热键无效 | 没正式 bundle id / 没主线程 RunLoop | 用 Xcode App Target 跑;hotkey id 冲突时改签名常量 |
| 第一次截图无反应 | 屏幕录制权限未授予 | 系统设置 → 隐私 → 屏幕录制 → 勾选 Pluck → 重启 |
| 通知不弹 | 通知权限未授予 / 非 .app bundle | 系统设置 → 通知 → 找到 Pluck → 允许 |
| `SQLite_BUSY` 错误 | 多进程同时写 db | v1 单进程不会;若你开多实例需关掉 |
| OCR 速度慢 | Intel Mac / 复杂图片 | M-系列 < 1s;Intel 慢 2-3 倍属正常 |

---

## 7. 联系人 & 资源

- 技术参考:[docs/TECH_DESIGN.md](docs/TECH_DESIGN.md)
- 产品规格:[docs/PRD.md](docs/PRD.md)
- 工程搭建:[docs/SETUP.md](docs/SETUP.md)
- 市场底稿:[MARKET_RESEARCH.md](MARKET_RESEARCH.md)

祝顺利。Pluck 的设计目标是"诚实的小工具" — 不要塞功能,不要追风口,先把 v0.1.0 推出去拿到 50 个真实用户反馈,再决定 v0.2 该做什么。
