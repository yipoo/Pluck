# Pluck 更新日志

## v0.1.0-dev (2026-04-27)

第一个可发布的内测版本 — 代码完工 + 工程化全套。

### 核心功能

- 全局热键 ⌃⌥A 区域截图 + Apple Vision OCR(中文 95%+)
- 全局热键 ⌃⌥V 打开剪贴板历史(LIKE 中文搜索)
- 菜单栏常驻(LSUIElement,无 Dock)
- 多屏路由(NSEvent.mouseLocation + displayID 直传 SCKit)
- 截图视觉反馈(被截区域 200ms 白光 + 系统截图音)
- 动态菜单栏图标(就绪/启动/截图中,SF Symbol pulse 动画)
- 4 Tab 设置面板(通用 / 热键 / 隐私 / 关于)
- 3 步首启 Onboarding(隐私 / 热键 / 权限)
- 历史窗口 NavigationSplitView 3 栏(侧栏筛选 + 卡片列表 + 详情)
- 截图详情:大图 + 完整 OCR 文字 + 复制/导出/Finder/删除
- 截图标注(v0.2 提前):矩形 / 箭头 / 高亮 / 文本 + 调色板 + 线宽 + 撤销重做 + 导出
- 长截图(v0.2 实验性):ImageStitcher 算法 + 浮窗式手动滚动 UI
- "检查更新"入口(Sparkle SPM 接好后自动激活)

### 工程基础

- 零外部依赖(仅 Apple 原生框架)
- macOS 14+(全 Apple Silicon 优化)
- App Sandbox + Hardened Runtime + Developer ID 签名
- 单元测试 13 个(Models / Storage / OCR / Settings)
- AppIcon 程序化生成(scripts/generate-app-icon.swift)
- DMG 打包 + 公证编排(scripts/build-dmg.sh / release.sh)
- GitHub Actions CI(build + test on push;tag 出 DMG)
- 官网静态页(零依赖纯 HTML/CSS,暗色模式自动适配)

### 隐私承诺

- 默认不申请网络权限
- 不内嵌任何分析 / 崩溃 / 广告 SDK
- 所有 OCR / 历史 / 截图本地处理
- PrivacyInfo.xcprivacy 仅声明 UserDefaults(CA92.1)

---

## 待 v0.2 完成(代码已落,需打磨)

- 标注:**马赛克**(用 CIPixellate)
- 长截图:Accessibility API 自动滚动 + 滚动到底检测
- 历史搜索:FTS5 + trigram tokenizer(规模 > 1000 时切换)

## 待 v0.3+

- 接入备案 LLM(豆包 / Kimi / DeepSeek)做智能总结 / 翻译 — 用户开关
- 离线 PaddleOCR 增强(手写体)
- iOS 配套 App
- Windows 版(Tauri 重写)
