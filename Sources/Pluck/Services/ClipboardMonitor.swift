import Foundation
import AppKit

/// 监听 NSPasteboard 变化(0.5s 轮询)。W5 任务。
/// 跳过自己写入的 + 跳过 ConcealedType。
final class ClipboardMonitor {

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let pollingInterval: TimeInterval = 0.5

    /// 标记为"自己写入"的私有 pasteboard type — 我们写剪贴板时附加这个 type,下次扫描时跳过
    static let ownWriteMarker = NSPasteboard.PasteboardType("com.dinglei.pluck.own-write")

    /// macOS 推荐的"敏感"标记 — 1Password 等密码管理器写入时使用,避免被剪贴板历史工具捕获
    static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    var onItemCaptured: ((CapturedItem) -> Void)?

    enum CapturedItem {
        case text(String)
        case image(NSImage)
        case file(URL)
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        // 跳过自己写入
        if pb.types?.contains(Self.ownWriteMarker) == true { return }
        // 跳过敏感
        if pb.types?.contains(Self.concealedType) == true { return }

        if let s = pb.string(forType: .string), !s.isEmpty {
            onItemCaptured?(.text(s))
            return
        }
        if let img = NSImage(pasteboard: pb) {
            onItemCaptured?(.image(img))
            return
        }
        if let url = pb.string(forType: .fileURL).flatMap(URL.init(string:)) {
            onItemCaptured?(.file(url))
            return
        }
    }

    /// 写剪贴板时调用,带上 ownWriteMarker。
    static func writeOwn(text: String) {
        let pb = NSPasteboard.general
        pb.declareTypes([.string, ownWriteMarker], owner: nil)
        pb.setString(text, forType: .string)
        pb.setString("", forType: ownWriteMarker)
    }
}
