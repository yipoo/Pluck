# Vercel Functions

## `dl/[file].js` — DMG 下载代理

将 `pluck.yipoo.com/dl/Pluck-0.1.0.dmg` 这类 URL 自动适配两种 Blob 模式:

| Blob 类型 | URL 特征 | 处理方式 | 流量经过 |
|---------|--------|--------|---------|
| **公开** | `public.blob.vercel-storage.com` | **302 重定向** | Vercel CDN(免费快速) |
| **私有** | `private.blob.vercel-storage.com` | **函数加 token 拉 + 流式回传** | Function 计算时间 |

⭐ **强烈建议把 Blob 设为公开** — 速度快、不耗 Function 配额。私有适合敏感文件(我们这是公开 DMG,无需私有)。

### 工作流

```
用户浏览器                         Vercel(你的项目)         Vercel Blob 存储
   │                                    │                         │
   │  GET /dl/Pluck-0.1.0.dmg           │                         │
   │ ─────────────────────────────────▶ │                         │
   │                                    │  vercel.json rewrite     │
   │                                    │  → /api/dl/Pluck-0.1.0.dmg
   │                                    │                         │
   │                                    │  list({ prefix:'dl/...' })
   │                                    │ ──────────────────────▶ │
   │                                    │  返回 blob.url(public) │
   │                                    │ ◀────────────────────── │
   │  302 → blob.vercel-storage.com/...  │                         │
   │ ◀───────────────────────────────── │                         │
   │                                                              │
   │  GET https://blob.vercel-storage.com/dl/Pluck-0.1.0.dmg     │
   │ ──────────────────────────────────────────────────────────▶ │
   │  返回 DMG 文件                                                │
   │ ◀────────────────────────────────────────────────────────── │
```

### 部署要求

1. Vercel project 链接到此仓库的 `website/` 子目录
2. **Storage → Blob** 已开启,且 `BLOB_READ_WRITE_TOKEN` 自动写入了 Project Environment Variables(默认行为)
3. DMG 文件已上传到 Blob 的 `dl/Pluck-X.Y.Z.dmg` 路径

### 环境变量

| Name | Source | 用途 |
|------|--------|------|
| `BLOB_READ_WRITE_TOKEN` | Vercel Blob 集成自动注入 | Function 运行时调 list API |

不需要手动设置,Vercel Storage 集成会自动写到 project env。

### 升级新版

只需要把新 DMG 上传到 Blob 的同样路径(覆盖)或新文件名(`dl/Pluck-0.2.0.dmg`),然后:
- 同名:用户 URL 不变,自动拿到新版
- 新名:改 `index.html` 里下载按钮的 `href`(或加 `latest.dmg` 永久指向最新)

### 测试

部署后:

```bash
curl -I https://pluck.yipoo.com/dl/Pluck-0.1.0.dmg
```

应该看到:
```
HTTP/2 302
location: https://<random>.public.blob.vercel-storage.com/dl/Pluck-0.1.0.dmg
content-disposition: attachment; filename="Pluck-0.1.0.dmg"
cache-control: public, max-age=300, s-maxage=300
```

直接访问浏览器 → 自动开始下载。

### 错误处理

- `400 Missing file parameter` — URL 路径里没文件名
- `400 Invalid file name` — 文件名包含 `/` `..` `\\`(防 path traversal)
- `404 文件未找到` — Blob 里没这个文件,前端会看到友好提示
- `500 内部错误` — Blob API 调用失败(token 无效 / 网络问题)

### 本地开发

```bash
cd website
npm install
npx vercel dev
# 浏览器访问 http://localhost:3000/dl/Pluck-0.1.0.dmg
```
