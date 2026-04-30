# Pluck — App Store Connect 提交资料

完整的 macOS App Store 上架素材包。

## 文件清单

```
store/
├── README.md                       ← 本文档
├── APP_STORE_CONNECT.md            ← ⭐ ASC 全部填写内容(中英双语)
├── generate-screenshots.swift      ← 程序化生成 24 张截图
└── screenshots/
    ├── 1280x800/        ← 13" MacBook
    │   ├── 01-hero.png
    │   ├── 02-capture.png
    │   ├── 03-ocr.png
    │   ├── 04-clipboard.png
    │   ├── 05-snapshots.png
    │   └── 06-settings.png
    ├── 1440x900/        ← 13" MacBook Pro / Air
    ├── 2560x1600/       ← 13" Retina
    └── 2880x1800/       ← 15" Retina
```

## 使用方法

### 1. 看完 APP_STORE_CONNECT.md

里面有 11 个章节,涵盖:
- App Information(基础信息 + Age Rating + Export Compliance)
- Pricing & Availability(定价 + 可用区域)
- App Privacy(隐私问卷,**全 No**)
- 描述 / 关键词 / 更新说明 / 推广文本(中英双语)
- 隐私政策 / 支持 / EULA URL
- 给审核员的留言模板
- 提交清单 + 常见拒因预防

### 2. 上传截图

到 ASC → 你的 App → macOS → 添加新版本 → 截屏区域:

| 尺寸 Tab | 拖以下文件 |
|---------|----------|
| 12.9" Mac (1280×800) | `screenshots/1280x800/*.png` |
| 13" MacBook (1440×900) | `screenshots/1440x900/*.png` |
| 13" Retina (2560×1600) | `screenshots/2560x1600/*.png` |
| 15" Retina (2880×1800) | `screenshots/2880x1800/*.png` |

每个尺寸最多 10 张,我们提供 6 张,顺序为:
1. Hero(品牌定位)
2. Region Capture(区域选择)
3. OCR Result(识别结果)
4. Clipboard History(历史窗口)
5. Annotation(标注编辑)
6. Privacy(隐私承诺)

### 3. 部署 stub 页面

ASC 必填三个 URL:Marketing / Support / Privacy Policy。Stub 已生成:

- `website/index.html` → `https://pluck.app`
- `website/privacy.html` → `https://pluck.app/privacy.html`
- `website/terms.html` → `https://pluck.app/terms.html`(EULA 可选)
- `website/support.html` → `https://pluck.app/support.html`

部署到 Vercel / Cloudflare Pages / 自有 CDN 后,这些 URL 立即生效。

### 4. 重新生成截图

如果想改文案 / 配色 / 布局,改 `generate-screenshots.swift` 后跑:

```bash
cd /Users/dinglei/MyClaude/pluck
swift store/generate-screenshots.swift
```

24 PNG 会被覆盖。

## 提示:替换为真实运行截图

我们生成的是 marketing-style 营销图(品牌渐变 + 矢量 mockup)。
**App Store 不强制要求"真实运行截图"**,营销图完全可以用。但如果你想换:

1. 在 macOS 上 ⌘⇧4 + 空格,点 Pluck 窗口截图
2. 截到的图通常是 Retina(2x),对应 2560×1600 / 2880×1800 尺寸
3. 用 sips 缩到 1280×800 / 1440×900:
   ```bash
   sips -z 800 1280 source.png --out 1280x800.png
   ```
4. 替换 `screenshots/<尺寸>/0X-<场景>.png`

## App Preview(预览视频)

App Preview 必须是真实运行视频。**强烈建议先发不带 App Preview 的版本**,等 v0.2 时补。

如果一定要做:
- 时长 15-30 秒
- 同截图的 4 个尺寸,每个一份
- H.264 MP4
- 录屏:macOS 内置 ⌘⇧5 → 选录制全屏 → 选择麦克风 None
- 内容:截图 OCR 一气呵成的 demo

## App Icon

`Pluck.app` 内已嵌入 AppIcon(由 `scripts/generate-app-icon.swift` 生成的 10 个尺寸),Xcode Archive 时自动打进 .app bundle。**不需要单独上传给 ASC** — Apple 从 .app 里提取。

## 常见 ASC 问题

### Q: 为什么我的 App 上传后说"截屏尺寸不对"?

把 PNG 拖进 ASC 时,它会自动校验维度。本仓库生成的是精确像素(无 Retina 缩放),不会有问题。

如果手动截的图,确保:
- 没有 alpha 通道
- 无 Retina 双倍像素(用 sips 校验:`sips -g pixelWidth foo.png`)

### Q: 中国区审核问"未成年人模式"?

Pluck 是工具类、无 UGC、无社交,通常不会问。如果问了,回答:
- 本 App 不针对未成年人设计
- 不收集任何个人信息
- 无内容生产/分享/直播功能
- 不需要专门的未成年人模式

### Q: ASC "应用密钥" 是什么?

`SKU`(开发者内部唯一编号)。建议用 `PLUCK-MAC-001`。仅你能看到。

## 下一步

参考 `APP_STORE_CONNECT.md §8 提交清单` 一步步执行。
