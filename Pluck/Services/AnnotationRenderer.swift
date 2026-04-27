import Foundation
import AppKit
import CoreGraphics

/// 把 annotations 烧录到底图上,导出新的 PNG。
/// 与 AnnotationCanvas 的 SwiftUI 视图绘制保持视觉一致(颜色 / 线宽 / 箭头形状)。
enum AnnotationRenderer {

    /// 渲染 — 返回带标注的 CGImage。失败返回 nil。
    /// - Parameter image: 底图
    /// - Parameter annotations: bounds 是归一化坐标 [0..1]
    static func render(image: CGImage, with annotations: [Annotation]) -> CGImage? {
        let w = image.width
        let h = image.height
        guard w > 0, h > 0 else { return nil }

        let bytesPerRow = w * 4
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else { return nil }

        // 1. 画底图
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        // 2. CG 坐标默认是底-左原点,而 SwiftUI/UI 我们用左-上,需翻转 Y
        context.translateBy(x: 0, y: CGFloat(h))
        context.scaleBy(x: 1, y: -1)

        // 3. 逐个画 annotation
        for ann in annotations {
            drawAnnotation(ann, in: context, imageSize: CGSize(width: w, height: h))
        }

        return context.makeImage()
    }

    /// 写 PNG
    @discardableResult
    static func writePNG(_ cg: CGImage, to url: URL) -> Bool {
        let rep = NSBitmapImageRep(cgImage: cg)
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        return (try? data.write(to: url, options: .atomic)) != nil
    }

    // MARK: - 私有

    private static func drawAnnotation(_ ann: Annotation, in ctx: CGContext, imageSize: CGSize) {
        // 反归一化
        let r = CGRect(
            x: ann.bounds.origin.x * imageSize.width,
            y: ann.bounds.origin.y * imageSize.height,
            width: ann.bounds.size.width * imageSize.width,
            height: ann.bounds.size.height * imageSize.height
        )
        let color = NSColor(hexString: ann.colorHex) ?? .red
        let lineWidth = CGFloat(ann.strokeWidth.rawValue)

        ctx.saveGState()
        defer { ctx.restoreGState() }

        switch ann.kind {
        case .rect:
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.stroke(r)

        case .highlight:
            ctx.setFillColor(color.withAlphaComponent(0.35).cgColor)
            ctx.fill(r)

        case .arrow:
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            let start = r.origin
            let end = CGPoint(x: r.maxX, y: r.maxY)
            ctx.move(to: start)
            ctx.addLine(to: end)

            // 箭头头
            let headSize = max(10, lineWidth * 3)
            let dx = end.x - start.x
            let dy = end.y - start.y
            let len = max(sqrt(dx * dx + dy * dy), 1)
            let ux = dx / len
            let uy = dy / len
            let angle: CGFloat = .pi * 5 / 6
            let leftWing = CGPoint(
                x: end.x + headSize * (ux * cos(angle) - uy * sin(angle)),
                y: end.y + headSize * (ux * sin(angle) + uy * cos(angle))
            )
            let rightWing = CGPoint(
                x: end.x + headSize * (ux * cos(-angle) - uy * sin(-angle)),
                y: end.y + headSize * (ux * sin(-angle) + uy * cos(-angle))
            )
            ctx.move(to: end)
            ctx.addLine(to: leftWing)
            ctx.move(to: end)
            ctx.addLine(to: rightWing)
            ctx.strokePath()

        case .text:
            guard let text = ann.text, !text.isEmpty else { break }
            let fontSize = max(14, lineWidth * 4)
            let attr: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: color
            ]
            let str = NSAttributedString(string: text, attributes: attr)

            // CG 已翻转,要再翻一次让文字正向
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.midY)
            ctx.scaleBy(x: 1, y: -1)
            let lineSize = str.size()
            let drawPoint = CGPoint(x: -lineSize.width / 2, y: -lineSize.height / 2)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
            str.draw(at: drawPoint)
            NSGraphicsContext.restoreGraphicsState()
            ctx.restoreGState()

        case .mosaic:
            // v0.3:这里应用 CIPixellate;v0.2 占位画灰色棋盘
            ctx.setFillColor(NSColor.gray.withAlphaComponent(0.55).cgColor)
            ctx.fill(r)
        }
    }
}

// MARK: - NSColor hex 扩展

extension NSColor {
    convenience init?(hexString: String) {
        let s = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = CGFloat((v >> 16) & 0xFF) / 255
        let g = CGFloat((v >> 8) & 0xFF) / 255
        let b = CGFloat(v & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
