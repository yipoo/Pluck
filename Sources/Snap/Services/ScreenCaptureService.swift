import Foundation
import CoreGraphics
import AppKit

/// 屏幕截图服务。
/// W2:接入 ScreenCaptureKit,实现 captureFullScreen
/// W3:实现 captureRegion(选区 overlay)
final class ScreenCaptureService {

    enum CaptureError: Error {
        case permissionDenied
        case captureFailed(reason: String)
        case unsupportedDisplay
    }

    /// 全屏截图 — W2 任务。
    func captureFullScreen() async throws -> CGImage {
        // TODO W2:用 SCScreenshotManager.captureImage(contentFilter:configuration:)
        //         首次调用会触发屏幕录制权限请求
        throw CaptureError.captureFailed(reason: "Not implemented yet (W2)")
    }

    /// 区域截图 — W3 任务。
    /// - Parameter rect: 屏幕坐标系下的矩形(以主显示器左上为原点)
    func captureRegion(rect: CGRect) async throws -> CGImage {
        // TODO W3:用 SCScreenshotManager.captureImage(in: rect)
        //         注意 Retina 缩放(乘以 backingScaleFactor)
        //         注意多显示器(用 NSScreen.screens 找到 rect 所在的 screen)
        throw CaptureError.captureFailed(reason: "Not implemented yet (W3)")
    }

    /// 检查屏幕录制权限。
    /// 用于设置面板上显示状态。
    func hasScreenRecordingPermission() -> Bool {
        // TODO W2:CGPreflightScreenCaptureAccess()
        return false
    }

    /// 主动请求权限(会弹系统对话框)。
    func requestScreenRecordingPermission() {
        // TODO W2:CGRequestScreenCaptureAccess()
    }
}
