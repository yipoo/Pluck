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

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[Pluck] applicationDidFinishLaunching")

        // 请求通知权限(静默 — 用户拒绝就拒绝)
        NotificationService.requestAuthorization()

        // ⭐ 主动请求屏幕录制权限 — 触发系统弹窗(必须有 Info.plist 的 NSScreenCaptureUsageDescription)
        // 已授权时返回 true,什么都不做;未授权时返回 false 并弹系统对话框
        let hasScreenAccess = CGPreflightScreenCaptureAccess()
        print("[Pluck] CGPreflightScreenCaptureAccess() = \(hasScreenAccess)")
        if !hasScreenAccess {
            print("[Pluck] 主动请求屏幕录制权限...")
            let granted = CGRequestScreenCaptureAccess()
            print("[Pluck] CGRequestScreenCaptureAccess() = \(granted) (false = 用户需要去系统设置授予;通常授予后需重启 App)")
        }

        // 实例化所有 service + 注册热键
        Task { @MainActor in
            print("[Pluck] bootstrapServices begin")
            state.bootstrapServices()
            print("[Pluck] bootstrapServices done, isReady=\(state.isReady), lastError=\(state.lastError ?? "nil")")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[Pluck] applicationWillTerminate")
        Task { @MainActor in
            state.shutdownServices()
        }
    }
}
