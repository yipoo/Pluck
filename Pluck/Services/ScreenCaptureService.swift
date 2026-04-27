import Foundation
import CoreGraphics
import AppKit
import ScreenCaptureKit

/// 屏幕截图服务。基于 ScreenCaptureKit (macOS 12.3+,我们要求 14+)。
final class ScreenCaptureService {

    enum CaptureError: Error, LocalizedError {
        case permissionDenied
        case noDisplay
        case captureFailed(String)
        case displayNotFound

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "未授予屏幕录制权限"
            case .noDisplay: return "未找到任何显示器"
            case .captureFailed(let r): return "截屏失败:\(r)"
            case .displayNotFound: return "选区所在显示器未找到"
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

    /// 抓指定显示器上的指定矩形。
    /// - Parameter rect: 选区,**display-local 坐标**(top-left origin,相对该显示器)
    /// - Parameter displayID: 物理显示器 ID(从 NSScreen.deviceDescription[NSScreenNumber])
    func captureRegion(rect: CGRect, displayID: CGDirectDisplayID) async throws -> CGImage {
        let content = try await fetchSharedContent()
        print("[Pluck] ScreenCaptureKit displays: \(content.displays.map { "id=\($0.displayID) frame=\($0.frame)" })")

        // 严格按 displayID 匹配,匹配不到再降级用第一块
        let display = content.displays.first(where: { $0.displayID == displayID })
                   ?? content.displays.first
        guard let display else { throw CaptureError.noDisplay }

        if display.displayID != displayID {
            print("[Pluck] WARN: requested displayID \(displayID) not found, falling back to \(display.displayID)")
        } else {
            print("[Pluck] capturing on display \(display.displayID), rect (display-local)=\(rect)")
        }

        return try await capture(display: display, contentRect: rect)
    }

    func hasPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    func requestPermission() -> Bool {
        return CGRequestScreenCaptureAccess()
    }

    // MARK: - Internals

    private func fetchSharedContent() async throws -> SCShareableContent {
        print("[Pluck] ScreenCaptureService.fetchSharedContent: hasPermission=\(hasPermission())")
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            print("[Pluck] SCShareableContent OK, displays=\(content.displays.count)")
            return content
        } catch {
            print("[Pluck] SCShareableContent ERROR: \(error)")
            throw CaptureError.permissionDenied
        }
    }

    private func capture(display: SCDisplay, contentRect: CGRect?) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let cfg = SCStreamConfiguration()

        // 用该显示器自己的 backingScaleFactor(多屏混合 Retina/普通 时关键)
        let scale = NSScreen.screens
            .first(where: { $0.pluckDisplayID == display.displayID })?
            .backingScaleFactor ?? CGFloat(NSScreen.main?.backingScaleFactor ?? 2.0)

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
