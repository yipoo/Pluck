# Pluck 官网

零依赖纯 HTML + CSS,可直接放到任何静态托管。

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
