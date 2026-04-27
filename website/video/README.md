# Hero 背景视频

`index.html` 的 hero 区会自动加载本目录的视频文件。文件不存在时,Vanta.js HALO 流光会自然兜底显示,**无需任何代码改动**。

## 必需文件

| 文件 | 必需? | 说明 |
|------|------|------|
| `bg.mp4` | **强烈建议** | 主视频,所有现代浏览器支持 |
| `bg.webm` | 可选 | 体积更小 30-40%,Chrome/FF 优先 |
| `poster.jpg` | 可选 | 视频加载前的占位静帧;不放也能用 |

## 推荐规格

- **分辨率**:1920×1080 或 1280×720(任何 16:9 都行,会被 `object-fit: cover` 裁切到铺满)
- **码率 / 文件大小**:**< 4 MB**(超过会拖慢首屏)— 用 720p H.264 就够了
- **时长**:**8-30 秒**;`loop` 会自动循环,无缝最佳
- **无声音**:`muted` 属性强制静音;可以原视频带音轨,反正不播
- **格式**:H.264 MP4(兼容性最好),可加一份 VP9 WebM 给现代浏览器

## 下载用户提到的 Pixabay 海鸥视频

1. 浏览器打开 https://pixabay.com/videos/gull-bird-snow-plumage-sitting-191159/
2. 点 "**免费下载**"(免登录)
3. 选 **Tiny 1280×720** 或 **Small 1920×1080** 下拉里的 MP4
4. 把下载的 MP4 改名为 `bg.mp4` 放到当前目录(`website/video/`)
5. 刷新 `index.html`,hero 背景就变成那个海鸥视频

> Pixabay 视频是 Pixabay License — 可商用、不需要署名,但建议在网站 footer 标一句"视频来源 Pixabay"作为友好。

## 备选(更契合 Pluck brand 的视频源)

海鸥很美但跟"Mac 截图 OCR"产品的气质有点远。如果想换更"科技/抽象/高级感"的:

### 1. Coverr.co(免费 + CC0)
- https://coverr.co/categories/abstract — 抽象流光
- https://coverr.co/categories/technology — 科技

直接下载 MP4,改名放到 `hero-bg.mp4`。

### 2. Pexels Videos(免费)
- https://www.pexels.com/zh-cn/search/videos/abstract%20blue/
- https://www.pexels.com/zh-cn/search/videos/code/

### 3. Mixkit(免费)
- https://mixkit.co/free-stock-video/abstract/
- https://mixkit.co/free-stock-video/computer/

### 4. 如果要"和示例完全一样的鸟类自然感":
- Pexels 鸟类页:https://www.pexels.com/zh-cn/search/videos/birds/
- Pixabay 海鸥页:https://pixabay.com/videos/search/seagull/

## 本地压缩工具

下载的视频如果太大,本地压一下:

### ffmpeg(推荐)

```bash
# H.264 MP4,720p,3 Mbps,无音轨,目标 < 4 MB
ffmpeg -i bg.mp4 \
  -vf "scale=1280:-2" \
  -c:v libx264 -preset slow -crf 26 -profile:v high -pix_fmt yuv420p \
  -an \
  -movflags +faststart \
  bg-compressed.mp4

# 满意后覆盖原文件
mv bg-compressed.mp4 bg.mp4

# 可选:再压一份 WebM(更小,Chrome/FF 优先用)
ffmpeg -i bg.mp4 \
  -c:v libvpx-vp9 -b:v 1.5M -an \
  bg.webm
```

`-movflags +faststart` 让浏览器边下边播,首屏更快。

### 在线压缩

- https://www.freeconvert.com/video-compressor
- https://www.veed.io/tools/video-compressor

## 生成 poster.jpg(可选但建议)

```bash
ffmpeg -i bg.mp4 -vframes 1 -q:v 2 poster.jpg
```

抽视频第 1 帧做占位图。

## 隐私 / 法律提醒

- **不要 hotlink**(直接 `<source src="https://cdn.pixabay.com/...">`)— 多数素材站 ToS 禁止
- **下载下来本地放**才是合规做法
- 视频文件不要 commit 进 git(已加 .gitignore)— 体积大,改用 CDN / Vercel Blob 部署

## 文件没放/加载失败会怎样?

- `<video>` 元素安静失败,占位高度为 0
- Vanta.js HALO 流光自然透出 — **用户体验不破**
- 控制台有 404 警告,但不影响渲染
