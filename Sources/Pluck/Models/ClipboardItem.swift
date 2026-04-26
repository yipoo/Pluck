import Foundation

struct ClipboardItem: Identifiable, Hashable, Codable {
    enum Kind: String, Codable {
        case text
        case image
        case file
    }

    let id: UUID
    let kind: Kind
    /// kind == .text → 文本内容
    /// kind == .image → 缩略图描述(图片本体在 imagePath)
    /// kind == .file → 路径字符串
    let content: String
    /// 仅 kind == .image 时有效,文件存在 Storage.snapshotsDir
    let imagePath: String?
    let sourceApp: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        kind: Kind,
        content: String,
        imagePath: String? = nil,
        sourceApp: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.content = content
        self.imagePath = imagePath
        self.sourceApp = sourceApp
        self.createdAt = createdAt
    }
}
