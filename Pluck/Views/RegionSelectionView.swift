import SwiftUI

/// 区域选择 SwiftUI 视图(由 RegionSelectionController 包在 NSWindow 里全屏覆盖)。
struct RegionSelectionView: View {
    let onComplete: (CGRect?) -> Void

    @State private var startPoint: CGPoint?
    @State private var currentPoint: CGPoint?

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // 半透明黑色蒙层 — 加深一些更明显
                Color.black.opacity(0.40)
                    .contentShape(Rectangle())

                if let s = startPoint, let c = currentPoint {
                    let r = Self.rect(s, c)

                    // 选区(白边 + 透明)
                    Rectangle()
                        .strokeBorder(Color.white, lineWidth: 1.5)
                        .background(Color.white.opacity(0.05))
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)

                    // 尺寸标签
                    Text("\(Int(r.width)) × \(Int(r.height))")
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .position(x: r.midX, y: max(r.minY - 14, 14))
                }

                // 中央提示(未开始拖动时)
                if startPoint == nil {
                    VStack(spacing: 4) {
                        Text("拖动选择区域 · ESC 取消")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .gesture(
                // ⭐ minimumDistance: 5 — 防止单击穿透事件被当成"零像素拖动"误触发结束
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if startPoint == nil {
                            print("[Pluck] drag begin at \(value.startLocation)")
                            startPoint = value.startLocation
                        }
                        currentPoint = value.location
                    }
                    .onEnded { value in
                        let s = startPoint ?? value.startLocation
                        let c = value.location
                        let r = Self.rect(s, c)
                        print("[Pluck] drag end, rect=\(r)")
                        if r.width > 5 && r.height > 5 {
                            onComplete(r)
                        } else {
                            // 极小拖动 — 当取消处理
                            print("[Pluck] rect too small, treating as cancel")
                            onComplete(nil)
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }

    private static func rect(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(a.x - b.x),
            height: abs(a.y - b.y)
        )
    }
}
