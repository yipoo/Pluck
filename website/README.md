# Pluck 官网

零打包依赖。HTML + CSS + 几十行原生 JS。
**Cinematic 动画背景** 通过 CDN 远程拉 Vanta.js + three.js,无需 npm。

## 部署

### Vercel(推荐,免费)

```bash
cd website/
npx vercel --prod
```

### Cloudflare Pages

```bash
npx wrangler pages deploy website
```

### GitHub Pages

```bash
# 确保仓库 Settings → Pages 启用 main 分支 / website/
git push origin main
```

### 自有 CDN

直接 rsync 上传:

```bash
rsync -avz --delete website/ user@server:/var/www/pluck/
```

## 文件清单

```
website/
├── index.html       # 主页
├── styles.css       # 样式(暗色模式自动适配)
├── README.md        # 本文档
│
├── dl/              # ⚠️ 把 DMG 放这下
│   └── Pluck-0.1.0.dmg
├── appcast.xml      # ⚠️ Sparkle 自动更新源(见 docs/SPARKLE.md)
├── changelog.html   # 待写
├── privacy.html     # 待写
├── terms.html       # 待写
├── docs.html        # 待写
└── favicon.png      # 32x32 favicon(用 generate-app-icon 同款 brand)
```

## 待补内容

- [ ] DMG 实际部署到 `dl/`
- [ ] `appcast.xml`(每次发版手维护)
- [ ] `changelog.html` / `privacy.html` / `terms.html` / `docs.html`
- [ ] Open Graph 图片(1200x630)
- [ ] favicon 生成(可截 AppIcon 32x32 PNG)

## 修改文案

文案集中在 `index.html` 里,关键区段用 HTML 注释划分:Nav / Hero / Features / Privacy / Download / FAQ / Footer。

## 设计语言

- 字体:SF Pro / PingFang(系统默认)
- 主色:`#0066e6`(与 App 内 accentColor 同源)
- 暗色模式:用 `prefers-color-scheme` 自动切换
- 卡片:1px border + 16px 圆角 + 微阴影
- 排版:macOS 风格密度(行高 1.6,字号 14-17)

风格与 App 内一致:渐变 brand mark / 圆角卡片 / 类型徽章 / 大标题 letter-spacing -0.02。

## 动画(Cinematic)

Hero 区:
- **Vanta.js HALO** WebGL 渐变流光 — 通过 jsDelivr CDN 拉(`three@0.134.0` + `vanta@0.5.24`)
- 顶 / 底渐隐遮罩(`.hero-veil`),让 nav 区与下方浅色区平滑衔接
- 鼠标移入有视差响应(Vanta 内置 `mouseControls: true`)
- 底部"向下滚动"鼠标 icon + wheel 动画(纯 CSS keyframes)

内容区:
- **Intersection Observer** 滚动揭示(`.reveal` → `.is-revealed`,opacity + translateY 0.7s 缓动)
- 元素可加 `data-reveal-delay="160"` 错开节奏
- Hero mockup 浮动(CSS keyframes 6s 上下 6px)+ 滚动视差(JS 算 0.18 倍速度上移)

### 调主题色

`index.html` 底部脚本里改:
```js
VANTA.HALO({
  baseColor: 0x0066e6,        // ← Pluck 蓝;改这俩参数即换主色
  backgroundColor: 0x05080f,  // ← 深色基底
  amplitudeFactor: 1.4,
  size: 1.5
})
```

可换的 Vanta 效果(改 `vanta.halo.min.js` 路径 + 调用名):
- `vanta.waves.min.js` → `VANTA.WAVES` — 流动波纹
- `vanta.fog.min.js` → `VANTA.FOG` — 软云雾
- `vanta.net.min.js` → `VANTA.NET` — 连线网格(科技感)
- `vanta.birds.min.js` → `VANTA.BIRDS` — 飞鸟群
- `vanta.dots.min.js` → `VANTA.DOTS` — 点阵
- `vanta.cells.min.js` → `VANTA.CELLS` — 有机细胞
- `vanta.globe.min.js` → `VANTA.GLOBE` — 旋转地球

### 无障碍

`prefers-reduced-motion: reduce` 用户:
- Vanta 不初始化
- `.reveal` 直接显示
- mockup 浮动 / 滚动鼠标动画停止
- mockup 视差不绑 scroll 监听
