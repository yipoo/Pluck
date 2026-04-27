import AppKit
import Foundation

/// 截图完成后,在被截区域闪一下白光 — 仿 macOS 原生 ⌘⇧4 的反馈。
///
/// ⚠️ 内存生命周期注意:
/// - 强持有 NSWindow(activeWindows 数组),避免 [weak win] + isReleasedWhenClosed 默认 true
///   带来的 use-after-free → EXC_BAD_ACCESS
/// - 显式 isReleasedWhenClosed = false
/// - 动画完成时 orderOut + 从数组移除(此时才真正释放)
@MainActor
final class CaptureFlashController {

    /// 当前还在淡出动画中的窗口 — 强引用保活,直到 completion 移除
    private var activeWindows: [NSWindow] = []

    /// - Parameters:
    ///   - rect: 选区(display-local 坐标,top-left origin)
    ///   - displayID: 选区所在的物理显示器 ID
    func flash(rect: CGRect, displayID: CGDirectDisplayID) {
        let screen = NSScreen.screens.first(where: { $0.pluckDisplayID == displayID })
                  ?? NSScreen.main
        guard let screen else { return }

        // 坐标转换:display-local (top-left) → Cocoa global (bottom-left)
        let cocoaY = screen.frame.maxY - rect.origin.y - rect.height
        let flashFrame = NSRect(
            x: screen.frame.minX + rect.origin.x,
            y: cocoaY,
            width: rect.width,
            height: rect.height
        )

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
        win.isReleasedWhenClosed = false   // ⭐ 关键:不让 close() 自动释放,改由我们手动控制
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        win.orderFrontRegardless()

        // 强引用入数组保活
        activeWindows.append(win)

        // 渐隐 ~200ms,完成后从数组移除(此时 win 才真正释放)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.20
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            // NSAnimationContext completion 在主线程跑,可安全 assume MainActor
            MainActor.assumeIsolated {
                // 注意:不再用 [weak win] — 闭包强捕 win 直到 completion 跑完
                win.orderOut(nil)
                // 显式 close 让 NSApp 从窗口列表移除
                win.close()
                self?.activeWindows.removeAll(where: { $0 === win })
            }
        })
    }
}
