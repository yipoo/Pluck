import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {

    private var window: NSWindow?

    func presentIfNeeded(state: AppState) {
        guard !state.settings.hasCompletedOnboarding else { return }
        present(state: state)
    }

    func present(state: AppState) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = OnboardingView(onComplete: { [weak self] in
            self?.close()
        })
        .environmentObject(state)

        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.title = "欢迎使用 Pluck"
        win.setContentSize(NSSize(width: 520, height: 460))
        win.styleMask = [.titled, .closable]
        win.center()
        win.isReleasedWhenClosed = false

        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        window = win
    }

    func close() {
        window?.close()
        window = nil
    }
}
