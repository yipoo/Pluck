import Foundation
import CoreGraphics
import AppKit
import ScreenCaptureKit

/// 屏幕截图服务。基于 ScreenCaptureKit (macOS 12.3+,我们要求 14+)。
/// 关键点:
/// - 首次调用会触发"屏幕录制"权限请求(通过 SCShareableContent.current 触发)
/// - 多显示器:rect 是相对于主显示器左上角的全局坐标
/// - Retina:返回的 CGImage 是物理像素(已乘 backingScaleFactor)
final class ScreenCaptureService {

    enum CaptureError: Error, LocalizedError {
        case permissionDenied
        case noDisplay
        case captureFailed(String)
        case rectOutOfBounds

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "未授予屏幕录制权限"
            case .noDisplay: return "未找到任何显示器"
            case .captureFailed(let r): return "截屏失败:\(r)"
            case .rectOutOfBounds: return "选区超出屏幕边界"
            }
        }
    }

    /// 抓全屏(主显示器)。
    func captureFullScreen() async throws -> CGImage {
        let content = try await fetchSharedContent()
        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }
        return try await capture(display: display, contentRect: nil)
    }

    /// 抓指定全局矩形。坐标是 NSScreen 的"左上原点"(全局坐标)。
    func captureRegion(rect: CGRect) async throws -> CGImage {
        let content = try await fetchSharedContent()
        guard let display = displayContaining(rect: rect, in: content) else {
            throw CaptureError.rectOutOfBounds
        }

        let displayFrame = CGRect(
            x: CGFloat(display.frame.origin.x),
            y: CGFloat(display.frame.origin.y),
            width: CGFloat(display.width),
            height: CGFloat(display.height)
        )
        let relRect = CGRect(
            x: rect.origin.x - displayFrame.origin.x,
            y: rect.origin.y - displayFrame.origin.y,
            width: rect.width,
            height: rect.height
        )
        return try await capture(display: display, contentRect: relRect)
    }

    /// 检查屏幕录制权限(不会弹窗)。
    func hasPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    /// 主动请求权限(首次会弹系统对话框;授予后通常需要重启 App 生效)。
    @discardableResult
    func requestPermission() -> Bool {
        return CGRequestScreenCaptureAccess()
    }

    // MARK: - Internals

    private func fetchSharedContent() async throws -> SCShareableContent {
        do {
            return try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            throw CaptureError.permissionDenied
        }
    }

    private func displayContaining(rect: CGRect, in content: SCShareableContent) -> SCDisplay? {
        for d in content.displays {
            let f = CGRect(x: CGFloat(d.frame.origin.x),
                           y: CGFloat(d.frame.origin.y),
                           width: CGFloat(d.width),
                           height: CGFloat(d.height))
            if f.contains(rect.origin) { return d }
        }
        return content.displays.first
    }

    private func capture(display: SCDisplay, contentRect: CGRect?) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let cfg = SCStreamConfiguration()
        let scale = CGFloat(NSScreen.main?.backingScaleFactor ?? 2.0)

        if let r = contentRect {
            cfg.sourceRect = r
            cfg.width = Int(r.width * scale)
            cfg.height = Int(r.height * scale)
        } else {
            cfg.width = Int(CGFloat(display.width) * scale)
            cfg.height = Int(CGFloat(display.height) * scale)
        }
        cfg.showsCursor = false
        cfg.capturesAudio = false

        do {
            return try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: cfg
            )
        } catch {
            throw CaptureError.captureFailed(error.localizedDescription)
        }
    }
}

// MARK: - PNG helper

extension CGImage {
    /// 写入 PNG 到磁盘。返回是否成功。
    @discardableResult
    func writePNG(to url: URL) -> Bool {
        let rep = NSBitmapImageRep(cgImage: self)
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
