import XCTest
@testable import Pluck

final class PluckTests: XCTestCase {

    func testClipboardItemEncodingRoundtrip() throws {
        let item = ClipboardItem(kind: .text, content: "你好,世界")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.content, "你好,世界")
        XCTAssertEqual(decoded.kind, .text)
    }

    func testSnapshotInit() {
        let pluck = Snapshot(imagePath: "test.png", ocrText: "hello")
        XCTAssertEqual(pluck.imagePath, "test.png")
        XCTAssertEqual(pluck.ocrText, "hello")
        XCTAssertTrue(pluck.annotations.isEmpty)
    }

    func testStorageDirectoryCreation() throws {
        let storage = try Storage()
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: storage.snapshotsDir.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    @MainActor
    func testAppStateInitialization() {
        let state = AppState()
        XCTAssertTrue(state.clipboardHistory.isEmpty)
        XCTAssertTrue(state.snapshots.isEmpty)
        XCTAssertFalse(state.isCapturing)
    }

    // TODO W4:OCR 服务测试需要 sample 图像 — 在 Resources 目录加 5 张测试图后启用
    // func testOCRChineseRecognition() async throws { ... }
}
