import AppKit
import SwiftUI

/// 管理"历史"窗口的开关。
@MainActor
final class HistoryWindowController {

    private var window: NSWindow?
    private var closeObserver: NSObjectProtocol?

    /// 切换:已开 → 关闭;未开 → 打开
    func toggle(state: AppState) {
        if window != nil {
            close()
        } else {
            present(state: state)
        }
    }

    func present(state: AppState) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = HistoryView().environmentObject(state)
        let hosting = NSHostingController(rootView: view)

        let win = NSWindow(contentViewController: hosting)
        win.title = "Pluck"
        win.setContentSize(NSSize(width: 1100, height: 680))
        win.minSize = NSSize(width: 900, height: 540)
        win.styleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        win.titleVisibility = .visible
        win.titlebarAppearsTransparent = false
        win.center()
        win.isReleasedWhenClosed = false
        win.identifier = NSUserInterfaceItemIdentifier("pluck.history.window")

        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: win,
            queue: .main
        ) { [weak self] _ in
            // queue: .main 保证回调在主线程,可安全 assume MainActor
            MainActor.assumeIsolated {
                self?.window = nil
                if let obs = self?.closeObserver {
                    NotificationCenter.default.removeObserver(obs)
                    self?.closeObserver = nil
                }
            }
        }

        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        window = win
    }

    func close() {
        window?.close()
        window = nil
    }
}
