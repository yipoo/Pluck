import Foundation
import AppKit
import Carbon.HIToolbox

/// 全局热键注册(基于 Carbon HIToolbox,无需 Accessibility 权限)。
/// 实现参考 Apple Carbon HotKey API + soffes/HotKey 思路;零外部依赖。
final class HotkeyManager {

    enum Action: Hashable {
        case captureRegion
        case toggleHistory
        case toggleSettings
    }

    /// 一组键码 + 修饰位(Carbon 风格)
    struct Combo: Equatable, Hashable {
        let keyCode: UInt32          // kVK_ANSI_A 等
        let modifiers: UInt32        // cmdKey | controlKey | optionKey | shiftKey
    }

    private struct Registration {
        let id: UInt32
        let ref: EventHotKeyRef
    }

    private var registrations: [Action: Registration] = [:]
    private var nextId: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    static let shared = HotkeyManager()

    private init() {
        installEventHandler()
    }

    deinit {
        unregisterAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    /// 注册一个全局热键。如果该 action 已注册,先解绑再绑。
    @discardableResult
    func register(_ action: Action, combo: Combo, handler: @escaping () -> Void) -> Bool {
        unregister(action)

        let id = nextId
        nextId &+= 1

        let hkID = EventHotKeyID(signature: signature, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            hkID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else { return false }

        registrations[action] = Registration(id: id, ref: ref)
        Self.handlerLookup[id] = handler
        return true
    }

    func unregister(_ action: Action) {
        guard let reg = registrations.removeValue(forKey: action) else { return }
        UnregisterEventHotKey(reg.ref)
        Self.handlerLookup[reg.id] = nil
    }

    func unregisterAll() {
        for action in Array(registrations.keys) {
            unregister(action)
        }
    }

    // MARK: - Event handling

    /// "PLCK" — 4字节 OSType 用于区分 hotkey 来源
    private let signature: OSType = {
        let chars: [UInt8] = [0x50, 0x4C, 0x43, 0x4B] // "PLCK"
        return chars.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }()

    /// 全局 id → handler 查找表(C 回调内访问)
    fileprivate static var handlerLookup: [UInt32: () -> Void] = [:]

    private func installEventHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, eventRef, _ in
            guard let eventRef else { return noErr }
            var hkID = EventHotKeyID()
            let status = GetEventParameter(eventRef,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &hkID)
            guard status == noErr else { return status }
            if let handler = HotkeyManager.handlerLookup[hkID.id] {
                DispatchQueue.main.async { handler() }
            }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(),
                            callback,
                            1, &spec, nil, &eventHandler)
    }
}

// MARK: - Combo helpers

extension HotkeyManager.Combo {
    /// 默认绑定 ⌃⌥A — 区域截图 OCR
    static let captureRegionDefault = HotkeyManager.Combo(
        keyCode: UInt32(kVK_ANSI_A),
        modifiers: UInt32(controlKey | optionKey)
    )
    /// 默认绑定 ⌃⌥V — 呼出剪贴板历史
    static let toggleHistoryDefault = HotkeyManager.Combo(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(controlKey | optionKey)
    )
}

extension HotkeyManager.Combo {
    /// 给 UI 显示的字符串("⌃⌥A")
    var displayString: String {
        var s = ""
        if modifiers & UInt32(controlKey)  != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey)   != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey)    != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey)      != 0 { s += "⌘" }
        s += Self.keyName(for: keyCode)
        return s
    }

    private static func keyName(for code: UInt32) -> String {
        switch Int(code) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Escape: return "⎋"
        default: return "Key(\(code))"
        }
    }
}
