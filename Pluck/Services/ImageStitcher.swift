import Foundation
import AppKit
import CoreGraphics
import Accelerate

/// 垂直长截图拼接算法。
///
/// 思路:
/// 1. 假定多张截图同宽(同一区域反复抓)
/// 2. 对相邻两张找垂直重叠 — 比较 prev 底部 N 行 vs next 顶部 N 行,找 SSD 最小的偏移
/// 3. 按检测到的偏移把 next 拼到 prev 下方,扣除重叠
///
/// 不打算做完美 — 真实滚动 App 中:
/// - sticky header 会破坏算法 → 后续可加忽略顶部 X% 高度
/// - 动态加载 / 抖动 → 后续可加 fuzzy match
enum ImageStitcher {

    /// 拼接给定 CGImage 数组,返回单张长图。空输入返回 nil。
    /// - Parameter overlapWindow: 搜索重叠的最大窗口高度(像素)。默认 200。
    /// - Parameter sampleRows: 每行采样的像素数(降采样用,提速)。默认 32。
    static func stitch(_ images: [CGImage], overlapWindow: Int = 200, sampleRows: Int = 32) -> CGImage? {
        guard !images.isEmpty else { return nil }
        if images.count == 1 { return images[0] }

        // 验证同宽
        let baseWidth = images[0].width
        for img in images where img.width != baseWidth {
            // 不同宽度直接返回 nil — 调用方决定怎么处理
            return nil
        }

        var stitched = images[0]
        for i in 1..<images.count {
            guard let merged = mergeOne(prev: stitched, next: images[i],
                                        overlapWindow: overlapWindow,
                                        sampleRows: sampleRows) else {
                return nil
            }
            stitched = merged
        }
        return stitched
    }

    // MARK: - 单步合并

    private static func mergeOne(prev: CGImage, next: CGImage,
                                 overlapWindow: Int,
                                 sampleRows: Int) -> CGImage? {
        let w = prev.width
        let prevH = prev.height
        let nextH = next.height
        guard w > 0, prevH > 0, nextH > 0 else { return nil }

        // 取 prev 的最后 overlapWindow 行(或全部),与 next 的前 overlapWindow 行做对齐
        let searchH = min(overlapWindow, prevH, nextH)
        guard searchH > 0 else { return nil }

        guard let prevTail = grayPixels(of: prev, fromY: prevH - searchH, height: searchH, sampleCols: sampleRows) else {
            return nil
        }
        guard let nextHead = grayPixels(of: next, fromY: 0, height: searchH, sampleCols: sampleRows) else {
            return nil
        }

        // 找最优偏移 offset:next 顶部 offset 行就是 prev 尾部最后 (searchH - offset) 行
        var bestOffset = 0
        var bestScore: Double = .infinity
        let cols = sampleRows
        for offset in 0..<(searchH - 4) { // 至少剩 4 行用来匹配
            let rowsToCompare = searchH - offset
            // SSD over rowsToCompare rows of `cols` samples each
            // prev 用 [offset..<searchH] 行,对比 next 的 [0..<rowsToCompare] 行
            var sum: Double = 0
            for r in 0..<rowsToCompare {
                let pIdx = (offset + r) * cols
                let nIdx = r * cols
                for c in 0..<cols {
                    let d = Double(prevTail[pIdx + c]) - Double(nextHead[nIdx + c])
                    sum += d * d
                }
            }
            // 归一化(否则 offset 大的总分小)
            let normalized = sum / Double(rowsToCompare * cols)
            if normalized < bestScore {
                bestScore = normalized
                bestOffset = offset
            }
        }
        // bestOffset = next 头部和 prev 尾部对齐的偏移(即 prev 最后 searchH 行的第 bestOffset 行 ≈ next 第 0 行)
        // → next 真正"新增"的内容从 next 的 (searchH - bestOffset) 行开始
        let newPart = searchH - bestOffset
        let nextNewHeight = nextH - newPart
        guard nextNewHeight > 0 else {
            // 完全重叠或 next 比 prev 短,直接返回 prev
            return prev
        }

        // 创建新画布:prev + next 后续行
        let outH = prevH + nextNewHeight
        let bytesPerRow = w * 4
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: w, height: outH,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else { return nil }

        // 注意 CG 坐标:bottom-left origin。我们想要 prev 在顶部 → 用翻转
        ctx.translateBy(x: 0, y: CGFloat(outH))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(prev, in: CGRect(x: 0, y: 0, width: w, height: prevH))
        // next 的下半段(跳过重叠 newPart 行)
        ctx.draw(next, in: CGRect(x: 0, y: prevH - newPart, width: w, height: nextH))

        return ctx.makeImage()
    }

    // MARK: - 工具:把 CGImage 子区域转灰度采样

    /// 取图像 [fromY, fromY+height) 行,每行采 sampleCols 个等距像素,返回 UInt8 灰度数组。
    private static func grayPixels(of image: CGImage, fromY: Int, height: Int, sampleCols: Int) -> [UInt8]? {
        let w = image.width
        guard fromY >= 0, height > 0, fromY + height <= image.height, sampleCols > 0 else { return nil }

        // 整行渲染到 RGBA 缓冲 → 抽取灰度
        let bytesPerRow = w * 4
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        var buffer = [UInt8](repeating: 0, count: w * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()

        guard let ctx = buffer.withUnsafeMutableBytes({ ptr -> CGContext? in
            CGContext(data: ptr.baseAddress,
                      width: w, height: height,
                      bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                      space: space, bitmapInfo: bitmapInfo)
        }) else { return nil }

        // 截取的 sub-image
        guard let sub = image.cropping(to: CGRect(x: 0, y: fromY, width: w, height: height)) else { return nil }
        ctx.draw(sub, in: CGRect(x: 0, y: 0, width: w, height: height))

        // 等距采样 sampleCols 个点,降低复杂度
        let step = max(1, w / sampleCols)
        var result = [UInt8](repeating: 0, count: height * sampleCols)
        for y in 0..<height {
            for c in 0..<sampleCols {
                let x = min(w - 1, c * step)
                let idx = (y * w + x) * 4
                let r = buffer[idx]
                let g = buffer[idx + 1]
                let b = buffer[idx + 2]
                // 经典灰度系数
                let gray = (UInt32(r) * 30 + UInt32(g) * 59 + UInt32(b) * 11) / 100
                result[y * sampleCols + c] = UInt8(gray)
            }
        }
        return result
    }
}
