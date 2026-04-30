// Vercel Function: pluck.yipoo.com/dl/<file> 下载代理
//
// 兼容两种 Blob 访问模式:
//   - 公开 Blob (public.blob.vercel-storage.com)  → 302 直接重定向(走 Vercel CDN,流量免费)
//   - 私有 Blob (private.blob.vercel-storage.com) → 用 token 拉文件 + 流式回传给浏览器
//
// 路由配合 vercel.json 的 rewrite:
//   /dl/:file → /api/dl/:file
//
// 升级版本:把新 DMG 上传到 Blob 的 dl/<同名>,HTML 不动

import { list } from '@vercel/blob';
import { Readable } from 'node:stream';

export default async function handler(req, res) {
  const { file } = req.query;

  // 输入校验
  if (
    !file ||
    typeof file !== 'string' ||
    file.includes('/') ||
    file.includes('..') ||
    file.includes('\\')
  ) {
    res.statusCode = 400;
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.end('Invalid file name');
  }

  const path = `dl/${file}`;

  try {
    const { blobs } = await list({ prefix: path, limit: 5 });
    const blob = blobs.find((b) => b.pathname === path);

    if (!blob) {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      return res.end(
        `文件未找到:${path}\n\n` +
        `请确认 Vercel Blob 的 dl/ 目录下有这个文件。`
      );
    }

    // 关键:看 URL 判断公开 / 私有
    const isPublic = blob.url.includes('public.blob.vercel-storage.com');

    // ===== 公开:直接 302,流量走 Vercel CDN =====
    if (isPublic) {
      res.setHeader('Cache-Control', 'public, max-age=300, s-maxage=300');
      res.setHeader('Content-Disposition', `attachment; filename="${file}"`);
      res.statusCode = 302;
      res.setHeader('Location', blob.url);
      return res.end();
    }

    // ===== 私有:函数加 token 拉,流式回传 =====
    const token = process.env.BLOB_READ_WRITE_TOKEN;
    if (!token) {
      res.statusCode = 500;
      return res.end('BLOB_READ_WRITE_TOKEN 未配置');
    }

    const upstream = await fetch(blob.url, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!upstream.ok || !upstream.body) {
      console.error('[dl] upstream error', upstream.status, upstream.statusText);
      res.statusCode = 502;
      return res.end(`Upstream Blob 取文件失败:${upstream.status}`);
    }

    // 透传 Content-Type / Length(尽量保留原始)
    const contentType =
      upstream.headers.get('content-type') || 'application/octet-stream';
    const contentLength = upstream.headers.get('content-length');
    res.setHeader('Content-Type', contentType);
    if (contentLength) res.setHeader('Content-Length', contentLength);
    res.setHeader('Content-Disposition', `attachment; filename="${file}"`);
    res.setHeader('Cache-Control', 'public, max-age=300, s-maxage=300');

    // WHATWG ReadableStream → Node.js stream → res(管道流式回传,不占内存)
    Readable.fromWeb(upstream.body).pipe(res);
  } catch (err) {
    console.error('[dl proxy] error:', err);
    if (!res.headersSent) {
      res.statusCode = 500;
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      return res.end('内部错误');
    }
    res.end();
  }
}

// 默认 Node.js runtime(边缘函数 Edge Runtime 不支持 node:stream)
// 流式响应不会被全部加载到内存,大文件也安全
