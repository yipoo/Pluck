import AppKit
import Foundation

/// 截图完成后,在被截取区域闪一下白光 — 仿 macOS 原生 ⌘⇧4 的反馈。
/// 完全本地视觉,不阻塞主链路。
@MainActor
final class CaptureFlashController {

    /// - Parameters:
    ///   - rect: 选区 rect(display-local 坐标,top-left origin,即从 RegionSelectionController 拿到的)
    ///   - displayID: 选区所在的物理显示器 ID
    func flash(rect: CGRect, displayID: CGDirectDisplayID) {
        // 找到对应 NSScreen
        let screen = NSScreen.screens.first(where: { $0.pluckDisplayID == displayID })
                  ?? NSScreen.main
        guard let screen else { return }

        // ⭐ 坐标转换:display-local (top-left) → Cocoa global (bottom-left)
        let cocoaY = screen.frame.maxY - rect.origin.y - rect.height
        let flashFrame = NSRect(
            x: screen.frame.minX + rect.origin.x,
            y: cocoaY,
            width: rect.width,
            height: rect.height
        )

        // 白色闪光窗口
        let win = NSWindow(
            contentRect: flashFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.backgroundColor = .white
        win.isOpaque = false
        win.alphaValue = 0.55
        win.level = .screenSaver
        win.ignoresMouseEvents = true
        win.hasShadow = false
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        win.orderFrontRegardless()

        // 渐隐 ~200ms
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.20
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win.animator().alphaValue = 0
        }, completionHandler: { [weak win] in
            win?.orderOut(nil)
            win?.close()
        })
    }
}
