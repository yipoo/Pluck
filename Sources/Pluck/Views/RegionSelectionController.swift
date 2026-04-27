import AppKit
import SwiftUI

/// 管理区域选择 overlay 的 NSWindow 生命周期。
/// 调用 `present()` 异步返回用户选定的 CGRect(SwiftUI 视图坐标系,原点左上)— 等同主显示器的 CGDisplay 坐标。
@MainActor
final class RegionSelectionController {

    private var window: NSWindow?
    private var keyMonitor: Any?
    private var continuation: CheckedContinuation<CGRect?, Never>?

    func present() async -> CGRect? {
        guard let screen = NSScreen.main else { return nil }

        return await withCheckedContinuation { (cont: CheckedContinuation<CGRect?, Never>) in
            self.continuation = cont

            let view = RegionSelectionView { [weak self] rect in
                self?.finish(with: rect)
            }
            let hosting = NSHostingController(rootView: view)

            let win = OverlayWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            win.contentViewController = hosting
            win.level = .screenSaver
            win.isOpaque = false
            win.backgroundColor = .clear
            win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            win.ignoresMouseEvents = false
            win.acceptsMouseMovedEvents = true

            self.window = win

            // ESC 取消
            self.keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 { // ESC
                    self?.finish(with: nil)
                    return nil
                }
                return event
            }

            NSApp.activate(ignoringOtherApps: true)
            win.makeKeyAndOrderFront(nil)
        }
    }

    private func finish(with rect: CGRect?) {
        guard let cont = continuation else { return }
        continuation = nil

        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        window?.orderOut(nil)
        window = nil

        cont.resume(returning: rect)
    }
}

/// 借此让 borderless 窗口能成为 key,从而接收键盘事件
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
