import Foundation
import AppKit
import Combine

/// Sparkle 自动更新封装。
///
/// 设计:
/// - 用 `#if canImport(Sparkle)` 保护 — 没装 SPM 时也能 build,只是更新功能 no-op
/// - 默认不自动检查(SUEnableAutomaticChecks = false in Info.plist)
/// - 用户主动点 "检查更新" 才发请求 — 隐私优先
///
/// 集成步骤见 docs/SPARKLE.md

#if canImport(Sparkle)
import Sparkle

@MainActor
final class UpdaterService: NSObject, ObservableObject {

    static let shared = UpdaterService()

    private let controller: SPUStandardUpdaterController
    @Published private(set) var canCheckForUpdates: Bool = false

    private override init() {
        // userDriver:nil 表示用 Sparkle 自带 UI(简洁弹窗 + 下载进度)
        // updaterDelegate:nil(默认行为已够 v0.1.0)
        self.controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()

        // 监听 canCheckForUpdates 的 KVO
        controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)
    }

    /// 用户在设置面板点 "检查更新" 时调用
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    /// 当前自动检查频率(秒)
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }
}

#else

/// 没装 Sparkle SPM 时的兜底实现 — 让 SettingsView 等代码能编译
@MainActor
final class UpdaterService: ObservableObject {
    static let shared = UpdaterService()
    @Published private(set) var canCheckForUpdates: Bool = false

    private init() {}

    func checkForUpdates() {
        // 没集成 Sparkle 时,引导去官网
        let alert = NSAlert()
        alert.messageText = "更新检查未启用"
        alert.informativeText = "Sparkle 自动更新模块尚未在此 build 中集成。请到官网查看最新版本。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "访问官网")
        alert.addButton(withTitle: "好")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "https://pluck.yipoo.com") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    var automaticallyChecksForUpdates: Bool {
        get { false }
        set { _ = newValue }
    }
}

#endif
