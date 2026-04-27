import SwiftUI
import AppKit

/// 标注画布:在底图之上绘制 + 接受鼠标拖动来添加标注。
/// 坐标:用归一化 [0..1] × [0..1] 存储 annotations,渲染时按容器尺寸映射。
struct AnnotationCanvas: View {
    @Binding var annotations: [Annotation]
    let tool: Annotation.Kind?
    let color: String
    let stroke: Annotation.Stroke

    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var pendingTextEdit: UUID?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack(alignment: .topLeading) {
                // 透明捕获层
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(dragGesture(canvasSize: size))

                // 已有 annotations
                ForEach(annotations) { ann in
                    annotationView(ann, in: size)
                }

                // 进行中的预览
                if let ds = dragStart, let dc = dragCurrent, let tool {
                    let rect = Self.normalizedRect(from: ds, to: dc, in: size)
                    annotationView(
                        Annotation(kind: tool, bounds: rect, colorHex: color, strokeWidth: stroke),
                        in: size,
                        isPreview: true
                    )
                }
            }
        }
    }

    // MARK: - 单个 annotation 渲染

    @ViewBuilder
    private func annotationView(_ ann: Annotation, in size: CGSize, isPreview: Bool = false) -> some View {
        let absRect = CGRect(
            x: ann.bounds.origin.x * size.width,
            y: ann.bounds.origin.y * size.height,
            width: ann.bounds.size.width * size.width,
            height: ann.bounds.size.height * size.height
        )
        let color = Color(hex: ann.colorHex)
        let lineWidth = CGFloat(ann.strokeWidth.rawValue)

        switch ann.kind {
        case .rect:
            Rectangle()
                .strokeBorder(color, lineWidth: lineWidth)
                .frame(width: absRect.width, height: absRect.height)
                .position(x: absRect.midX, y: absRect.midY)
                .opacity(isPreview ? 0.7 : 1)

        case .highlight:
            Rectangle()
                .fill(color.opacity(0.35))
                .frame(width: absRect.width, height: absRect.height)
                .position(x: absRect.midX, y: absRect.midY)
                .opacity(isPreview ? 0.5 : 1)

        case .arrow:
            ArrowShape(start: absRect.origin,
                       end: CGPoint(x: absRect.maxX, y: absRect.maxY),
                       headSize: max(10, lineWidth * 3))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .opacity(isPreview ? 0.7 : 1)

        case .text:
            if let text = ann.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: max(14, lineWidth * 4), weight: .semibold))
                    .foregroundStyle(color)
                    .padding(4)
                    .position(x: absRect.midX, y: absRect.midY)
            } else if isPreview {
                Rectangle()
                    .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: max(absRect.width, 60), height: max(absRect.height, 24))
                    .position(x: absRect.midX, y: absRect.midY)
            }

        case .mosaic:
            // v0.3 — 真正像素化需要在导出时由 AnnotationRenderer 用 CIPixellate 处理
            // 这里画布预览用半透明灰格子作占位
            MosaicPreview()
                .frame(width: absRect.width, height: absRect.height)
                .position(x: absRect.midX, y: absRect.midY)
                .opacity(isPreview ? 0.6 : 1)
        }
    }

    // MARK: - 手势

    private func dragGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard tool != nil else { return }
                if dragStart == nil { dragStart = value.startLocation }
                dragCurrent = value.location
            }
            .onEnded { value in
                guard let tool, let start = dragStart else { return }
                let end = value.location
                let rect = Self.normalizedRect(from: start, to: end, in: canvasSize)
                // 太小的视为误操作
                if rect.width * canvasSize.width > 5 || rect.height * canvasSize.height > 5 {
                    let ann = Annotation(kind: tool, bounds: rect, colorHex: color, strokeWidth: stroke)
                    annotations.append(ann)
                    if tool == .text {
                        pendingTextEdit = ann.id
                    }
                }
                dragStart = nil
                dragCurrent = nil
            }
    }

    // 把两点变成归一化矩形
    private static func normalizedRect(from a: CGPoint, to b: CGPoint, in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        let abs = CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(a.x - b.x),
            height: abs(a.y - b.y)
        )
        return CGRect(
            x: abs.origin.x / size.width,
            y: abs.origin.y / size.height,
            width: abs.size.width / size.width,
            height: abs.size.height / size.height
        )
    }
}

// MARK: - 工具:箭头 Shape

struct ArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint
    let headSize: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: start)
        p.addLine(to: end)

        // 箭头头部
        let dx = end.x - start.x
        let dy = end.y - start.y
        let len = max(sqrt(dx * dx + dy * dy), 1)
        let ux = dx / len
        let uy = dy / len

        // 旋转 ±150° 得到两个翼
        let angle: CGFloat = .pi * 5 / 6
        let cosA = cos(angle), sinA = sin(angle)
        let cosNA = cos(-angle), sinNA = sin(-angle)

        let leftWing = CGPoint(
            x: end.x + headSize * (ux * cosA - uy * sinA),
            y: end.y + headSize * (ux * sinA + uy * cosA)
        )
        let rightWing = CGPoint(
            x: end.x + headSize * (ux * cosNA - uy * sinNA),
            y: end.y + headSize * (ux * sinNA + uy * cosNA)
        )

        p.move(to: end)
        p.addLine(to: leftWing)
        p.move(to: end)
        p.addLine(to: rightWing)
        return p
    }
}

// MARK: - 马赛克占位

private struct MosaicPreview: View {
    var body: some View {
        Canvas { ctx, size in
            let tile: CGFloat = 8
            let cols = Int(ceil(size.width / tile))
            let rows = Int(ceil(size.height / tile))
            for r in 0..<rows {
                for c in 0..<cols {
                    let alpha = Double((r * 7 + c * 11) % 5) / 5.0 * 0.5 + 0.25
                    let rect = CGRect(x: CGFloat(c) * tile, y: CGFloat(r) * tile, width: tile, height: tile)
                    ctx.fill(Path(rect), with: .color(.gray.opacity(alpha)))
                }
            }
        }
    }
}

// MARK: - SwiftUI Color 扩展(从 hex 解析)

extension Color {
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard s.count == 6, let value = UInt32(s, radix: 16) else {
            self = .red
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
