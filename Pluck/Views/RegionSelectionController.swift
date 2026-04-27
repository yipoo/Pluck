import AppKit
import SwiftUI
import CoreGraphics

/// 用户选区结果(包含 rect + 它在哪个显示器上)
struct CaptureSelection {
    /// 选区,**display-local 坐标**(top-left origin,相对 SCDisplay)
    let rect: CGRect
    /// 选中的物理显示器 ID,直传 ScreenCaptureKit
    let displayID: CGDirectDisplayID
}

/// 管理区域选择 overlay 的 NSWindow 生命周期。
@MainActor
final class RegionSelectionController {

    private var window: NSWindow?
    private var keyMonitor: Any?
    private var continuation: CheckedContinuation<CaptureSelection?, Never>?
    private var activeDisplayID: CGDirectDisplayID = 0

    func present() async -> CaptureSelection? {
        // ⭐ 关键:用鼠标当前所在的屏幕,而不是 NSScreen.main
        // (LSUIElement App 在多屏环境下 NSScreen.main 经常不是用户期望的那块)
        let mouseLoc = NSEvent.mouseLocation  // Cocoa global coords (bottom-left origin of primary)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) })
                  ?? NSScreen.main
        guard let screen else {
            print("[Pluck] RegionSelectionController.present: no screen!")
            return nil
        }
        let displayID = screen.pluckDisplayID
        self.activeDisplayID = displayID
        print("[Pluck] RegionSelectionController.present: cursor on screen \(displayID), frame=\(screen.frame), totalScreens=\(NSScreen.screens.count)")

        return await withCheckedContinuation { (cont: CheckedContinuation<CaptureSelection?, Never>) in
            self.continuation = cont

            let view = RegionSelectionView { [weak self] rect in
                print("[Pluck] RegionSelectionView completed with rect: \(String(describing: rect)) on display=\(self?.activeDisplayID ?? 0)")
                self?.finish(with: rect)
            }
            let hosting = NSHostingController(rootView: view)
            hosting.view.frame = NSRect(origin: .zero, size: screen.frame.size)

            let win = OverlayWindow(
                contentRect: screen.frame,    // Cocoa coords — 位于这块屏幕
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            win.contentViewController = hosting
            win.level = .screenSaver
            win.isOpaque = false
            win.backgroundColor = .clear
            win.hasShadow = false
            // ⭐ 关键:不让 close() 自动释放,我们手动控制 — 否则可能在 NSApp 还引用时被释放
            win.isReleasedWhenClosed = false
            win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            win.acceptsMouseMovedEvents = true
            win.hidesOnDeactivate = false
            // 防菜单栏 popover 关闭事件穿透
            win.ignoresMouseEvents = true

            self.window = win

            self.keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 { // ESC
                    print("[Pluck] ESC pressed, cancelling overlay")
                    self?.finish(with: nil)
                    return nil
                }
                return event
            }

            let prevPolicy = NSApp.activationPolicy()
            print("[Pluck] activation policy was: \(prevPolicy.rawValue), switching to .regular for overlay")
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)

            win.orderFrontRegardless()
            win.makeKeyAndOrderFront(nil)

            print("[Pluck] overlay window ordered front. visible=\(win.isVisible), key=\(win.isKeyWindow), level=\(win.level.rawValue), frame=\(win.frame)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak win] in
                guard let win else { return }
                win.ignoresMouseEvents = false
                win.makeKey()
                NSCursor.crosshair.push()
                print("[Pluck] overlay mouse events enabled, cursor → crosshair")
            }
        }
    }

    private func finish(with rect: CGRect?) {
        guard let cont = continuation else {
            print("[Pluck] finish called but continuation already nil (double-finish?)")
            return
        }
        continuation = nil

        NSCursor.pop()

        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        // ⭐ 关键:orderOut + close + nil 三连
        // 单 orderOut 会让窗口"半死不活"留在 NSApp 列表里,后续 popover 重开遍历窗口时可能触碰野指针
        // close() 会真正从 NSApp 列表移除;isReleasedWhenClosed=false → 我们仍持有强引用直到 nil 出
        if let win = window {
            win.orderOut(nil)
            win.close()
        }
        window = nil

        // 不再从 finish 直接切回 .accessory — AppDelegate 的 willCloseNotification 观察者会统一处理
        // 避免重复切换造成 NSApp 内部状态混乱

        if let rect {
            cont.resume(returning: CaptureSelection(rect: rect, displayID: activeDisplayID))
        } else {
            cont.resume(returning: nil)
        }
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - NSScreen helper

extension NSScreen {
    /// 物理显示器 ID,与 SCDisplay.displayID 对应
    var pluckDisplayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }
}
