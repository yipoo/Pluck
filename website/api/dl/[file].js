// Vercel Function: pluck.yipoo.com/dl/<file> → 302 → Vercel Blob 公开 URL
//
// 工作原理:
//   1. 用 BLOB_READ_WRITE_TOKEN(env)调 Vercel Blob list API
//   2. 找到匹配 dl/<file> 的对象,拿它的真实 public URL
//   3. 302 重定向 — 浏览器自动跟随,直接从 Blob CDN 下载
//
// 优点:
//   - URL 永远在自己域名,即使切换托管也不动
//   - 升级版本(传新 blob)无需改 HTML
//   - 可以加 Cache-Control / 统计 / 限流
//
// 路由:配合 vercel.json 的 rewrite:
//   /dl/:file → /api/dl/:file

import { list } from '@vercel/blob';

export default async function handler(req, res) {
  const { file } = req.query;

  if (!file || typeof file !== 'string') {
    res.statusCode = 400;
    return res.end('Missing file parameter');
  }

  // 防 path traversal
  if (file.includes('/') || file.includes('..') || file.includes('\\')) {
    res.statusCode = 400;
    return res.end('Invalid file name');
  }

  const path = `dl/${file}`;

  try {
    // list({ prefix }) 在我们的 dl/ 目录下找匹配
    const { blobs } = await list({ prefix: path, limit: 5 });
    const blob = blobs.find((b) => b.pathname === path);

    if (!blob) {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      return res.end(
        `文件未找到:${path}\n\n` +
        `可能原因:\n` +
        `1. 文件名拼写有误\n` +
        `2. 文件还没上传到 Vercel Blob 的 dl/ 目录\n` +
        `3. 文件已被删除`
      );
    }

    // 设置 cache:5 分钟内 Vercel CDN 直接复用 302 响应
    res.setHeader('Cache-Control', 'public, max-age=300, s-maxage=300');
    // 让浏览器知道这是下载
    res.setHeader('Content-Disposition', `attachment; filename="${file}"`);
    res.statusCode = 302;
    res.setHeader('Location', blob.url);
    return res.end();
  } catch (err) {
    console.error('[dl proxy]', err);
    res.statusCode = 500;
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.end('内部错误,请稍后再试');
  }
}
