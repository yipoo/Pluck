import SwiftUI
import AppKit
import CoreGraphics

@main
struct PluckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(delegate.state)
        } label: {
            MenuBarLabel()
                .environmentObject(delegate.state)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(delegate.state)
        }
    }
}

/// AppDelegate 负责 bootstrap 时机控制(早于第一个 Scene 渲染)
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private var windowCloseObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[Pluck] applicationDidFinishLaunching")

        // 请求通知权限(静默 — 用户拒绝就拒绝)
        NotificationService.requestAuthorization()

        // ⭐ 主动请求屏幕录制权限 — 触发系统弹窗(必须有 Info.plist 的 NSScreenCaptureUsageDescription)
        let hasScreenAccess = CGPreflightScreenCaptureAccess()
        print("[Pluck] CGPreflightScreenCaptureAccess() = \(hasScreenAccess)")
        if !hasScreenAccess {
            print("[Pluck] 主动请求屏幕录制权限...")
            let granted = CGRequestScreenCaptureAccess()
            print("[Pluck] CGRequestScreenCaptureAccess() = \(granted)")
        }

        // 实例化所有 service + 注册热键
        Task { @MainActor in
            print("[Pluck] bootstrapServices begin")
            state.bootstrapServices()
            print("[Pluck] bootstrapServices done, isReady=\(state.isReady), lastError=\(state.lastError ?? "nil")")
        }

        // ⭐ 监听窗口关闭 → 没有可见 content 窗口时,把激活策略改回 .accessory
        // 解决:打开"设置"或"历史"会切到 .regular 让 Dock 出图标,关闭后要隐回去
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                let visibleContentWindows = NSApp.windows.filter { win in
                    win.isVisible
                    && win.contentViewController != nil
                    && !win.styleMask.contains(.borderless)        // 排除区域选择 overlay
                    && win.level == .normal                        // 排除 .floating 长截图浮窗
                    && !(win.className.contains("Popover"))        // 排除 MenuBarExtra popover
                }
                if visibleContentWindows.isEmpty {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[Pluck] applicationWillTerminate")
        if let obs = windowCloseObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        Task { @MainActor in
            state.shutdownServices()
        }
    }
}
