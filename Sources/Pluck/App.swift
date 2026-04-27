import SwiftUI
import AppKit

@main
struct PluckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Pluck", systemImage: "camera.viewfinder") {
            MenuBarContentView()
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
        // 请求通知权限(静默 — 用户拒绝就拒绝)
        NotificationService.requestAuthorization()

        // 实例化所有 service + 注册热键
        Task { @MainActor in
            state.bootstrapServices()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            state.shutdownServices()
        }
    }
}
