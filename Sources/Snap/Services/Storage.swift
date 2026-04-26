import Foundation

/// 本地持久化(SQLite via GRDB)— W5 任务。
/// 数据库位置:`~/Library/Application Support/Snap/snap.sqlite`
/// 截图缓存目录:`~/Library/Application Support/Snap/snapshots/`
final class Storage {

    enum StorageError: Error {
        case directoryCreationFailed
        case databaseInitFailed(String)
    }

    let dbPath: URL
    let snapshotsDir: URL

    init() throws {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let snapDir = appSupport.appendingPathComponent("Snap", isDirectory: true)
        let shotsDir = snapDir.appendingPathComponent("snapshots", isDirectory: true)
        try FileManager.default.createDirectory(at: shotsDir, withIntermediateDirectories: true)

        self.dbPath = snapDir.appendingPathComponent("snap.sqlite")
        self.snapshotsDir = shotsDir

        // TODO W5:GRDB DatabasePool 初始化 + migrate
        //         CREATE TABLE clipboard_items / snapshots / FTS5
    }

    // MARK: Clipboard

    func insertClipboard(_ item: ClipboardItem) async throws {
        // TODO W5
    }

    func recentClipboard(limit: Int = 100) async throws -> [ClipboardItem] {
        // TODO W5
        return []
    }

    func searchClipboard(_ keyword: String, limit: Int = 50) async throws -> [ClipboardItem] {
        // TODO W5:用 FTS5 全文搜索
        return []
    }

    func purgeClipboard(olderThan date: Date) async throws {
        // TODO W5
    }

    func clearAllClipboard() async throws {
        // TODO W5 + 设置面板"清空"按钮调用
    }

    // MARK: Snapshots

    func insertSnapshot(_ snap: Snapshot) async throws {
        // TODO W5
    }

    func recentSnapshots(limit: Int = 100) async throws -> [Snapshot] {
        // TODO W5
        return []
    }
}
