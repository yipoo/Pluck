import Foundation

/// 全局热键注册。W2 接入 [HotKey](https://github.com/soffes/HotKey) 库。
/// 默认绑定:
/// - ⌃⌥A 触发区域截图 OCR
/// - ⌃⌥V 呼出剪贴板历史
final class HotkeyManager {
    enum Action: String, CaseIterable {
        case captureRegion
        case toggleHistory
        case toggleSettings
    }

    private var handlers: [Action: () -> Void] = [:]

    func register(_ action: Action, handler: @escaping () -> Void) {
        handlers[action] = handler
        // TODO W2:用 HotKey 库注册到系统全局,绑定快捷键
        //         需要从 SettingsStore 读取用户自定义的 key/modifiers
    }

    func unregister(_ action: Action) {
        handlers[action] = nil
        // TODO W2:解绑系统全局热键
    }

    func unregisterAll() {
        handlers.removeAll()
        // TODO W2
    }
}
