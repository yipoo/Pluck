import Foundation
import SQLite3

/// 本地持久化(SQLite3 直接调用,零外部依赖)。
/// 数据库:`~/Library/Application Support/Pluck/pluck.sqlite`
/// 截图缓存:`~/Library/Application Support/Pluck/snapshots/<uuid>.png`
final class Storage {

    enum StorageError: Error, LocalizedError {
        case directoryCreationFailed(String)
        case databaseOpenFailed(String)
        case statementPrepareFailed(String)
        case stepFailed(String)

        var errorDescription: String? {
            switch self {
            case .directoryCreationFailed(let m): return "目录创建失败:\(m)"
            case .databaseOpenFailed(let m): return "数据库打开失败:\(m)"
            case .statementPrepareFailed(let m): return "SQL 准备失败:\(m)"
            case .stepFailed(let m): return "SQL 执行失败:\(m)"
            }
        }
    }

    let dbPath: URL
    let snapshotsDir: URL
    private var db: OpaquePointer?
    /// 串行队列保证 SQLite 调用串行
    private let queue = DispatchQueue(label: "pluck.storage.serial")

    convenience init() throws {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDir = appSupport.appendingPathComponent("Pluck", isDirectory: true)
        let dbFile = appDir.appendingPathComponent("pluck.sqlite")
        let shotsDir = appDir.appendingPathComponent("snapshots", isDirectory: true)
        try self.init(databaseFile: dbFile, snapshotsDirectory: shotsDir)
    }

    /// 测试用 init:可指定数据库路径与截图目录(用 tmp 目录)
    init(databaseFile: URL, snapshotsDirectory: URL) throws {
        try FileManager.default.createDirectory(
            at: snapshotsDirectory,
            withIntermediateDirectories: true
        )
        self.dbPath = databaseFile
        self.snapshotsDir = snapshotsDirectory
        try openAndMigrate()
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    // MARK: - Open + Migrate

    private func openAndMigrate() throws {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let rc = sqlite3_open_v2(dbPath.path, &handle, flags, nil)
        guard rc == SQLITE_OK, let handle else {
            throw StorageError.databaseOpenFailed(lastErr(handle))
        }
        self.db = handle
        try execLocked("PRAGMA journal_mode=WAL;")
        try execLocked("PRAGMA foreign_keys=ON;")
        try migrate()
    }

    private func migrate() throws {
        try execLocked("""
        CREATE TABLE IF NOT EXISTS clipboard_items (
            id           TEXT PRIMARY KEY,
            kind         TEXT NOT NULL,
            content      TEXT NOT NULL,
            image_path   TEXT,
            source_app   TEXT,
            created_at   REAL NOT NULL
        );
        """)
        try execLocked("CREATE INDEX IF NOT EXISTS idx_clip_created ON clipboard_items(created_at DESC);")
        // v0.1 用 LIKE 搜索(对 100-1000 条规模足够快,代码简单,中英文混合无 tokenizer 问题)
        // FTS5 + trigram tokenizer 留待 v0.2 数据规模上来再切换

        try execLocked("""
        CREATE TABLE IF NOT EXISTS snapshots (
            id           TEXT PRIMARY KEY,
            image_path   TEXT NOT NULL,
            ocr_text     TEXT,
            annotations  BLOB,
            created_at   REAL NOT NULL
        );
        """)
        try execLocked("CREATE INDEX IF NOT EXISTS idx_snap_created ON snapshots(created_at DESC);")
    }

    // MARK: - Clipboard CRUD

    func insertClipboard(_ item: ClipboardItem) throws {
        try queue.sync {
            let sql = """
            INSERT OR REPLACE INTO clipboard_items
            (id, kind, content, image_path, source_app, created_at)
            VALUES (?, ?, ?, ?, ?, ?);
            """
            let stmt = try prepare(sql)
            defer { sqlite3_finalize(stmt) }
            bindText(stmt, 1, item.id.uuidString)
            bindText(stmt, 2, item.kind.rawValue)
            bindText(stmt, 3, item.content)
            bindOptionalText(stmt, 4, item.imagePath)
            bindOptionalText(stmt, 5, item.sourceApp)
            sqlite3_bind_double(stmt, 6, item.createdAt.timeIntervalSince1970)
            try step(stmt)
        }
    }

    func recentClipboard(limit: Int = 100) throws -> [ClipboardItem] {
        try queue.sync {
            let sql = """
            SELECT id, kind, content, image_path, source_app, created_at
            FROM clipboard_items
            ORDER BY created_at DESC
            LIMIT ?;
            """
            let stmt = try prepare(sql)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int(stmt, 1, Int32(limit))
            return readClipboardRows(stmt)
        }
    }

    /// LIKE 子串搜索(中英文均可);空 keyword 返回最近条目。
    func searchClipboard(_ keyword: String, limit: Int = 50) throws -> [ClipboardItem] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try recentClipboard(limit: limit) }

        return try queue.sync {
            let sql = """
            SELECT id, kind, content, image_path, source_app, created_at
            FROM clipboard_items
            WHERE content LIKE ?
            ORDER BY created_at DESC
            LIMIT ?;
            """
            let stmt = try prepare(sql)
            defer { sqlite3_finalize(stmt) }
            // 转义 LIKE 通配符,然后包 %x%
            let escaped = trimmed
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")
            bindText(stmt, 1, "%\(escaped)%")
            sqlite3_bind_int(stmt, 2, Int32(limit))
            return readClipboardRows(stmt)
        }
    }

    /// 限制总条数:超过 keep 的最旧条目删掉。
    func enforceClipboardLimit(keep: Int) throws {
        try queue.sync {
            let sql = """
            DELETE FROM clipboard_items
            WHERE id IN (
                SELECT id FROM clipboard_items
                ORDER BY created_at DESC
                LIMIT -1 OFFSET ?
            );
            """
            let stmt = try prepare(sql)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int(stmt, 1, Int32(keep))
            try step(stmt)
        }
    }

    func clearAllClipboard() throws {
        try queue.sync {
            try execLocked("DELETE FROM clipboard_items;")
        }
    }

    // MARK: - Snapshots CRUD

    func insertSnapshot(_ snapshot: Snapshot) throws {
        try queue.sync {
            let sql = """
            INSERT OR REPLACE INTO snapshots
            (id, image_path, ocr_text, annotations, created_at)
            VALUES (?, ?, ?, ?, ?);
            """
            let stmt = try prepare(sql)
            defer { sqlite3_finalize(stmt) }
            bindText(stmt, 1, snapshot.id.uuidString)
            bindText(stmt, 2, snapshot.imagePath)
            bindOptionalText(stmt, 3, snapshot.ocrText)
            if !snapshot.annotations.isEmpty,
               let blob = try? JSONEncoder().encode(snapshot.annotations) {
                blob.withUnsafeBytes { ptr in
                    _ = sqlite3_bind_blob(stmt, 4, ptr.baseAddress, Int32(blob.count), SQLITE_TRANSIENT)
                }
            } else {
                sqlite3_bind_null(stmt, 4)
            }
            sqlite3_bind_double(stmt, 5, snapshot.createdAt.timeIntervalSince1970)
            try step(stmt)
        }
    }

    func recentSnapshots(limit: Int = 100) throws -> [Snapshot] {
        try queue.sync {
            let sql = """
            SELECT id, image_path, ocr_text, annotations, created_at
            FROM snapshots
            ORDER BY created_at DESC
            LIMIT ?;
            """
            let stmt = try prepare(sql)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int(stmt, 1, Int32(limit))
            var out: [Snapshot] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                guard let idStr = readText(stmt, 0),
                      let uuid = UUID(uuidString: idStr),
                      let path = readText(stmt, 1) else { continue }
                let ocr = readText(stmt, 2)
                var ann: [Annotation] = []
                if let blobPtr = sqlite3_column_blob(stmt, 3) {
                    let n = Int(sqlite3_column_bytes(stmt, 3))
                    if n > 0 {
                        let data = Data(bytes: blobPtr, count: n)
                        ann = (try? JSONDecoder().decode([Annotation].self, from: data)) ?? []
                    }
                }
                let ts = sqlite3_column_double(stmt, 4)
                out.append(Snapshot(
                    id: uuid,
                    imagePath: path,
                    ocrText: ocr,
                    annotations: ann,
                    createdAt: Date(timeIntervalSince1970: ts)
                ))
            }
            return out
        }
    }

    /// 给定相对路径,返回截图缓存目录的完整 URL
    func snapshotURL(for relativePath: String) -> URL {
        snapshotsDir.appendingPathComponent(relativePath)
    }

    // MARK: - SQL helpers

    private func execLocked(_ sql: String) throws {
        var err: UnsafeMutablePointer<CChar>?
        let rc = sqlite3_exec(db, sql, nil, nil, &err)
        if rc != SQLITE_OK {
            let msg = err.flatMap { String(cString: $0) } ?? "unknown"
            sqlite3_free(err)
            throw StorageError.stepFailed(msg)
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer? {
        var stmt: OpaquePointer?
        let rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        if rc != SQLITE_OK {
            throw StorageError.statementPrepareFailed(lastErr(db))
        }
        return stmt
    }

    private func step(_ stmt: OpaquePointer?) throws {
        let rc = sqlite3_step(stmt)
        if rc != SQLITE_DONE && rc != SQLITE_ROW {
            throw StorageError.stepFailed(lastErr(db))
        }
    }

    private func bindText(_ stmt: OpaquePointer?, _ idx: Int32, _ value: String) {
        sqlite3_bind_text(stmt, idx, value, -1, SQLITE_TRANSIENT)
    }

    private func bindOptionalText(_ stmt: OpaquePointer?, _ idx: Int32, _ value: String?) {
        if let v = value {
            sqlite3_bind_text(stmt, idx, v, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, idx)
        }
    }

    private func readText(_ stmt: OpaquePointer?, _ col: Int32) -> String? {
        guard let raw = sqlite3_column_text(stmt, col) else { return nil }
        return String(cString: raw)
    }

    private func readClipboardRows(_ stmt: OpaquePointer?) -> [ClipboardItem] {
        var out: [ClipboardItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idStr = readText(stmt, 0),
                  let uuid = UUID(uuidString: idStr),
                  let kindRaw = readText(stmt, 1),
                  let kind = ClipboardItem.Kind(rawValue: kindRaw),
                  let content = readText(stmt, 2) else { continue }
            let imagePath = readText(stmt, 3)
            let sourceApp = readText(stmt, 4)
            let ts = sqlite3_column_double(stmt, 5)
            out.append(ClipboardItem(
                id: uuid,
                kind: kind,
                content: content,
                imagePath: imagePath,
                sourceApp: sourceApp,
                createdAt: Date(timeIntervalSince1970: ts)
            ))
        }
        return out
    }

    private func lastErr(_ handle: OpaquePointer?) -> String {
        guard let handle, let raw = sqlite3_errmsg(handle) else { return "unknown" }
        return String(cString: raw)
    }
}

/// SQLite "瞬时"绑定标志:让 SQLite 复制传入的字节,而不是持有指针。
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
