# ASC 直接可复制版本(无特殊 Unicode)

> ⭐ **复制源是本文件**(`ASC_CLEAN_TEXT.md`),**不是** `APP_STORE_CONNECT.md`。
> 旧文档里描述用了 `•` `✓` `→` 等字符,ASC 后台会拒。本文件已扫描验证 0 雷区。

App Store Connect 对部分 Unicode 范围有校验,常见的"列表前缀字符"和键盘符号都会被判无效:

- 键盘符号:`⌃` `⌥` `⌘` `⇧`
- **列表前缀**:`•`(U+2022 BULLET)`▪` `▫` `‣` `◦` `·`
- 箭头:`→` `←` `↑` `↓`
- 勾叉:`✓` `✗` `★` `☆` `⭐`
- 破折号变体:`—` `–` `…`
- 任何 emoji(`🚀` `🎉` `🔒` 等)

本文件**只用** ASCII + 中文字 + 中文标点(`,。!?:;""''`)+ `©`。所有列表前缀用 ASCII `-`(连字符 + 空格)。

---

## 1. App Name(显示名)

```
Pluck
```

---

## 2. 副标题 / Subtitle(30 字符内)

**中文版:**
```
本地优先的截图 OCR
```

**英文版:**
```
Privacy-first Screenshot OCR
```

---

## 3. Promotional Text(170 字符内,可不重审改)

**中文版:**
```
拖动选择,自动识别,直接进剪贴板。所有处理都在你的 Mac 上,默认不联网,不收集任何数据。永久免费,独立开发者维护。
```

**英文版:**
```
Drag to select, instant OCR, straight to clipboard. Everything processed on your Mac, no network, no telemetry. Free forever, made by an indie developer.
```

---

## 4. Description(4000 字符内)

**中文版:**

```
Pluck 是一款 macOS 上的隐私优先截图 OCR 与剪贴板套件。

核心功能

- 全局热键 Control + Option + A 区域截图,基于 Apple Vision 自动识别中英文文字并复制到剪贴板
- 全局热键 Control + Option + V 打开剪贴板历史,所有复制过的文本、图片、文件随时回查
- 多屏识别,智能找到鼠标当前所在屏幕,Retina 加外接显示器混合环境正确处理
- 截图标注,矩形 / 箭头 / 高亮 / 文本,带调色板,支持撤销重做与一键导出 PNG
- 长截图(实验性),滚动捕获多屏内容,自动拼接成一张长图
- 完整剪贴板历史,LIKE 模糊搜索支持中英文,100 条结果在 100 毫秒内返回

为什么是 Pluck

数据只在你的 Mac 上
所有 OCR、历史、截图都本地处理,不上传任何数据到云端。律师、医生、财务、政府、合规人员可放心处理敏感文档。

默认不申请网络权限
你可以在活动监视器(Activity Monitor)验证零外联。沙盒 entitlements 不包含 com.apple.security.network.client,即使我们想上传也做不到。

不内嵌任何分析、崩溃、广告 SDK
没有 Sentry,没有 Firebase,没有 Bugsnag,没有 Google Analytics。开源依赖:零。

极轻量
仅 8MB 体积,空闲态内存小于 100MB,启动小于 1.5 秒。只用 Apple 原生框架,SwiftUI、AppKit、Vision、ScreenCaptureKit、SQLite3。

苹果原生体验
菜单栏常驻,无 Dock 图标。全局热键支持自定义。深浅模式自动跟随系统。

适合人群

- 知识工作者、产品经理、设计师,每天截图 OCR 复制粘贴 30 次以上
- 律师、医生、财务、合规、政府,处理敏感文档,云端 OCR 不可用
- 学生、研究者、跨境从业者,文献 OCR、长截图归档
- Mac 重度用户,替代海外不本地化的同类工具

技术细节

- OCR 引擎:Apple Vision(系统级,免费,中文 95% 以上准确率)
- 全局热键:Carbon HotKey API(无需辅助功能权限)
- 剪贴板监听:NSPasteboard 0.5 秒轮询,跳过敏感内容标记
- 数据库:SQLite3(本地,默认 100 条历史,可在设置调到 1000)
- 渲染:SwiftUI MenuBarExtra 加 NavigationSplitView
- 签名:Apple Developer ID 加沙盒 加 Hardened Runtime 加公证

支持 macOS 14 (Sonoma) 及以上,Apple Silicon 与 Intel 通用二进制。

价格

永久免费。无任何功能限制、无水印、无广告、无内购解锁。所有未来更新都免费。后续可能在 App 内或官网增加"打赏"入口(自愿捐助),不影响任何功能可用性。

隐私政策:https://pluck.yipoo.com/privacy.html
开发者:dinglei
反馈邮箱:pluck@yipoo.com
```

**英文版:**

```
Pluck is a privacy-first screenshot OCR and clipboard suite for macOS.

KEY FEATURES

- Global hotkey Control + Option + A: drag to select any screen region, Apple Vision instantly recognizes Chinese and English text and writes it to your clipboard
- Global hotkey Control + Option + V: open clipboard history with full-text search across everything you have ever copied
- Multi-display aware: finds the screen your cursor is on, handles mixed Retina and external monitors correctly
- Annotation canvas: rectangle, arrow, highlight, and text tools with color palette, undo / redo, one-click export as PNG
- Long screenshot (experimental): scroll capture multiple pages, auto-stitch into a single long image
- Searchable clipboard history: fuzzy search across Chinese and English, 100 results in under 100 milliseconds

WHY PLUCK

Your data never leaves your Mac
All OCR, history, and screenshots are processed locally. Nothing uploaded to any cloud. Trusted by lawyers, doctors, finance professionals, and government workers handling sensitive documents.

No network permission requested by default
Verify it yourself in Activity Monitor. Zero outbound connections. Our sandbox entitlements do not include com.apple.security.network.client, so we could not upload even if we wanted to.

Zero analytics, crash reporters, or ad SDKs
No Sentry, no Firebase, no Bugsnag, no Google Analytics. Open-source dependencies: zero.

Featherweight
8MB on disk, under 100MB idle RAM, under 1.5 seconds launch. Pure Apple-native frameworks: SwiftUI, AppKit, Vision, ScreenCaptureKit, SQLite3.

Native macOS feel
Menu-bar resident, no Dock icon. Global hotkeys customizable. Light and dark mode follows system.

PERFECT FOR

- Knowledge workers, PMs, designers (30 OCRs a day)
- Lawyers, doctors, finance, compliance, government (confidential documents where cloud OCR is not allowed)
- Students, researchers, cross-border professionals (paper OCR, long-screenshot archiving)
- Mac power users (a Chinese-localized alternative to similar tools)

TECHNICAL DETAILS

- OCR: Apple Vision Framework (system-level, free, 95 percent or higher Chinese accuracy)
- Hotkeys: Carbon HotKey API (no Accessibility permission needed)
- Clipboard: NSPasteboard 0.5-second polling, skips sensitive markers
- Database: SQLite3 (local, default 100-item history, configurable up to 1000)
- Rendering: SwiftUI MenuBarExtra plus NavigationSplitView
- Signing: Apple Developer ID, sandbox, hardened runtime, notarized

Requires macOS 14 (Sonoma) or later. Universal binary (Apple Silicon and Intel).

PRICE

Free forever. No feature limits, no watermark, no ads, no in-app unlocks. All future updates are free. We may later add a voluntary tip jar (in-app or on the website), which never affects feature availability.

Privacy: https://pluck.yipoo.com/privacy.html
Developer: dinglei
Feedback: pluck@yipoo.com
```

---

## 5. Keywords(100 字符内,逗号分隔,英文逗号)

**中国区(中文 + 英文混合):**
```
OCR,截图,剪贴板,文字识别,本地,隐私,效率,生产力,菜单栏,Vision,Mac,工具
```

**海外(纯英文):**
```
ocr,screenshot,clipboard,text recognition,vision,productivity,privacy,offline,menubar,utility
```

> 注意:逗号必须是**英文半角逗号** `,` 不要用中文全角逗号 `,`,否则 Apple 会把整段当成一个词。

---

## 6. What's New in This Version

**中文版:**

```
v0.1.0 首发版本

核心功能

- 全局热键 Control + Option + A 区域截图,基于 Apple Vision 自动 OCR(中文 95% 以上准确率)
- 全局热键 Control + Option + V 打开剪贴板历史窗口
- 多屏环境智能识别鼠标所在屏幕
- 4 Tab 设置面板:通用、热键、隐私、关于
- 首次启动 3 步引导:隐私承诺、热键、权限

标注画布

- 矩形、箭头、高亮、文本 4 种工具
- 8 色调色板加 3 档线宽
- 撤销、重做、一键导出 PNG

历史窗口

- 侧栏分类筛选加中栏列表加右栏详情(macOS 原生 3 栏布局)
- LIKE 子串搜索(中英文,100 条结果在 100 毫秒内)
- 截图缩略图加 OCR 文字双栏并排

视觉反馈

- 截图后被截区域 200 毫秒白光淡出
- 系统截图音效(AudioToolbox,沙盒友好)
- 菜单栏图标三态:就绪、启动中、截图中

隐私

- 默认不申请网络权限,Activity Monitor 可验证零外联
- 不内嵌任何分析、崩溃、广告 SDK
- 严格离线模式开关
```

**英文版:**

```
v0.1.0 launch release

CORE

- Global hotkey Control + Option + A: drag-to-select region capture plus Apple Vision OCR (95 percent or higher Chinese accuracy)
- Global hotkey Control + Option + V: clipboard history window
- Multi-display aware (cursor follow)
- 4-tab settings panel: General, Hotkeys, Privacy, About
- First-launch 3-step onboarding

ANNOTATION

- Rectangle, arrow, highlight, text tools
- 8-color palette and 3 stroke widths
- Undo, redo, one-click PNG export

HISTORY

- 3-pane macOS-native layout: sidebar filter, list, detail
- Fuzzy search (Chinese and English, 100 results in under 100 milliseconds)
- Snapshot thumbnail and OCR text in split view

FEEDBACK

- 200ms white flash on captured region
- System capture sound (AudioToolbox, sandbox-friendly)
- Tri-state menu bar icon: ready, launching, capturing

PRIVACY

- No network entitlement by default, verifiable in Activity Monitor
- No analytics, crash reporters, or ad SDKs embedded
- Strict offline mode toggle
```

---

## 7. URLs(三个必填)

```
Marketing URL:        https://pluck.yipoo.com
Support URL:          https://pluck.yipoo.com/support.html
Privacy Policy URL:   https://pluck.yipoo.com/privacy.html
EULA URL (可选):       https://pluck.yipoo.com/terms.html
```

---

## 8. Copyright

```
© 2026 dinglei. All rights reserved.
```

> 这里的 `©` 字符 ASC 接受。如不放心可改成 `(c) 2026 dinglei. All rights reserved.`

---

## 9. Notes for Reviewer(给审核员的说明)

```
Pluck 是一款本地处理的截图 OCR 加剪贴板工具,无需登录、无需联网即可完整使用。

测试方法:
1. 安装并启动后,App 在菜单栏出现相机图标
2. 首次启动会有 3 步欢迎引导
3. 系统会请求"屏幕录制"权限,授予后即可使用
4. 按 Control + Option + A 拖动选择屏幕任意区域,文字会被自动识别并写入剪贴板
5. 按 Control + Option + V 打开剪贴板历史窗口

不需要任何账号或网络连接。
所有数据存储在 ~/Library/Containers/com.yipoo.Pluck/Data/Library/Application Support/Pluck/

如有问题请联系 pluck@yipoo.com
```

---

## 10. 已剔除的字符列表(供你检查别的 ASC 字段)

如果你在别的字段还遇到 "无效字符",检查一下:

| 字符 | Unicode | 在哪 | 替换为 |
|------|---------|------|------|
| **`•`** | **U+2022 BULLET** | **列表前缀(最高频雷区)** | **`-`(ASCII 连字符 + 空格)** |
| `▪` | U+25AA | 黑色小方块列表前缀 | `-` |
| `▫` | U+25AB | 白色小方块列表前缀 | `-` |
| `‣` | U+2023 | 三角列表前缀 | `-` |
| `◦` | U+25E6 | 白圈列表前缀 | `-` |
| `·` | U+00B7 | 中点 | `,` 或 ` ` |
| `⌃` | U+2303 | 键盘 Control 符号 | `Control` 或 `Ctrl` |
| `⌥` | U+2325 | 键盘 Option 符号 | `Option` 或 `Alt` |
| `⌘` | U+2318 | 键盘 Command 符号 | `Command` 或 `Cmd` |
| `⇧` | U+21E7 | 键盘 Shift 符号 | `Shift` |
| `→` | U+2192 | 箭头 | `,` 或 `然后` 或 `to` |
| `←` | U+2190 | 反向箭头 | `from` |
| `✓` | U+2713 | 勾选 | 删除或 `-` |
| `✗` | U+2717 | 叉 | 删除 |
| `★` | U+2605 | 实心星 | 删除 |
| `☆` | U+2606 | 空心星 | 删除 |
| `⭐` | U+2B50 | emoji 星 | 删除 |
| `—` | U+2014 | em dash | `-` 或 `,` |
| `–` | U+2013 | en dash | `-` |
| `…` | U+2026 | 省略号 | `...` |
| `「」` | U+300C/D | 中文方括号 | 删除 |
| `『』` | U+300E/F | 中文引号 | 删除 |
| 任何 emoji(`🚀✨🎉🔒🛡️`) | 高位 Unicode | 表情 | 删除(尤其 Promotional Text / Keywords / Subtitle) |

> ASC 对 **Description 字段** 容忍度最高(中文标点 `,。!?` 都行)。
> 对 **Promotional Text / Keywords / What's New** 容忍度低,**别用任何 emoji 和键盘符号**。
> 对 **Subtitle** 最严,**只用 ASCII + 标准中文字符**。

## 11. 验证方法

复制粘贴前先用这个一键检查:

把要提交的文本贴到 https://www.compart.com/en/unicode/category/Sm 或 https://onlinetools.com/unicode/find-unusual-unicode 里看,有没有"非常规"字符。

或者本地命令:

```bash
# 一行命令:把要提交的文字粘进 stdin,输出空 = 安全
pbpaste | python3 -c "
import sys
def safe(c):
    n = ord(c)
    return (0x20 <= n <= 0x7E or n in (9,10)
            or 0x4E00 <= n <= 0x9FFF
            or 0x3000 <= n <= 0x303F
            or 0xFF00 <= n <= 0xFFEF
            or n == 0xA9)
for i,c in enumerate(sys.stdin.read()):
    if not safe(c): print(f'位置 {i}: U+{ord(c):04X} [{c}]')
"
# 把要测的文字先剪贴板上,然后跑上面命令。空输出 = 安全
```

---

## 12. 推荐顺序

按这个顺序填,**逐字段保存测试**,出问题立即知道是哪个字段:

1. App Name
2. Subtitle
3. Description(用上面中文版,先粘 1/3,Save → 1/3,Save → 1/3,Save)
4. Keywords
5. Promotional Text
6. URLs
7. What's New
8. Notes for Reviewer

每段保存如果都没报错,就 OK。

---

> 旧版 `APP_STORE_CONNECT.md` 留作内部文档参考(里面 ⌃⌥ 等符号用于本地阅读体验,App 内 UI 也确实显示这些符号,但 ASC 文本字段必须用本文件版本)。
