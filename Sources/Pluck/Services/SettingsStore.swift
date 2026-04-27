import Foundation
import Combine
import Carbon.HIToolbox

/// 用户设置(UserDefaults 持久化,Combine 发布)。
final class SettingsStore: ObservableObject {

    @Published var historyLimit: Int               { didSet { UserDefaults.standard.set(historyLimit, forKey: K.historyLimit) } }
    @Published var launchAtLogin: Bool             { didSet { UserDefaults.standard.set(launchAtLogin, forKey: K.launchAtLogin) } }
    @Published var strictOffline: Bool             { didSet { UserDefaults.standard.set(strictOffline, forKey: K.strictOffline) } }
    @Published var appearance: Appearance          { didSet { UserDefaults.standard.set(appearance.rawValue, forKey: K.appearance) } }
    @Published var hasCompletedOnboarding: Bool    { didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: K.onboardingDone) } }
    @Published var captureRegionHotkey: HotkeyDescriptor { didSet { saveCombo(captureRegionHotkey, forKey: K.captureCombo) } }
    @Published var toggleHistoryHotkey: HotkeyDescriptor { didSet { saveCombo(toggleHistoryHotkey, forKey: K.toggleCombo) } }

    enum Appearance: String, CaseIterable, Codable {
        case light, dark, system
    }

    /// 持久化的热键(keyCode + modifiers)+ 计算的展示串
    struct HotkeyDescriptor: Codable, Equatable, Hashable {
        var keyCode: UInt32
        var modifiers: UInt32

        var combo: HotkeyManager.Combo {
            HotkeyManager.Combo(keyCode: keyCode, modifiers: modifiers)
        }
        var displayString: String { combo.displayString }

        static let captureRegionDefault = HotkeyDescriptor(
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: UInt32(controlKey | optionKey)
        )
        static let toggleHistoryDefault = HotkeyDescriptor(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(controlKey | optionKey)
        )
    }

    private enum K {
        static let historyLimit   = "pluck.historyLimit"
        static let launchAtLogin  = "pluck.launchAtLogin"
        static let strictOffline  = "pluck.strictOffline"
        static let appearance     = "pluck.appearance"
        static let onboardingDone = "pluck.onboardingDone"
        static let captureCombo   = "pluck.captureCombo"
        static let toggleCombo    = "pluck.toggleCombo"
    }

    init() {
        let d = UserDefaults.standard

        d.register(defaults: [
            K.historyLimit: 100,
            K.launchAtLogin: false,
            K.strictOffline: true,
            K.appearance: Appearance.system.rawValue,
            K.onboardingDone: false
        ])

        self.historyLimit  = d.integer(forKey: K.historyLimit)
        self.launchAtLogin = d.bool(forKey: K.launchAtLogin)
        self.strictOffline = d.bool(forKey: K.strictOffline)
        self.appearance    = Appearance(rawValue: d.string(forKey: K.appearance) ?? "") ?? .system
        self.hasCompletedOnboarding = d.bool(forKey: K.onboardingDone)

        self.captureRegionHotkey = Self.loadCombo(forKey: K.captureCombo) ?? .captureRegionDefault
        self.toggleHistoryHotkey = Self.loadCombo(forKey: K.toggleCombo) ?? .toggleHistoryDefault
    }

    /// 兜底:保留 API,didSet 已经在写
    func persist() { /* no-op,didSet 已自动写 */ }

    func resetToDefaults() {
        historyLimit = 100
        launchAtLogin = false
        strictOffline = true
        appearance = .system
        captureRegionHotkey = .captureRegionDefault
        toggleHistoryHotkey = .toggleHistoryDefault
    }

    // MARK: - Combo persist helpers

    private static func loadCombo(forKey key: String) -> HotkeyDescriptor? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HotkeyDescriptor.self, from: data)
    }

    private func saveCombo(_ descriptor: HotkeyDescriptor, forKey key: String) {
        if let data = try? JSONEncoder().encode(descriptor) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
