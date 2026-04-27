import AppKit
import SwiftUI
import Combine

/// 长截图浮窗 — 弹一个小窗口告诉用户:
/// "已捕获 N 张 · 请滚动后点'下一屏' · 完成"
///
/// v0.2 实验性 UX。需要用户在被截 App 里手动滚动,然后切回此浮窗点按钮。
@MainActor
final class LongCaptureController: ObservableObject {

    private var window: NSWindow?
    private var hostingController: NSHostingController<LongCaptureFloater>?
    private var session: LongCaptureSession?
    private var onFinish: ((CGImage) -> Void)?
    private var onCancel: (() -> Void)?

    @Published var pageCount: Int = 0
    @Published var isCapturing: Bool = false

    /// 启动 — region selector 已经选好了区域
    func start(rect: CGRect, displayID: CGDirectDisplayID,
               session: LongCaptureSession,
               onFinish: @escaping (CGImage) -> Void,
               onCancel: @escaping () -> Void) {
        session.start(rect: rect, displayID: displayID)
        self.session = session
        self.onFinish = onFinish
        self.onCancel = onCancel
        self.pageCount = 0

        // 立即抓第一张
        Task { await self.captureNext() }

        present()
    }

    func captureNext() async {
        guard let session, !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }
        do {
            let n = try await session.capturePage()
            pageCount = n
        } catch {
            // 静默 — 浮窗 status 会显示
        }
    }

    func finish() {
        guard let session else { return }
        do {
            let stitched = try session.finish()
            close()
            onFinish?(stitched)
        } catch {
            close()
            onCancel?()
        }
    }

    func cancel() {
        session?.cancel()
        close()
        onCancel?()
    }

    // MARK: - 浮窗

    private func present() {
        guard window == nil else { return }
        let view = LongCaptureFloater(controller: self)
        let hosting = NSHostingController(rootView: view)
        hostingController = hosting

        let win = NSWindow(contentViewController: hosting)
        win.title = "长截图(实验性)"
        win.styleMask = [.titled, .closable, .nonactivatingPanel, .utilityWindow]
        win.level = .floating
        win.isReleasedWhenClosed = false
        win.setContentSize(NSSize(width: 320, height: 140))

        // 放屏幕右上角
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            win.setFrameOrigin(NSPoint(x: f.maxX - 340, y: f.maxY - 160))
        }

        win.makeKeyAndOrderFront(nil)
        window = win
    }

    private func close() {
        window?.close()
        window = nil
        hostingController = nil
    }
}

// MARK: - 浮窗视图

private struct LongCaptureFloater: View {
    @ObservedObject var controller: LongCaptureController

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.tint)
                Text("已捕获 \(controller.pageCount) 屏")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if controller.isCapturing {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            Text("提示:在被截 App 里向下滚动一屏,然后回这里点 \"下一屏\"")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Button("取消") { controller.cancel() }
                    .controlSize(.small)
                Spacer()
                Button("下一屏") {
                    Task { await controller.captureNext() }
                }
                .controlSize(.small)
                .keyboardShortcut(.space, modifiers: [])
                Button("完成") { controller.finish() }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(controller.pageCount == 0)
            }
        }
        .padding(14)
        .frame(width: 320)
    }
}
