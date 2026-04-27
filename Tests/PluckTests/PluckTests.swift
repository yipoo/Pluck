import XCTest
import AppKit
import CoreGraphics
@testable import Pluck

final class PluckTests: XCTestCase {

    // MARK: - Models

    func testClipboardItemEncodingRoundtrip() throws {
        let item = ClipboardItem(kind: .text, content: "你好,世界")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.content, "你好,世界")
        XCTAssertEqual(decoded.kind, .text)
    }

    func testSnapshotInit() {
        let snap = Snapshot(imagePath: "test.png", ocrText: "hello")
        XCTAssertEqual(snap.imagePath, "test.png")
        XCTAssertEqual(snap.ocrText, "hello")
        XCTAssertTrue(snap.annotations.isEmpty)
    }

    @MainActor
    func testAppStateInitialization() {
        let state = AppState()
        XCTAssertTrue(state.clipboardHistory.isEmpty)
        XCTAssertTrue(state.snapshots.isEmpty)
        XCTAssertFalse(state.isCapturing)
        XCTAssertFalse(state.isReady)
    }

    // MARK: - Storage CRUD

    func testStorageDirectoryCreation() throws {
        let storage = try Storage()
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: storage.snapshotsDir.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    func testStorageInsertAndReadClipboard() throws {
        let storage = try Self.makeTempStorage()
        let a = ClipboardItem(kind: .text, content: "first")
        let b = ClipboardItem(kind: .text, content: "second")
        try storage.insertClipboard(a)
        try storage.insertClipboard(b)

        let items = try storage.recentClipboard(limit: 10)
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.contains(where: { $0.content == "first" }))
        XCTAssertTrue(items.contains(where: { $0.content == "second" }))
    }

    func testStorageFTSSearch() throws {
        let storage = try Self.makeTempStorage()
        try storage.insertClipboard(ClipboardItem(kind: .text, content: "今天调研了银发市场"))
        try storage.insertClipboard(ClipboardItem(kind: .text, content: "Mac 截图工具竞品"))
        try storage.insertClipboard(ClipboardItem(kind: .text, content: "产品定位:隐私优先"))

        let hits = try storage.searchClipboard("调研", limit: 10)
        XCTAssertEqual(hits.count, 1)
        XCTAssertTrue(hits.first?.content.contains("调研") == true)

        let mixed = try storage.searchClipboard("隐私", limit: 10)
        XCTAssertEqual(mixed.count, 1)
    }

    func testStorageEnforceClipboardLimit() throws {
        let storage = try Self.makeTempStorage()
        for i in 0..<10 {
            try storage.insertClipboard(ClipboardItem(
                kind: .text,
                content: "item-\(i)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(i))
            ))
        }
        try storage.enforceClipboardLimit(keep: 5)
        let remaining = try storage.recentClipboard(limit: 100)
        XCTAssertEqual(remaining.count, 5)
        let contents = Set(remaining.map { $0.content })
        for i in 5..<10 {
            XCTAssertTrue(contents.contains("item-\(i)"), "应保留 item-\(i)")
        }
    }

    func testStorageClearAll() throws {
        let storage = try Self.makeTempStorage()
        try storage.insertClipboard(ClipboardItem(kind: .text, content: "x"))
        try storage.insertClipboard(ClipboardItem(kind: .text, content: "y"))
        XCTAssertEqual(try storage.recentClipboard().count, 2)
        try storage.clearAllClipboard()
        XCTAssertEqual(try storage.recentClipboard().count, 0)
    }

    func testStorageInsertAndReadSnapshot() throws {
        let storage = try Self.makeTempStorage()
        let snap = Snapshot(
            imagePath: "abc.png",
            ocrText: "Hello world",
            annotations: [
                Annotation(kind: .rect, bounds: CGRect(x: 0, y: 0, width: 10, height: 10), text: nil, colorHex: "#FF0000")
            ]
        )
        try storage.insertSnapshot(snap)
        let snaps = try storage.recentSnapshots(limit: 10)
        XCTAssertEqual(snaps.count, 1)
        XCTAssertEqual(snaps.first?.imagePath, "abc.png")
        XCTAssertEqual(snaps.first?.ocrText, "Hello world")
        XCTAssertEqual(snaps.first?.annotations.count, 1)
        XCTAssertEqual(snaps.first?.annotations.first?.colorHex, "#FF0000")
    }

    // MARK: - SettingsStore

    func testHotkeyDescriptorDisplayString() {
        let hk = SettingsStore.HotkeyDescriptor.captureRegionDefault
        XCTAssertEqual(hk.displayString, "⌃⌥A")
    }

    func testHotkeyDescriptorEncodingRoundtrip() throws {
        let original = SettingsStore.HotkeyDescriptor.toggleHistoryDefault
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SettingsStore.HotkeyDescriptor.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.displayString, "⌃⌥V")
    }

    // MARK: - OCR (Vision)

    /// 渲染英文文字 → 用 OCRService 识别 → 验证结果包含原文
    /// 该测试验证整个 Vision pipeline 在当前机器可用
    func testOCRRecognizesRenderedEnglish() async throws {
        let image = Self.renderText("Hello Pluck", size: CGSize(width: 600, height: 200))
        let ocr = OCRService()
        ocr.recognitionLanguages = ["en-US"]
        let result = try await ocr.recognize(image: image)
        XCTAssertTrue(result.text.lowercased().contains("hello"),
                      "OCR result was: \(result.text)")
    }

    func testOCRReturnsEmptyForBlankImage() async throws {
        let blank = Self.renderText("", size: CGSize(width: 200, height: 100))
        let ocr = OCRService()
        let result = try await ocr.recognize(image: blank)
        XCTAssertEqual(result.text, "")
        XCTAssertTrue(result.blocks.isEmpty)
    }

    // MARK: - Helpers

    private static func makeTempStorage() throws -> Storage {
        let baseDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pluck-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        let dbFile = baseDir.appendingPathComponent("test.sqlite")
        let snapsDir = baseDir.appendingPathComponent("snapshots", isDirectory: true)
        return try Storage(databaseFile: dbFile, snapshotsDirectory: snapsDir)
    }

    /// 用 Cocoa 把文字画进 CGImage(用于 OCR 测试)
    private static func renderText(_ text: String, size: CGSize) -> CGImage {
        let w = Int(size.width)
        let h = Int(size.height)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let cs = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: bitmapInfo
        )!
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: w, height: h))

        if !text.isEmpty {
            let font = NSFont.systemFont(ofSize: 56, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let attributed = NSAttributedString(string: text, attributes: attrs)
            NSGraphicsContext.saveGraphicsState()
            let nsCtx = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsCtx
            attributed.draw(at: NSPoint(x: 20, y: 60))
            NSGraphicsContext.restoreGraphicsState()
        }

        return context.makeImage()!
    }
}
