import Foundation
import Combine

/// 用户设置(UserDefaults 包装,Combine 发布)。
/// W6 任务:接入设置面板。
final class SettingsStore: ObservableObject {

    @Published var historyLimit: Int = 100
    @Published var launchAtLogin: Bool = false
    @Published var strictOffline: Bool = true       // 隐私优先 — 默认开
    @Published var appearance: Appearance = .system
    @Published var captureRegionHotkey: HotkeyDescriptor = .default(for: .captureRegion)
    @Published var toggleHistoryHotkey: HotkeyDescriptor = .default(for: .toggleHistory)

    enum Appearance: String, CaseIterable, Codable {
        case light, dark, system
    }

    struct HotkeyDescriptor: Codable, Equatable {
        var keyCode: UInt32
        var modifiers: UInt32
        var displayString: String

        static func `default`(for action: HotkeyManager.Action) -> HotkeyDescriptor {
            switch action {
            case .captureRegion:
                return HotkeyDescriptor(keyCode: 0, modifiers: 0, displayString: "⌃⌥A")
            case .toggleHistory:
                return HotkeyDescriptor(keyCode: 0, modifiers: 0, displayString: "⌃⌥V")
            case .toggleSettings:
                return HotkeyDescriptor(keyCode: 0, modifiers: 0, displayString: "⌃⌥,")
            }
        }
    }

    init() {
        // TODO W6:从 UserDefaults 读取持久化设置
    }

    func persist() {
        // TODO W6:写回 UserDefaults
    }

    func resetToDefaults() {
        // TODO W6
    }
}
