import Foundation
import CoreGraphics

struct Snapshot: Identifiable, Hashable, Codable {
    let id: UUID
    let imagePath: String      // 相对 Storage.snapshotsDir
    var ocrText: String?
    var annotations: [Annotation]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        imagePath: String,
        ocrText: String? = nil,
        annotations: [Annotation] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imagePath = imagePath
        self.ocrText = ocrText
        self.annotations = annotations
        self.createdAt = createdAt
    }
}

struct Annotation: Identifiable, Hashable, Codable {
    enum Kind: String, Codable, CaseIterable {
        case rect
        case arrow
        case text
        case mosaic
        case highlight
    }

    /// 描边宽度(像素 — 在归一化坐标里其实是相对值,渲染时再换算)
    enum Stroke: Int, Codable, CaseIterable, Identifiable {
        case small = 2
        case medium = 4
        case large = 7
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .small: return "细"
            case .medium: return "中"
            case .large: return "粗"
            }
        }
    }

    let id: UUID
    let kind: Kind
    /// 归一化坐标:[0..1] × [0..1] 相对截图尺寸 — 缩放预览不会失真
    let bounds: CGRect
    var text: String?           // kind == .text
    var colorHex: String        // "#RRGGBB"
    var strokeWidth: Stroke

    init(
        id: UUID = UUID(),
        kind: Kind,
        bounds: CGRect,
        text: String? = nil,
        colorHex: String = "#FF3B30",
        strokeWidth: Stroke = .medium
    ) {
        self.id = id
        self.kind = kind
        self.bounds = bounds
        self.text = text
        self.colorHex = colorHex
        self.strokeWidth = strokeWidth
    }
}

// MARK: - Hex 颜色解析

extension Annotation {
    /// 调色盘候选(配合工具栏)
    static let palette: [(name: String, hex: String)] = [
        ("红",  "#FF3B30"),
        ("橙",  "#FF9500"),
        ("黄",  "#FFCC00"),
        ("绿",  "#34C759"),
        ("蓝",  "#0066E6"),
        ("紫",  "#AF52DE"),
        ("白",  "#FFFFFF"),
        ("黑",  "#1D1F23"),
    ]
}
