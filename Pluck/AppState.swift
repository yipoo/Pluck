import Foundation
import Combine
import AppKit

/// 全局可观察状态。持有 service 实例并暴露给 UI。
@MainActor
final class AppState: ObservableObject {

    // 用于 HistoryView 的可见数据
    @Published var clipboardHistory: [ClipboardItem] = []
    @Published var snapshots: [Snapshot] = []

    // UI 状态
    @Published var isCapturing = false
    @Published var lastError: String?
    @Published var isReady = false

    let settings = SettingsStore()

    // 服务句柄(bootstrap 时实例化)
    private(set) var screenCapture: ScreenCaptureService?
    private(set) var ocr: OCRService?
    private(set) var clipboard: ClipboardMonitor?
    private(set) var storage: Storage?

    private let regionSelector = RegionSelectionController()
    private let historyWindow = HistoryWindowController()
    private let onboardingWindow = OnboardingWindowController()
    private let flashController = CaptureFlashController()

    private var settingsCancellables: Set<AnyCancellable> = []

    nonisolated init() {}

    /// App 启动时调用一次。失败会 set lastError 并保持非 ready 状态。
    func bootstrapServices() {
        do {
            let storage = try Storage()
            self.storage = storage
            self.ocr = OCRService()
            self.screenCapture = ScreenCaptureService()

            let monitor = ClipboardMonitor()
            monitor.onItemCaptured = { [weak self] captured in
                Task { await self?.handleClipboardCapture(captured) }
            }
            monitor.start()
            self.clipboard = monitor

            registerHotkeys()
            wireSettingsChangeListeners()
            refreshHistory()

            isReady = true

            // 首次启动展示欢迎页
            onboardingWindow.presentIfNeeded(state: self)
        } catch {
            lastError = "初始化失败:\(error.localizedDescription)"
            NotificationService.error(error.localizedDescription)
        }
    }

    func shutdownServices() {
        clipboard?.stop()
        HotkeyManager.shared.unregisterAll()
    }

    // MARK: - Hotkeys

    private func registerHotkeys() {
        HotkeyManager.shared.register(
            .captureRegion,
            combo: settings.captureRegionHotkey.combo
        ) { [weak self] in
            Task { await self?.captureRegion() }
        }

        HotkeyManager.shared.register(
            .toggleHistory,
            combo: settings.toggleHistoryHotkey.combo
        ) { [weak self] in
            self?.toggleHistory()
        }
    }

    /// 设置改变时,重新注册热键
    private func wireSettingsChangeListeners() {
        settings.$captureRegionHotkey
            .dropFirst()
            .sink { [weak self] desc in
                guard let self else { return }
                HotkeyManager.shared.register(.captureRegion, combo: desc.combo) {
                    Task { await self.captureRegion() }
                }
            }
            .store(in: &settingsCancellables)

        settings.$toggleHistoryHotkey
            .dropFirst()
            .sink { [weak self] desc in
                guard let self else { return }
                HotkeyManager.shared.register(.toggleHistory, combo: desc.combo) {
                    self.toggleHistory()
                }
            }
            .store(in: &settingsCancellables)
    }

    // MARK: - Capture flow

    func captureRegion() async {
        print("[Pluck] captureRegion() called, isReady=\(isReady), isCapturing=\(isCapturing)")
        guard !isCapturing, isReady else {
            print("[Pluck] captureRegion early return: isReady=\(isReady), isCapturing=\(isCapturing)")
            return
        }
        isCapturing = true
        defer { isCapturing = false }

        guard let screenCapture, let ocr, let storage else {
            print("[Pluck] captureRegion: services missing — screenCapture=\(screenCapture != nil), ocr=\(ocr != nil), storage=\(storage != nil)")
            return
        }

        // 关键:让菜单栏 popover 先关闭,再弹 overlay(避免焦点竞争)
        try? await Task.sleep(for: .milliseconds(120))

        // 1. 弹出 overlay,等用户选区(返回 selection 含 rect + 哪个显示器)
        print("[Pluck] presenting region selector overlay…")
        guard let selection = await regionSelector.present() else {
            print("[Pluck] user cancelled overlay (or returned nil)")
            return  // 用户取消,静默
        }
        print("[Pluck] user selected rect: \(selection.rect) on display=\(selection.displayID)")

        do {
            // 2. 抓图(传 displayID,确保多屏环境抓对屏幕)
            print("[Pluck] calling ScreenCaptureService.captureRegion...")
            let image = try await screenCapture.captureRegion(rect: selection.rect, displayID: selection.displayID)
            print("[Pluck] got image \(image.width)x\(image.height)")

            // 2b. 视觉反馈:被截区域闪一下白光(仿 macOS 原生)
            flashController.flash(rect: selection.rect, displayID: selection.displayID)

            // 3. 落盘
            let filename = "\(UUID().uuidString).png"
            let url = storage.snapshotURL(for: filename)
            image.writePNG(to: url)

            // 4. OCR
            print("[Pluck] running OCR…")
            let result = try await ocr.recognize(image: image)
            let text = result.text
            print("[Pluck] OCR result: \(text.count) chars")

            // 5. 写剪贴板(带 ownWriteMarker,避免被自己监听到)
            if !text.isEmpty {
                ClipboardMonitor.writeOwn(text: text)
            }

            // 6. 保存 snapshot 记录
            let snap = Snapshot(imagePath: filename, ocrText: text.isEmpty ? nil : text)
            try storage.insertSnapshot(snap)
            // 6b. 强制总数上限,避免无限堆积
            if let removed = try? storage.enforceSnapshotLimit(keep: settings.historyLimit) {
                for url in removed { ThumbnailCache.shared.invalidate(url) }
            }

            // 7. 刷新 UI + 截图音效 + 通知
            refreshHistory()
            playCaptureSound()
            NotificationService.ocrDone(charCount: text.count)

        } catch {
            print("[Pluck] captureRegion ERROR: \(error)")
            lastError = error.localizedDescription
            NotificationService.error(error.localizedDescription)
        }
    }

    // MARK: - Clipboard handling

    private func handleClipboardCapture(_ item: ClipboardMonitor.CapturedItem) async {
        guard let storage else { return }

        let entry: ClipboardItem
        switch item {
        case .text(let s):
            entry = ClipboardItem(
                kind: .text,
                content: s,
                sourceApp: NSWorkspace.shared.frontmostApplication?.localizedName
            )
        case .image(let img):
            // 图片复制:存盘 + 记录路径
            let filename = "\(UUID().uuidString).png"
            let url = storage.snapshotURL(for: filename)
            if let tiff = img.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
            }
            entry = ClipboardItem(
                kind: .image,
                content: "[图片]",
                imagePath: filename,
                sourceApp: NSWorkspace.shared.frontmostApplication?.localizedName
            )
        case .file(let url):
            entry = ClipboardItem(
                kind: .file,
                content: url.path,
                sourceApp: NSWorkspace.shared.frontmostApplication?.localizedName
            )
        }

        do {
            try storage.insertClipboard(entry)
            try storage.enforceClipboardLimit(keep: settings.historyLimit)
            refreshHistory()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - History

    func refreshHistory() {
        guard let storage else { return }
        let limit = settings.historyLimit
        // SQLite 读取走串行队列,常规历史规模(<= 1000)同步读取微秒级,无需异步
        clipboardHistory = (try? storage.recentClipboard(limit: limit)) ?? []
        snapshots = (try? storage.recentSnapshots(limit: limit)) ?? []
    }

    func search(_ keyword: String) -> [ClipboardItem] {
        guard let storage else { return [] }
        return (try? storage.searchClipboard(keyword, limit: 200)) ?? []
    }

    func toggleHistory() {
        historyWindow.toggle(state: self)
    }

    func openHistory() {
        historyWindow.present(state: self)
    }

    /// 用户在 设置 → 关于 点 "重看欢迎页"
    func showOnboardingAgain() {
        onboardingWindow.present(state: self)
    }

    /// 截图完成后播放短音 — 仿 macOS 系统截图音效
    /// 找不到 Grab.aiff 时降级到 "Pop"(macOS 内置音效)
    private func playCaptureSound() {
        let candidates = [
            "/System/Library/Sounds/Grab.aiff",
            "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/screen_capture.caf"
        ]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            if let s = NSSound(contentsOfFile: path, byReference: true) {
                s.play()
                return
            }
        }
        // 降级:Pop 是 macOS 标配,任何系统都有
        NSSound(named: NSSound.Name("Pop"))?.play()
    }

    // MARK: - Reuse: 复制历史条目回剪贴板

    func copyToClipboard(_ item: ClipboardItem) {
        switch item.kind {
        case .text:
            ClipboardMonitor.writeOwn(text: item.content)
        case .file:
            if let url = URL(string: item.content) ?? URL(fileURLWithPath: item.content) as URL? {
                let pb = NSPasteboard.general
                pb.declareTypes([.fileURL, ClipboardMonitor.ownWriteMarker], owner: nil)
                pb.setString(url.absoluteString, forType: .fileURL)
                pb.setString("", forType: ClipboardMonitor.ownWriteMarker)
            }
        case .image:
            if let path = item.imagePath, let storage {
                let url = storage.snapshotURL(for: path)
                if let img = NSImage(contentsOf: url) {
                    let pb = NSPasteboard.general
                    pb.declareTypes([.tiff, ClipboardMonitor.ownWriteMarker], owner: nil)
                    pb.writeObjects([img])
                    pb.setString("", forType: ClipboardMonitor.ownWriteMarker)
                }
            }
        }
    }

    // MARK: - Snapshot management

    func deleteSnapshot(_ snap: Snapshot) {
        guard let storage else { return }
        do {
            let removedURL = try storage.deleteSnapshot(id: snap.id)
            if let url = removedURL { ThumbnailCache.shared.invalidate(url) }
            refreshHistory()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func copySnapshotImage(_ snap: Snapshot) {
        guard let storage else { return }
        let url = storage.snapshotURL(for: snap.imagePath)
        guard let img = NSImage(contentsOf: url) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.declareTypes([.tiff, ClipboardMonitor.ownWriteMarker], owner: nil)
        pb.writeObjects([img])
        pb.setString("", forType: ClipboardMonitor.ownWriteMarker)
    }

    func snapshotURL(_ snap: Snapshot) -> URL? {
        storage?.snapshotURL(for: snap.imagePath)
    }

    // MARK: - Privacy

    func clearAllClipboard() {
        guard let storage else { return }
        try? storage.clearAllClipboard()
        refreshHistory()
    }

    func clearAllSnapshots() {
        guard let storage else { return }
        try? storage.clearAllSnapshots()
        ThumbnailCache.shared.clearAll()
        refreshHistory()
    }
}
