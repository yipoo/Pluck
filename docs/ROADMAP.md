# Roadmap — Pluck MVP 8 周冲刺

**目标**:8 周(2 个月)从 0 到 v0.1.0 内测发布
**起点**:2026-04-26(本周即 W1)
**预计 v0.1.0 发布日**:2026-06-21

---

## 总览(8 周)

| Week | 主题 | 关键产出 | 验收 |
|------|------|---------|------|
| W1 | **基础架构 + 菜单栏** | 跑通 SwiftUI MenuBarExtra,设置面板骨架 | App 能启动并常驻菜单栏 |
| W2 | **全局热键 + 截屏权限** | Carbon HotKey 注册成功,触发 ScreenCaptureKit | 按 ⌃⌥A 能截图保存到 ~/Desktop |
| W3 | **区域选择 overlay** | 半透明全屏 + 鼠标拖动选区 | 用户能任选屏幕区域,得到 CGImage |
| W4 | **OCR 集成** | Vision Framework 中英文识别打通 | 区域 OCR 后文字进入剪贴板 |
| W5 | **剪贴板监听 + GRDB 存储** | 0.5s 轮询监听,SQLite 写入,FTS 全文搜索 | 历史窗口能查 + 搜索 100 条 |
| W6 | **设置面板 + 自定义热键** | 热键自定义 + 启动项 + 隐私开关 | 设置改完即生效 |
| W7 | **打磨 + 隐私清单 + 公证** | App Icon、Onboarding、PrivacyInfo、Sparkle | 能签名 + 公证 + 用 Sparkle 自更新 |
| W8 | **内测发布** | 自有官网 + DMG 下载 + 反馈渠道 | 50 个种子用户,GitHub Issues / Telegram 反馈 |

---

## 详细任务拆分

### Sprint 1(W1-W2):骨架与系统集成

#### W1 — 基础架构

**目标**:跑通最小可运行的菜单栏 App。

任务清单:
- [ ] 在 Xcode 创建 macOS App Target(参考 [SETUP.md](SETUP.md))
- [ ] 配 Team / Bundle ID(`com.dinglei.pluck`)
- [ ] 引用本 Package 作为 local dependency
- [ ] `App.swift` 用 `MenuBarExtra` 渲染图标
- [ ] `MenuBarContentView` 显示"Hello Pluck"+ Quit 按钮
- [ ] `SettingsView` 占位(空 Tab 视图)
- [ ] `Info.plist` 设置 `LSUIElement = YES`
- [ ] `swift test` 跑通空测试
- [ ] GitHub Actions CI

**验收**:
- 双击 App 后菜单栏出现图标,点击展开 popover
- 关闭后再启动,正常显示
- CI 绿

#### W2 — 全局热键 + 截屏

**目标**:按热键能截图(暂不区域选择,先全屏)。

任务清单:
- [ ] 添加 [HotKey](https://github.com/soffes/HotKey) 依赖到 Package.swift
- [ ] `HotkeyManager` 注册 ⌃⌥A 全局热键
- [ ] 实现 `ScreenCaptureService.captureFullScreen()`
- [ ] 截图后保存到 `~/Library/Application Support/Pluck/snapshots/<uuid>.png`
- [ ] 第一次截图弹屏幕录制权限请求
- [ ] 在菜单里显示"最后一张截图"缩略图

**验收**:
- 按 ⌃⌥A 听到截屏音效,文件落到磁盘
- 系统设置 → 隐私 → 屏幕录制 中能看到 Pluck

**⚠️ 风险**:屏幕录制权限弹窗在沙盒下行为复杂,需要早测。

---

### Sprint 2(W3-W4):截图 OCR 主链路

#### W3 — 区域选择 overlay

**目标**:用户能用鼠标圈选区域。

任务清单:
- [ ] `RegionSelectionOverlay` SwiftUI 视图
- [ ] 创建全屏 `NSWindow`(level: `.screenSaver`)
- [ ] 半透明黑色蒙层
- [ ] 鼠标按下 → 拖动 → 松开,绘制选择框
- [ ] ESC 退出
- [ ] 选区坐标传给 `ScreenCaptureService.captureRegion(rect:)`
- [ ] 多显示器场景兼容
- [ ] Retina 缩放正确

**验收**:
- 按 ⌃⌥A 出现蒙层,能选任意矩形
- 选区与最终图像像素级匹配

#### W4 — OCR 打通

**目标**:截图后文字自动到剪贴板。

任务清单:
- [ ] `OCRService.recognize(image:) async -> String` 用 Vision
- [ ] 配置 `recognitionLanguages: ["zh-Hans","zh-Hant","en-US"]`
- [ ] 错误处理(图像为空 / 识别失败)
- [ ] 写入 `NSPasteboard.general` 文本
- [ ] 截屏 + OCR 全流程整合到一次热键
- [ ] 完成后弹出系统通知"已识别 N 字"
- [ ] 单元测试:5 张样图(中文 / 英文 / 中英混合 / 表格 / 手写)

**验收**:
- 印刷体中文识别准确率 ≥ 95%
- A4 半屏 OCR < 1s(M2 Mac)
- 测试覆盖 5 类样本

---

### Sprint 3(W5-W6):剪贴板与设置

#### W5 — 剪贴板监听 + 存储

**目标**:历史窗口可查可搜。

任务清单:
- [ ] 添加 [GRDB.swift](https://github.com/groue/GRDB.swift) 依赖
- [ ] `Storage` 初始化 SQLite + 表结构 + FTS5
- [ ] `ClipboardMonitor` 0.5s 轮询 `changeCount`
- [ ] 区分文本 / 图像 / 文件
- [ ] 跳过自己写入(自定义 pasteboard type)
- [ ] 跳过敏感(`org.nspasteboard.ConcealedType`)
- [ ] `HistoryView`:Tab(剪贴板 / 截图)+ 列表 + 搜索框
- [ ] 单击复制回剪贴板
- [ ] 历史限 100 条(老的自动清理)

**验收**:
- 复制任意 100 条,App 重启后历史还在
- 搜索"调研"能命中并高亮
- 单击列表项 → 内容回到剪贴板,可粘贴

#### W6 — 设置面板 + 自定义

**目标**:用户能自定义热键、清理历史、开关启动项。

任务清单:
- [ ] `SettingsView` 4 个 Tab:通用 / 热键 / 隐私 / 关于
- [ ] **通用**:启动项(SMAppService)、外观(浅 / 深 / 自动)、菜单栏图标样式
- [ ] **热键**:可重绑(用 [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) 或自实现)
- [ ] **隐私**:历史保留条数(20/100/500/无限)、清空历史按钮、严格离线开关
- [ ] **关于**:版本号、官网、邮件反馈、隐私政策链接
- [ ] `SettingsStore`(UserDefaults + Combine)

**验收**:
- 改完热键即生效(无需重启)
- 清空历史后数据库行数为 0
- "严格离线"开启后,任何网络请求被代码层 assert 阻断

---

### Sprint 4(W7-W8):发布准备

#### W7 — 打磨 + 公证

**目标**:产生可签名公证的发布版。

任务清单:
- [ ] App Icon(找设计师做或用 [IconKitchen](https://icon.kitchen/))
- [ ] Onboarding 弹窗(首启展示热键 / 权限引导)
- [ ] PrivacyInfo.xcprivacy
- [ ] Sparkle 集成,生成 EdDSA 密钥
- [ ] DMG 打包脚本(create-dmg)
- [ ] 公证流程跑通(notarytool submit / staple)
- [ ] 启动 / 截图 / OCR 路径埋本地日志(可选,debug build only)
- [ ] 内存 / CPU 压测(空闲 < 100MB)
- [ ] macOS 14 + 15 兼容性测试

**验收**:
- 产生签名 + 公证后的 .dmg,在干净 Mac 双击能启动
- Activity Monitor 空闲态 < 100MB

#### W8 — 内测发布

**目标**:50 个种子用户上手。

任务清单:
- [ ] 自有官网(可用 Vercel + Next.js / Astro 静态页)
- [ ] 下载页 + 文档 + FAQ
- [ ] Sparkle appcast.xml 指向 v0.1.0
- [ ] 隐私政策页(明确"严格离线")
- [ ] 邮件 / Telegram / 即刻 反馈渠道
- [ ] 在 V2EX / 少数派 / 小红书 / 即刻 软文 1 篇
- [ ] 收集 50 个种子用户反馈
- [ ] 建立 issue tracker(GitHub Issues 或 Linear)

**验收(内测)**:
- 至少 50 个真实用户安装
- 首日崩溃率 < 1%
- 至少 5 条有效反馈

---

## 里程碑 / 决策门(Decision Gates)

> 每个 Gate 失败时不要硬推,**先决定是 cut scope、改方案、还是延期**。

| Gate | 时点 | 通过条件 | 失败应对 |
|------|------|---------|---------|
| **G1 — 系统集成可行性** | W2 末 | 全局热键 + 截屏权限工作 | 失败则评估改用其他热键库 / 改用辅助功能 API |
| **G2 — OCR 质量达标** | W4 末 | 中文准确率 ≥ 95% | 失败则改 PaddleOCR / RapidOCR 备选 |
| **G3 — 历史搜索性能** | W5 末 | 1000 条搜索 < 200ms | 失败则索引调优或限制历史规模 |
| **G4 — 公证打包通过** | W7 末 | DMG 在干净 Mac 启动无警告 | 失败则排查 entitlements,可能延迟 1 周 |
| **G5 — 内测反馈** | W8 末 | 50 用户 + 5 条有效反馈 | 用反馈决定 v0.2 优先级 |

---

## 工作量假设(独立开发者)

- **可投入小时**:每周 30 小时(全职业余 / 半职专注)
- **总投入**:8 × 30 = 240 小时
- **buffer**:每个 Sprint 预留 10% 处理意外
- **如果是兼职**(每周 15 小时):**总周期翻倍到 16 周**

---

## 不在 MVP 范围内(明确推迟)

为了 8 周能到内测,以下功能**禁止**在 v0.1.0 内做:

- ❌ 标注画布(箭头 / 文字 / 马赛克)→ v0.2
- ❌ 长截图 → v0.2
- ❌ 贴图(钉桌面)→ v0.2
- ❌ 表格 OCR → v0.2
- ❌ 翻译 → v0.3
- ❌ AI 增强 → v0.3
- ❌ 多语言界面(繁中 / 日)→ v0.4
- ❌ iOS Companion → v1.0
- ❌ Windows → v2.0
- ❌ 跨设备同步 → v2.0

---

## Sprint 1 启动 checklist(开始 W1 前)

立即可做的事:
- [ ] 决定正式产品名 *(可推到 W5)*
- [ ] 注册 Apple Developer Program($99,**至少在 W7 公证前** 完成)
- [ ] 确定海外公司主体方向 *(可推到 W5,但影响支付 / 税务)*
- [ ] 选定代码托管(GitHub private repo 是默认,免费)
- [ ] 把本仓库初始 commit push 到远端
- [ ] 安装 Xcode 15+ / 命令行工具 / Apple Silicon Mac 推荐
