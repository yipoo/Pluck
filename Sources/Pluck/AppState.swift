import Foundation
import Combine

/// 全局可观察状态。持有 service 实例并暴露给 UI。
/// W1 阶段:仅占位 + 历史样本数据。
/// W2+:接入 HotkeyManager、ScreenCaptureService、ClipboardMonitor、Storage。
@MainActor
final class AppState: ObservableObject {
    @Published var clipboardHistory: [ClipboardItem] = []
    @Published var snapshots: [Snapshot] = []
    @Published var isCapturing = false
    @Published var lastError: String?

    let settings = SettingsStore()

    // 服务句柄(W2+ 真实实例化)
    var hotkeyManager: HotkeyManager?
    var screenCapture: ScreenCaptureService?
    var ocr: OCRService?
    var clipboard: ClipboardMonitor?
    var storage: Storage?

    init() {
        // W1:占位样本数据
        self.clipboardHistory = []
        self.snapshots = []
    }

    /// W2 接入:启动所有 service。
    func bootstrapServices() {
        // TODO W2: HotkeyManager() / ScreenCaptureService()
        // TODO W4: OCRService()
        // TODO W5: ClipboardMonitor() / Storage()
    }

    func captureRegion() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        do {
            // TODO W3: 调用 screenCapture?.captureRegion(rect:)
            // TODO W4: 把 CGImage 喂给 ocr?.recognize(image:),写 NSPasteboard + Storage
            try await Task.sleep(for: .milliseconds(50))
        } catch {
            lastError = "\(error)"
        }
    }
}
