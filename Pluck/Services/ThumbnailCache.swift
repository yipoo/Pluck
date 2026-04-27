import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

/// 截图缩略图加载 + LRU 缓存。
/// 用 ImageIO 的 thumbnail API,只解码到目标尺寸 — 100KB-2MB 的 PNG 也能毫秒级出图。
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 200          // 最多缓存 200 张缩略图
        cache.totalCostLimit = 50_000_000 // 50MB 上限
    }

    /// 取缩略图 — 缓存命中即返回,否则解码后缓存
    func thumbnail(for url: URL, maxDimension: Int = 200) -> NSImage? {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) { return cached }
        guard let img = Self.loadThumbnail(at: url, maxDimension: maxDimension) else { return nil }
        cache.setObject(img, forKey: key, cost: Int(img.size.width * img.size.height) * 4)
        return img
    }

    /// 删除单个缓存(配合文件删除)
    func invalidate(_ url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }

    /// 全部清空
    func clearAll() {
        cache.removeAllObjects()
    }

    // MARK: - Private

    private static func loadThumbnail(at url: URL, maxDimension: Int) -> NSImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: .zero)
    }
}
