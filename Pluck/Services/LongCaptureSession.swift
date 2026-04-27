import Foundation
import AppKit
import CoreGraphics

/// 长截图会话 — 维护一组连续抓的同一区域 CGImage,会话结束后调 stitch 出长图。
///
/// 工作流:
/// 1. start(rect:displayID:) — 用户选定区域
/// 2. capturePage() — 用户每滚动一屏后调用一次,APP 抓一张存进栈
/// 3. finish() — 拼接所有 page,返回长 CGImage
///
/// v0.2 实验性:UX 由 LongCaptureController 提供,初版要求用户手动滚动并按"下一页"。
/// v0.3+ 计划:用 Accessibility API 程序化滚动 + 自动判断滚动到底。
@MainActor
final class LongCaptureSession {

    enum SessionError: Error {
        case notStarted
        case captureFailed(String)
        case stitchFailed
        case noPages
    }

    private(set) var rect: CGRect?
    private(set) var displayID: CGDirectDisplayID?
    private(set) var pages: [CGImage] = []
    private(set) var isActive = false

    private let captureService: ScreenCaptureService

    init(captureService: ScreenCaptureService) {
        self.captureService = captureService
    }

    func start(rect: CGRect, displayID: CGDirectDisplayID) {
        self.rect = rect
        self.displayID = displayID
        self.pages = []
        self.isActive = true
    }

    /// 抓当前一屏 — 仍是给定区域,用户应已滚动了内容区
    @discardableResult
    func capturePage() async throws -> Int {
        guard isActive, let rect, let displayID else {
            throw SessionError.notStarted
        }
        do {
            let img = try await captureService.captureRegion(rect: rect, displayID: displayID)
            pages.append(img)
            return pages.count
        } catch {
            throw SessionError.captureFailed(error.localizedDescription)
        }
    }

    /// 结束 + 拼接
    func finish() throws -> CGImage {
        defer {
            isActive = false
            pages = []
            rect = nil
            displayID = nil
        }
        guard !pages.isEmpty else { throw SessionError.noPages }
        guard let stitched = ImageStitcher.stitch(pages) else {
            throw SessionError.stitchFailed
        }
        return stitched
    }

    func cancel() {
        isActive = false
        pages = []
        rect = nil
        displayID = nil
    }
}
