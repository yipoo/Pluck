# 技术设计 — Pluck

**版本**:0.1
**日期**:2026-04-26
**对应 PRD**:[PRD.md](PRD.md) v0.1

---

## 1. 整体架构

```
┌────────────────────────────────────────────────────────┐
│                  macOS 14+ (Apple Silicon 优先)         │
│                                                          │
│  ┌──────────────┐                                       │
│  │  Menu Bar UI │ (SwiftUI MenuBarExtra)                │
│  └──────┬───────┘                                       │
│         │                                                │
│  ┌──────▼─────────────────────────────────────────┐    │
│  │            AppState (ObservableObject)         │    │
│  │  绑定 UI 与服务,持有 Service 实例              │    │
│  └─┬──────┬──────┬──────┬──────┬──────────────────┘    │
│    │      │      │      │      │                         │
│ ┌──▼─┐ ┌──▼──┐ ┌─▼──┐ ┌─▼──┐ ┌▼─────┐                  │
│ │Hot │ │Scrn │ │OCR │ │Clip│ │Storage│                  │
│ │key │ │Capt │ │Svc │ │Mon │ │(GRDB)│                  │
│ │Mgr │ │Svc  │ │    │ │    │ │      │                  │
│ └─┬──┘ └──┬──┘ └─┬──┘ └─┬──┘ └──────┘                  │
│   │       │      │      │                                │
│ ┌─▼───────▼──────▼──────▼─────────────────┐             │
│ │   System APIs (AppKit + Vision +         │             │
│ │   ScreenCaptureKit + Carbon + Pasteboard)│             │
│ └──────────────────────────────────────────┘             │
└──────────────────────────────────────────────────────────┘

      离线运行,不发起任何 outbound 网络请求
      (AI 增强模式由用户显式开启,默认关闭)
```

---

## 2. 技术栈选型

### 2.1 决策表

| 选项 | 选择 | 不选的原因 |
|------|------|-----------|
| **UI 框架** | **SwiftUI(主) + AppKit(系统集成)** | Tauri/Electron 原生体验差,Mac 用户挑剔;Flutter Desktop Mac 集成弱 |
| **OCR 引擎** | **Apple Vision Framework** | Tesseract 中文质量差;PaddleOCR 体积大(50MB+);Vision 是系统级,免费、原生、中文质量过得去 |
| **截屏 API** | **ScreenCaptureKit**(macOS 12.3+) | `CGWindowListCreateImage` 已标记 deprecated;ScreenCaptureKit 是 Apple 推荐方向 |
| **全局热键** | **Carbon HotKey API** + Swift wrapper | NSEvent 全局监听需 Accessibility 权限,体验差 |
| **剪贴板监听** | **NSPasteboard + 定时轮询(0.5s)** | macOS 不支持 push 模式;轮询 0.5s 是社区共识(Maccy / Pasta 都这么做) |
| **本地存储** | **GRDB.swift(SQLite 包装)** | Core Data 心智重;GRDB 类型安全 + 性能好 + 异步友好 |
| **图片缓存** | **直接磁盘 + UUID 文件名** | NSCache 内存压力大;缓存目录用 `Application Support/Pluck/` |
| **依赖管理** | **Swift Package Manager** | CocoaPods 在新项目里已不流行;SPM 是 Apple 官方 |
| **构建系统** | **swift build / swift test(开发)+ Xcode(发布)** | 开发用 Package 快;发布需 Xcode 配 entitlements / 签名 |
| **代码风格** | **swift-format**(Apple 官方) | SwiftLint 规则多易吵 |
| **CI** | **GitHub Actions** macOS runner | 备选:本地 Makefile + 云端只跑 release |
| **崩溃 / 分析** | **不接** v1(隐私优先) | Sentry/Firebase 上云,违背产品定位;v2 考虑自建 |
| **支付** | **Paddle 或 Lemon Squeezy** | 海外主体,合规简单,支持 Apple Pay |
| **自动更新** | **Sparkle 2.x** | 行业标准,签名验证完备 |

### 2.2 macOS 最低版本:14.0

理由:
- `MenuBarExtra` 需要 macOS 13+,但 13 上的实现有 bug
- `ServiceManagement` 现代 API(SMAppService)需要 13+
- `ScreenCaptureKit` 全功能需要 14+
- 14+ 覆盖率(2026 年):预估 85%+,可接受

---

## 3. 模块划分

### 3.1 Services 层(无 UI 依赖,可单测)

| 模块 | 职责 | 关键 API |
|------|------|---------|
| `HotkeyManager` | 注册全局热键、转发到 handler | `RegisterEventHotKey` / `Carbon` |
| `ScreenCaptureService` | 区域选择 + 截图 | `ScreenCaptureKit.SCStream` / `SCScreenshotManager` |
| `OCRService` | 图像 → 文字(支持多语言) | `Vision.VNRecognizeTextRequest` |
| `ClipboardMonitor` | 监听 NSPasteboard 变化 | `NSPasteboard.changeCount` 轮询 |
| `Storage` | 持久化剪贴板历史 / 设置 / 截图缓存 | GRDB + FileManager |
| `SettingsStore` | 用户偏好(热键、隐私模式) | `UserDefaults` 包装 + Combine 发布 |

### 3.2 Models 层(纯数据)

| 模型 | 字段 |
|------|------|
| `ClipboardItem` | id, content(text/image/file), kind, createdAt, sourceApp |
| `Snapshot` | id, imagePath, ocrText, annotations, createdAt |
| `HotkeyBinding` | id, action(.captureRegion / .toggleHistory / ...), keyCode, modifiers |
| `Annotation` | type(.rect / .arrow / .text / .mosaic), bounds, color |

### 3.3 Views 层(SwiftUI)

| 视图 | 职责 |
|------|------|
| `MenuBarContentView` | 菜单栏点击展开的小窗口 |
| `HistoryView` | 剪贴板历史 + 截图历史(双 tab) |
| `SettingsView` | 设置面板(快捷键、隐私、外观、订阅) |
| `RegionSelectionOverlay` | 截图时全屏蒙层 + 选择框(NSWindow level: .screenSaver) |
| `AnnotationCanvas` | 截图后的标注画布 |

---

## 4. 关键技术点深入

### 4.1 隐私 / 离线声明的"硬保证"

设计原则:**默认无任何 outbound 网络请求**。

实现:
1. 不引入任何分析 / 崩溃 / 广告 SDK
2. AI 增强模式由用户在设置里**显式开启**(默认关闭),开启时弹出明确告知
3. App Sandbox entitlement 中**不申请** `com.apple.security.network.client`(开启 AI 模式时动态申请新权限,需重启 App — 这个限制是合规上的卖点)
4. 关于页面写明"严格离线"+ 提供 Little Snitch 验证截图
5. 提供"网络活动审计"页面,显示历史所有外联记录(理想是空)

### 4.2 全局热键(Carbon)

虽然 Carbon API 旧,但仍是 macOS 上注册全局热键的最稳方案(不需要 Accessibility 权限)。社区方案:
- 自实现:基于 `RegisterEventHotKey` + `InstallEventHandler`
- 第三方:[HotKey](https://github.com/soffes/HotKey)(MIT,被广泛使用)

**MVP 选择**:用 HotKey 库,降低风险。后续视情况自实现以减少依赖。

### 4.3 截图(ScreenCaptureKit)

```
1. 用户按热键 →
2. HotkeyManager 触发 captureRegion() →
3. 创建全屏 NSWindow(level=.screenSaver, backgroundColor=半透明黑) →
4. RegionSelectionOverlay 监听鼠标拖动,绘制选择框 →
5. 鼠标松开后,使用 SCScreenshotManager.captureImage(in: rect) 抓图 →
6. 关闭 overlay,把 CGImage 传给 OCRService →
7. OCRService 异步识别后,把文字 + 图像 commit 到 Storage 与 NSPasteboard
```

注意:
- macOS 14 后 ScreenCaptureKit 需要"屏幕录制"权限,首次使用引导用户授权
- 多显示器 / Retina 缩放需正确处理

### 4.4 OCR(Vision)

```swift
let request = VNRecognizeTextRequest { request, error in
    // 处理结果
}
request.recognitionLevel = .accurate         // 准确优先(慢但好)
request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "ja-JP"]
request.usesLanguageCorrection = true
```

性能:Apple Silicon M1 上 A4 半屏中文识别 ~ 0.3-0.6 秒;Intel Mac 慢 2-3 倍。

### 4.5 剪贴板监听

```swift
// 0.5 秒轮询
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
    let current = NSPasteboard.general.changeCount
    if current != lastChangeCount {
        captureClipboard()
        lastChangeCount = current
    }
}
```

注意:
- 跳过自己拷贝的内容(用自定义 pasteboard type 标记)
- 跳过敏感内容(检查 `org.nspasteboard.ConcealedType`)
- 图片限制大小(> 50MB 跳过)

### 4.6 持久化(GRDB)

表结构:

```sql
CREATE TABLE clipboard_items (
    id           TEXT PRIMARY KEY,
    kind         TEXT NOT NULL,         -- text/image/file
    content      TEXT,                  -- text 内容或文件路径
    image_path   TEXT,                  -- 仅 kind=image
    source_app   TEXT,
    created_at   REAL NOT NULL          -- timeIntervalSince1970
);
CREATE INDEX idx_clip_created ON clipboard_items(created_at DESC);
CREATE VIRTUAL TABLE clipboard_fts USING fts5(content, content='clipboard_items');

CREATE TABLE snapshots (
    id           TEXT PRIMARY KEY,
    image_path   TEXT NOT NULL,
    ocr_text     TEXT,
    annotations  BLOB,                  -- JSON encoded
    created_at   REAL NOT NULL
);
```

数据库文件位置:`~/Library/Application Support/Pluck/pluck.sqlite`

### 4.7 启动项

使用 `SMAppService.mainApp.register()`(macOS 13+),替代旧 `LaunchAtLogin` 库。

### 4.8 多语言

国际化:`Localizable.xcstrings`(Xcode 15+ 字符串目录),v1 提供:
- 简体中文(默认)
- 英文(兜底)

繁体中文 / 日语 等留待 v0.3+。

---

## 5. 安全 / 签名 / 公证

### 5.1 entitlements(v1)

```xml
<plist>
  <dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <!-- 不申请 network.client(隐私优先) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <!-- 屏幕录制权限通过 ScreenCaptureKit 系统弹窗申请 -->
  </dict>
</plist>
```

### 5.2 签名 / 公证流程

```
1. Apple Developer Program 账号($99/年)
2. 在 Xcode 配 Team / Signing
3. Archive → Distribute App → Developer ID
4. notarytool submit / staple
5. 打包成 DMG(用 create-dmg 等工具)
6. 上传到自有 CDN / 七牛 / R2
7. Sparkle appcast.xml 指向新版本
```

### 5.3 隐私清单

`PrivacyInfo.xcprivacy`(Xcode 15+ 必需):

```xml
<plist>
  <dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
      <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array><string>CA92.1</string></array>
      </dict>
    </array>
  </dict>
</plist>
```

---

## 6. 测试策略

| 层级 | 工具 | 范围 |
|------|------|------|
| 单元测试 | XCTest | Services 层 100%(OCR / Clipboard / Storage) |
| UI 测试 | XCUITest | 关键流程 3 条(截图 OCR / 历史回查 / 设置切换) |
| 性能基准 | XCTest measure | OCR 响应 / 历史搜索 / 启动时间 |
| 手工冒烟 | Checklist | 每次 release 前必跑(macOS 14 / 15) |

CI(GitHub Actions):

```yaml
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: swift build
      - run: swift test
```

---

## 7. 距离生产还差什么(本骨架不包含的)

骨架是"可跑通的最小架构",**不是产品**。距离 v0.1.0 发布还需要:

- [ ] 在 Xcode 里建立 macOS App Target,引用本 Package(见 SETUP.md)
- [ ] Apple Developer Program 注册
- [ ] entitlements / Info.plist / Privacy / Icon
- [ ] 区域选择 overlay 的真实交互(MVP 用占位)
- [ ] OCR 结果展示窗口
- [ ] 历史搜索 UI
- [ ] 设置面板 UI
- [ ] 标注画布(P1)
- [ ] Sparkle 集成
- [ ] Paddle / Lemon 集成
- [ ] 自有官网 + 下载页
- [ ] 中英文文案 + 应用截图

---

## 8. 演进路线(指引,非承诺)

| 版本 | 时间 | 关键能力 |
|------|------|----------|
| **v0.1.0 MVP** | 2026-06 | 截图 + OCR + 剪贴板,无 AI |
| **v0.2.0** | 2026-08 | 标注 + 长截图 + 贴图 + 表格 OCR |
| **v0.3.0** | 2026-10 | AI 增强(可选)+ 翻译 + 自动命名 |
| **v0.4.0** | 2026-12 | 浮窗 + 主题 + 多语言 |
| **v1.0.0** | 2027-Q1 | iOS Companion(用 iPhone 扫描后传到 Mac)|
| **v2.0.0** | 2027-Q3 | Windows 版(Tauri 重写)+ 跨设备同步 |
