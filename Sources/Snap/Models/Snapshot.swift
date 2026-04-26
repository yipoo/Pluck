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

struct Annotation: Hashable, Codable {
    enum Kind: String, Codable {
        case rect
        case arrow
        case text
        case mosaic
        case highlight
    }

    let kind: Kind
    let bounds: CGRect
    var text: String?       // kind == .text
    var colorHex: String?   // "#RRGGBB"
}
