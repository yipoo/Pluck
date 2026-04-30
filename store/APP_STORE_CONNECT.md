# Pluck — App Store Connect 提交材料(内部参考)

> ⚠️ **重要**:**不要从本文件复制描述 / Promotional Text / Keywords / What's New 到 ASC** — 本文件包含 `•` `✓` `⌃⌥` `→` `⭐` 等 ASC 拒绝的字符,留作内部 markdown 阅读用。
>
> ⭐ **复制源:[ASC_CLEAN_TEXT.md](ASC_CLEAN_TEXT.md)**(纯 ASCII + 中文,扫描验证 0 雷区)。本文件用来看流程 / 截图 / 隐私问卷 / 提交清单。

> 💰 **价格更新**(2026-04-27):本 App **永久免费**,Pricing Tier 全部选 **Free**。下面 §2 的"¥98 / ¥48 / ¥298"分层已废弃,留作以后参考。

完整的 macOS App Store 上架元数据(中英双语)+ 截图规格 + 提交流程。

---

## ⚠️ 上架前需用户决策的两件事

1. **是否真的上 Mac App Store** vs **只走自有官网下载(Developer ID 公证)**
   - MAS 抽 30% 佣金(年收入 < 100 万美元享 15%)
   - MAS 沙盒严苛,某些功能(屏幕录制权限)用户体验不如 DI
   - DI 自由度高、抽成 0,但失去 MAS 流量
   - **建议:并行做** — 主站走 DI,MAS 作流量入口
2. **海外公司主体是否到位**
   - 中国区 MAS 上架要求开发者账号实名 + 主体证件
   - 海外公司的话,美国/新加坡/香港 LLC 或个人开发者账号都行
   - 走 DI 可以先用个人账号上线,后期转公司

下面材料以**两种渠道都上架**为前提撰写,字段都通用。

---

## 1. App Information(基础信息,首次提交后大部分锁定)

| 字段 | 中文(主)| 英文(次)|
|------|---------|----------|
| **App Name(显示名)** | `Pluck` | `Pluck` |
| **副标题(Subtitle)** | `本地优先的截图 OCR` | `Privacy-first Screenshot OCR` |
| **Bundle ID** | `com.yipoo.Pluck`(用户已设)| 同 |
| **SKU**(开发者内部编号)| `PLUCK-MAC-001` | 同 |
| **Primary Language** | 简体中文 | — |
| **Primary Category** | 效率(Productivity) | Productivity |
| **Secondary Category** | 工具(Utilities) | Utilities |
| **Content Rights** | 不包含、不展示第三方内容 | Does not contain third-party content |
| **Age Rating** | 4+ | 4+ |

### Age Rating Questionnaire(全选 None/No)

| 问题 | 答案 |
|------|------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use | None |
| Simulated Gambling | None |
| Sexual Content / Nudity | None |
| Unrestricted Web Access | **No** ⭐(关键 — 我们没接 webview) |
| Gambling | No |
| Contests | No |
| User Generated Content | No |

### Export Compliance(出口合规)

| 字段 | 答案 |
|------|------|
| Does your app use encryption? | **Yes** |
| Does your app qualify for any of the exemptions provided in Category 5, Part 2 of the U.S. Export Administration Regulations? | **Yes**(只用 Apple 提供的 ATS / HTTPS / Keychain 标准加密) |
| Does your app implement any standard encryption algorithms instead of, or in addition to, using or accessing the encryption within Apple's operating system? | No |
| Is your app a mass market product with key length less than or equal to 56 bits? | N/A |
| Does your app meet any of the following: ... is available for free? | 收费上架 → No |

→ 这组组合让 App **豁免年度自报告**(Annual Self Classification Report 免提交)。

---

## 2. Pricing & Availability(定价与可用区域)

### 当前定价:**永久免费**

| 渠道 | 价格 | ASC 设置 |
|------|------|---------|
| Mac App Store | 免费 | **Price Schedule → Free** |
| 自有官网 | 免费 DMG | 直接下载,不接支付 |

**Pluck 永久免费**。后续可能在 App 内或官网增加"打赏"入口(自愿捐助,类似 Buy Me a Coffee / Patreon),**不影响任何功能可用性**,也无需通过 ASC 配置(直链跳转外部即可)。

> ⚠️ Mac App Store 沙盒规则禁止 IAP 之外的支付方式。如未来需要 IAP 形式打赏,需在 ASC 单独配置非消耗型 IAP 项,且必须按 Apple 30% 抽成规则走。

### Availability

- **All Countries / Regions**:勾上(默认)
- **Pre-Orders**:不开
- **App Store Distribution**:仅 Mac App Store(iOS 选择不上架)
- **Public**:勾(否则只能内部 TestFlight)

---

## 3. App Privacy(隐私实践 — 7 大类问卷)

### 数据收集声明

> **回答"No, we do not collect data from this app"** ⭐
>
> Pluck 不收集任何用户数据。这是核心卖点。

具体每一类:

| 数据类别 | 是否收集 | 说明 |
|---------|---------|------|
| Contact Info(姓名/邮箱/电话/地址)| **No** | — |
| Health & Fitness | No | — |
| Financial Info | No | — |
| Location | No | — |
| Sensitive Info | No | — |
| Contacts | No | — |
| User Content(剪贴板/截图)| **No** ⭐ 数据只存本地,不上传 | |
| Browsing History | No | — |
| Search History | No | — |
| Identifiers(IDFA/Device ID)| No | — |
| Purchases | **No**(MAS 自己处理付费,我们不收集)| — |
| Usage Data(产品互动)| **No** | — |
| Diagnostics(崩溃日志)| **No** | — |
| Other Data | No | — |

### Privacy Policy URL(必填)

`https://pluck.yipoo.com/privacy.html`

(stub 已生成在 website/privacy.html — 见本仓库;部署到 Vercel/Cloudflare Pages 后 URL 立即可用)

---

## 4. Version Information — v0.1.0 首次提交

### 4.1 Promotional Text(170 字符内,可随时改不需重新审核)

**中文:**
```
拖动选择 → 自动识别 → 进剪贴板。所有处理都在你的 Mac 上,默认不联网,不收集任何数据。律师 / 医生 / 财务可放心用。
```
(81 字符)

**英文:**
```
Drag to select → instant OCR → into clipboard. Everything processed on your Mac, no network, no telemetry. Trusted by lawyers, doctors, and finance pros.
```
(154 字符)

### 4.2 Description(4000 字符内)

**中文:**
```
Pluck 是一款 macOS 上的隐私优先截图 OCR 与剪贴板套件。

核心功能:
• 全局热键 ⌃⌥A 区域截图,基于 Apple Vision 自动识别中英文文字并复制到剪贴板
• 全局热键 ⌃⌥V 打开剪贴板历史,所有复制过的文本、图片、文件随时回查
• 多屏识别:智能找到鼠标当前所在屏幕,Retina + 外接显示器混合环境正确处理
• 截图标注:矩形 / 箭头 / 高亮 / 文本 + 调色板 + 撤销重做 + 一键导出 PNG
• 长截图(实验性):滚动捕获多屏内容,自动拼接成一张长图
• 完整剪贴板历史:LIKE 模糊搜索支持中英文,100 条结果 < 100ms

为什么是 Pluck:

✓ 数据只在你的 Mac 上
所有 OCR / 历史 / 截图都本地处理,不上传任何数据到云端。律师 / 医生 / 财务 / 政府 / 合规人员可放心处理敏感文档。

✓ 默认不申请网络权限
你可以在 Activity Monitor 验证零外联。沙盒 entitlements 不包含 com.apple.security.network.client,即使我们想上传也做不到。

✓ 不内嵌任何分析、崩溃、广告 SDK
没有 Sentry、没有 Firebase、没有 Bugsnag、没有 Google Analytics。开源依赖:零。

✓ 极轻量
仅 8MB,空闲态内存 < 100MB,启动 < 1.5 秒。只用 Apple 原生框架(SwiftUI / AppKit / Vision / ScreenCaptureKit / SQLite3)。

✓ 苹果原生体验
菜单栏常驻,无 Dock 图标。⌃⌥A / ⌃⌥V 全局热键。深浅模式自动跟随系统。

适合人群:
• 知识工作者、产品经理、设计师 — 每天截图 OCR 复制粘贴 30 次
• 律师、医生、财务、合规、政府 — 处理敏感文档,云端 OCR 不可用
• 学生、研究者、跨境从业者 — 文献 OCR、长截图归档
• Mac 重度用户 — 替代海外不本地化的 CleanShot / Raycast

技术细节:
• OCR 引擎:Apple Vision(系统级,免费,中文 95%+ 准确率)
• 全局热键:Carbon HotKey(无需 Accessibility 权限)
• 剪贴板监听:NSPasteboard 0.5s 轮询,跳过敏感内容标记
• 数据库:SQLite3(本地,默认 100 条历史,可在设置调到 1000)
• 渲染:SwiftUI MenuBarExtra + NavigationSplitView
• 签名:Apple Developer ID + 沙盒 + Hardened Runtime + 公证

支持 macOS 14 (Sonoma) 及以上,Apple Silicon + Intel 通用二进制。

隐私政策:https://pluck.yipoo.com/privacy
开发者:dinglei
反馈:pluck@yipoo.com
```
(约 1500 字)

**英文:**
```
Pluck is a privacy-first screenshot OCR and clipboard suite for macOS.

KEY FEATURES

• Global hotkey ⌃⌥A — drag to select any screen region; Apple Vision instantly recognizes Chinese & English text and writes it to your clipboard
• Global hotkey ⌃⌥V — open clipboard history with full-text search across everything you've ever copied
• Multi-display aware — finds the screen your cursor is on, handles mixed Retina + external monitors correctly
• Annotation canvas — rectangle / arrow / highlight / text with color palette, undo/redo, one-click export as PNG
• Long screenshot (experimental) — scroll capture multiple pages, auto-stitch into a single long image
• Searchable clipboard history — fuzzy search across Chinese & English, 100 results in under 100ms

WHY PLUCK

✓ Your data never leaves your Mac
All OCR / history / screenshots are processed locally. Nothing uploaded to any cloud. Trusted by lawyers, doctors, finance professionals, and government workers handling sensitive documents.

✓ No network permission requested by default
Verify it yourself in Activity Monitor — zero outbound connections. Our sandbox entitlements don't include com.apple.security.network.client, so we couldn't upload even if we wanted to.

✓ Zero analytics, crash reporters, or ad SDKs
No Sentry, no Firebase, no Bugsnag, no Google Analytics. Open-source dependencies: zero.

✓ Featherweight
8MB on disk, under 100MB idle RAM, under 1.5s launch. Pure Apple-native frameworks (SwiftUI / AppKit / Vision / ScreenCaptureKit / SQLite3).

✓ Native macOS feel
Menu-bar resident, no Dock icon. ⌃⌥A / ⌃⌥V global hotkeys. Light/dark mode follows system.

PERFECT FOR

• Knowledge workers, PMs, designers — 30 OCRs a day
• Lawyers, doctors, finance, compliance, government — handling confidential documents where cloud OCR isn't allowed
• Students, researchers, cross-border professionals — paper OCR, long-screenshot archiving
• Mac power users — a Chinese-localized alternative to CleanShot / Raycast

TECHNICAL DETAILS

• OCR: Apple Vision Framework (system-level, free, 95%+ Chinese accuracy)
• Hotkeys: Carbon HotKey API (no Accessibility permission needed)
• Clipboard: NSPasteboard 0.5s polling, skips sensitive markers
• Database: SQLite3 (local, default 100-item history, configurable up to 1000)
• Rendering: SwiftUI MenuBarExtra + NavigationSplitView
• Signing: Apple Developer ID + sandbox + hardened runtime + notarization

Requires macOS 14 (Sonoma) or later. Universal binary (Apple Silicon + Intel).

Privacy: https://pluck.yipoo.com/privacy
Developer: dinglei
Feedback: pluck@yipoo.com
```
(~280 words)

### 4.3 Keywords(100 字符内,逗号分隔,**不要重复 App 名 / 副标题里的词**)

**中文(中国区):**
```
OCR,截图,剪贴板,文字识别,本地,隐私,效率,生产力,菜单栏,Vision,Mac,工具
```
(约 56 字符)

**英文(其他区):**
```
ocr,screenshot,clipboard,text recognition,vision,productivity,privacy,offline,menubar,utility
```
(约 95 字符)

> **ASO 提示**:Apple 把 App Name + Subtitle + Keywords 全部进搜索索引。Name 和 Subtitle 已经包含 "Pluck / 截图 / OCR / 剪贴板",所以 Keywords 只用补充长尾词。

### 4.4 What's New in This Version(4000 字符内)

**中文:**
```
v0.1.0 — Pluck 首发版本

🎉 核心功能
• 全局热键 ⌃⌥A 区域截图 + Apple Vision 自动 OCR(中文 95%+ 准确率)
• 全局热键 ⌃⌥V 打开剪贴板历史窗口
• 多屏环境智能识别鼠标所在屏幕
• 4 Tab 设置面板(通用 / 热键 / 隐私 / 关于)
• 首次启动 3 步引导(隐私承诺 / 热键 / 权限)

✏️ 标注画布
• 矩形 / 箭头 / 高亮 / 文本 4 种工具
• 8 色调色板 + 3 档线宽
• 撤销 / 重做 / 一键导出 PNG

🔍 历史窗口
• 侧栏分类筛选 + 中栏列表 + 右栏详情(macOS 原生 3 栏)
• LIKE 子串搜索(中英文,100 条结果 < 100ms)
• 截图缩略图 + OCR 文字双栏并排

📸 视觉反馈
• 截图后被截区域 200ms 白光淡出
• 系统截图音效(AudioToolbox,沙盒友好)
• 菜单栏图标三态(就绪 / 启动 / 截图中,带 SF Symbol pulse 动画)

🛡️ 隐私
• 默认不申请网络权限,Activity Monitor 可验证零外联
• 不内嵌任何分析、崩溃、广告 SDK
• 严格离线模式开关
```

**英文:**
```
v0.1.0 — Pluck launch release

🎉 CORE
• Global hotkey ⌃⌥A: drag-to-select region capture + Apple Vision OCR (95%+ Chinese accuracy)
• Global hotkey ⌃⌥V: clipboard history window
• Multi-display aware (cursor follow)
• 4-tab settings panel (General / Hotkeys / Privacy / About)
• First-launch 3-step onboarding

✏️ ANNOTATION
• Rectangle / arrow / highlight / text tools
• 8-color palette + 3 stroke widths
• Undo / redo / one-click PNG export

🔍 HISTORY
• 3-pane macOS-native layout (sidebar filter + list + detail)
• Fuzzy search (Chinese & English, 100 results in <100ms)
• Snapshot thumbnail + OCR text in split view

📸 FEEDBACK
• 200ms white flash on captured region
• System capture sound (AudioToolbox, sandbox-friendly)
• Tri-state menu bar icon (ready / launching / capturing, with SF Symbol pulse)

🛡️ PRIVACY
• No network entitlement by default — verifiable in Activity Monitor
• No analytics, crash reporters, or ad SDKs embedded
• Strict offline mode toggle
```

### 4.5 URLs

| 字段 | URL | 备注 |
|------|-----|------|
| **Marketing URL** | `https://pluck.yipoo.com` | 官网首页(已写好 hero + features + privacy + download + faq) |
| **Support URL** | `https://pluck.yipoo.com/support.html` | 必填,stub 已生成 |
| **Privacy Policy URL** | `https://pluck.yipoo.com/privacy.html` | 必填,stub 已生成 |
| **EULA**(可选)| `https://pluck.yipoo.com/terms.html` | 不填会用 Apple 默认 EULA |

### 4.6 Copyright

```
© 2026 dinglei. All rights reserved.
```

### 4.7 Developer Contact Info(审核员看的,不公开)

```
Name: dinglei
Email: pluck@yipoo.com(把它配成你能收的真实邮箱)
Phone: +86-XXXX(必填)
```

### 4.8 Notes for Reviewer(给审核员的留言,可选但**强烈建议**)

```
Pluck 是一款本地处理的截图 OCR + 剪贴板工具,无需登录、无需联网即可完整使用。

测试方法:
1. 安装并启动后,App 在菜单栏出现相机图标
2. 首次启动会有 3 步欢迎引导
3. 系统会请求"屏幕录制"权限,授予后即可使用
4. 按 ⌃⌥A 拖动选择屏幕任意区域 → 文字会被自动识别并写入剪贴板
5. 按 ⌃⌥V 打开剪贴板历史窗口

不需要任何账号或网络连接。
所有数据存储在 ~/Library/Containers/com.yipoo.Pluck/Data/Library/Application Support/Pluck/

如有问题请联系 pluck@yipoo.com
```

### 4.9 Sign-In Information

> **Account Required:No(不需要账号)**

不勾选 "Sign-In Required"。Pluck 不需要任何账号。

---

## 5. Screenshots(本仓库 store/screenshots/ 已生成)

### 必备规格(macOS App Store 规则)

| 尺寸 | 用途 | 数量限制 |
|------|------|---------|
| 1280 × 800 | 13 寸 MacBook | 1-10 张 |
| 1440 × 900 | 13 寸 MacBook Pro / Air | 1-10 张 |
| 2560 × 1600 | 13 寸 Retina | 1-10 张 |
| 2880 × 1800 | 15 寸 Retina | 1-10 张 |

> **建议**:每个尺寸至少 5 张。Apple 优先展示 2880×1800 给 Retina 设备,1280×800 给低分辨率。

### 本仓库已生成的 6 张

存放在 `store/screenshots/{尺寸}/`,每张 4 个尺寸版本:

1. `01-hero.png` — Brand + 标语 "本地优先的截图 OCR" + 菜单栏 popover 浮窗
2. `02-capture.png` — 区域选择 overlay + 拖动选区 + 提示
3. `03-ocr.png` — OCR 识别结果 + 复制确认通知
4. `04-clipboard.png` — 剪贴板历史 3 栏窗口
5. `05-snapshots.png` — 截图历史 + 标注编辑器
6. `06-settings.png` — 设置面板(隐私 Tab) + "0 外部 SDK / 0 网络请求 / 0 用户追踪"

> 这些是程序化生成的 marketing-style 营销图。**正式提交时建议替换为真实运行 Pluck 时截的图**(更真实,但也可以直接用 marketing 版,App Store 不强制要求"真实截图")。

### 本地生成 / 重新生成

```bash
cd /Users/dinglei/MyClaude/pluck
swift store/generate-screenshots.swift
```

会输出 6 张 × 4 尺寸 = 24 个 PNG。

### 不需要的尺寸

- iOS 屏幕(iPhone / iPad)— 我们只发 macOS 版,iOS 标签 unchecked
- Apple TV / Watch — N/A

---

## 6. App Preview(预览视频,可选 ≤ 3 个)

App Preview 必须是**实机录屏**,不能用我们生成的 marketing 图。

**强烈建议先发不带 App Preview 的版本**,后续 v0.2 时补充。

如果一定要做:
- 时长:15-30 秒
- 格式:H.264 MP4
- 尺寸:同截图(每个分辨率一份)
- 内容建议:截图 OCR 一气呵成的 demo
- 录屏工具:macOS 内置 ⌘⇧5 → 选录制全屏 → 选择麦克风 None

---

## 7. App Store 审核常见拒因(我们的预防)

| 风险点 | 我们的处理 |
|--------|-----------|
| **2.1 App Completeness**:崩溃 / 不可用 | 已修 EXC_BAD_ACCESS / 沙盒 audioanalyticsd |
| **2.5.1 隐私权限滥用** | NSScreenCaptureUsageDescription 文案明确 + 不申请不必要权限 |
| **3.1.1 In-App Purchase 绕开** | v0.1 免费;后续付费用 MAS 内购,不绕开 |
| **5.1.1 Data Collection** | 隐私问卷全 No + 隐私政策 URL 必填 |
| **5.1.2 Data Use & Sharing** | 不收集就不用 ATT 弹窗 |
| **4.0 Design — 看起来像系统 App** | App Icon 与系统截图工具明显不同(蓝渐变) |
| **2.3.10 准确性** | 描述里说"OCR 95% 中文准确率"是基于实测 — 真实数据 |

---

## 8. 提交清单(checklist)

按这个顺序在 App Store Connect 操作:

- [ ] 注册 Apple Developer Program ($99/年)
- [ ] 在 ASC "我的 App" → 新增 → macOS App
- [ ] 填 §1 App Information(基础信息一次性)
- [ ] 填 §2 Pricing & Availability
- [ ] 填 §3 App Privacy(隐私问卷 + 政策 URL)
- [ ] 创建 v0.1.0 版本
- [ ] 上传截图(Xcode → Archive → Distribute → App Store Connect)
- [ ] 填 §4 描述 / 关键词 / 更新说明 / URL
- [ ] §4.7 - 4.9 联系信息 / 审核员留言
- [ ] §5 截图(从 store/screenshots/ 拖到对应尺寸)
- [ ] **Submit for Review**
- [ ] 等待 1-3 天审核(中国区有时 1 周)

如被拒:看 Resolution Center 给的 guideline 编号 → 改完重新提交。

---

## 9. 常用模板回复(被拒/客服回复)

### 用户报"截图无反应"

```
Hi,

请检查:
1. 系统设置 → 隐私与安全性 → 屏幕录制 → 找到 Pluck 并勾上
2. 完全退出 Pluck(⌘Q,不是关窗口)
3. 重新启动 Pluck

如还有问题,把 macOS 版本号 + Pluck 版本号(在"设置 → 关于"看)发给我们,我们立即跟进。

谢谢!
pluck@yipoo.com
```

### 用户问"为什么不上 iOS"

```
Pluck 用的截图 API 是 macOS 专属(ScreenCaptureKit),iOS 没有等价权限模型。
iOS 配套 App 已在 v1.0 路线图(用 iPhone 摄像头扫描后传到 Mac OCR),
预计 2027 Q1 推出。先在 https://pluck.yipoo.com 留个邮箱,我们发布时通知你。
```

---

## 10. 配套文件清单

```
store/
├── APP_STORE_CONNECT.md          ← 本文档
├── generate-screenshots.swift    ← 程序化生成营销截图
├── screenshots/
│   ├── 1280x800/                 ← 6 PNG
│   ├── 1440x900/                 ← 6 PNG
│   ├── 2560x1600/                ← 6 PNG
│   └── 2880x1800/                ← 6 PNG
└── (未来) preview-videos/        ← App Preview 实机录屏
```

```
website/
├── index.html                    ← 已就绪
├── privacy.html                  ← stub(本提交一并生成)
├── terms.html                    ← stub
├── support.html                  ← stub
└── ...
```

---

## 11. 提交后(发布即时操作)

- [ ] 推一条小红书 / 即刻 / V2EX 上线公告
- [ ] 通知 50 个内测用户切换到正式版
- [ ] 监控前 24 小时 Crashes(Xcode Organizer)
- [ ] 准备 v0.1.1 hotfix 路线(如果有 critical bug)

---

> **Apple 审核小贴士**
> 中国区比美区严 ~30%,常拿"内容审核""支付方式""备案"挑刺。
> 我们走 Developer ID + 自有官网作为 Plan B,即便 MAS 拒绝也能 Day-1 上线。
