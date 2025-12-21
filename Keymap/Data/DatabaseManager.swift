//
//  DatabaseManager.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation
import SQLite3

/// SQLite数据库管理器（单例）
class DatabaseManager {

    // MARK: - Singleton

    static let shared = DatabaseManager()

    // MARK: - Properties

    private var db: OpaquePointer?
    private let databasePath: String

    // MARK: - Initialization

    private init() {
        // 数据库路径：~/Library/Application Support/Keymap/keymap.db
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let keymapDirectory = appSupportURL.appendingPathComponent("Keymap")

        // 创建目录（如果不存在）
        if !fileManager.fileExists(atPath: keymapDirectory.path) {
            try? fileManager.createDirectory(at: keymapDirectory, withIntermediateDirectories: true)
        }

        databasePath = keymapDirectory.appendingPathComponent("keymap.db").path

        // 打开数据库
        openDatabase()

        // 创建表结构
        setupDatabase()
    }

    deinit {
        closeDatabase()
    }

    // MARK: - Database Operations

    /// 打开数据库连接
    private func openDatabase() {
        if sqlite3_open(databasePath, &db) == SQLITE_OK {
            print("✅ 数据库打开成功: \(databasePath)")
        } else {
            print("❌ 数据库打开失败")
            db = nil
        }
    }

    /// 关闭数据库连接
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            print("🔒 数据库已关闭")
        }
    }

    /// 初始化数据库表结构
    @discardableResult
    func setupDatabase() -> Bool {
        guard db != nil else {
            print("❌ 数据库未打开")
            return false
        }

        // 创建所有表
        let tables = [
            createApplicationsTable(),
            createShortcutsTable(),
            createConflictsTable(),
            createUsageRecordsTable(),
            createStatisticsSummaryTable()
        ]

        let success = tables.allSatisfy { $0 }

        if success {
            print("✅ 数据库表结构创建成功")
        } else {
            print("❌ 数据库表结构创建失败")
        }

        return success
    }

    // MARK: - Table Creation

    /// 创建应用表
    private func createApplicationsTable() -> Bool {
        let sql = """
        CREATE TABLE IF NOT EXISTS applications (
            bundle_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon_data BLOB,
            first_seen INTEGER NOT NULL,
            last_updated INTEGER NOT NULL
        );
        """
        return executeUpdate(sql)
    }

    /// 创建快捷键表
    private func createShortcutsTable() -> Bool {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS shortcuts (
            id TEXT PRIMARY KEY,
            key_combination TEXT NOT NULL,
            description TEXT NOT NULL,
            bundle_id TEXT NOT NULL,
            category TEXT NOT NULL,
            is_custom INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (bundle_id) REFERENCES applications(bundle_id)
        );
        """

        let createIndex1 = """
        CREATE INDEX IF NOT EXISTS idx_shortcuts_key ON shortcuts(key_combination);
        """

        let createIndex2 = """
        CREATE INDEX IF NOT EXISTS idx_shortcuts_bundle ON shortcuts(bundle_id);
        """

        return executeUpdate(createTableSQL) &&
               executeUpdate(createIndex1) &&
               executeUpdate(createIndex2)
    }

    /// 创建冲突表
    private func createConflictsTable() -> Bool {
        let sql = """
        CREATE TABLE IF NOT EXISTS conflicts (
            id TEXT PRIMARY KEY,
            shortcut_id TEXT NOT NULL,
            conflict_type TEXT NOT NULL,
            conflicting_bundle_id TEXT,
            severity TEXT NOT NULL,
            detected_at INTEGER NOT NULL,
            resolved INTEGER DEFAULT 0,
            FOREIGN KEY (shortcut_id) REFERENCES shortcuts(id)
        );
        """
        return executeUpdate(sql)
    }

    /// 创建使用记录表
    private func createUsageRecordsTable() -> Bool {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS usage_records (
            id TEXT PRIMARY KEY,
            shortcut_key TEXT NOT NULL,
            bundle_id TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            context TEXT NOT NULL,
            FOREIGN KEY (bundle_id) REFERENCES applications(bundle_id)
        );
        """

        let createIndex1 = """
        CREATE INDEX IF NOT EXISTS idx_usage_timestamp ON usage_records(timestamp);
        """

        let createIndex2 = """
        CREATE INDEX IF NOT EXISTS idx_usage_shortcut ON usage_records(shortcut_key);
        """

        return executeUpdate(createTableSQL) &&
               executeUpdate(createIndex1) &&
               executeUpdate(createIndex2)
    }

    /// 创建统计摘要表
    private func createStatisticsSummaryTable() -> Bool {
        let sql = """
        CREATE TABLE IF NOT EXISTS statistics_summary (
            bundle_id TEXT NOT NULL,
            shortcut_key TEXT NOT NULL,
            date TEXT NOT NULL,
            usage_count INTEGER NOT NULL,
            PRIMARY KEY (bundle_id, shortcut_key, date)
        );
        """
        return executeUpdate(sql)
    }

    // MARK: - Query Execution

    /// 执行查询（SELECT）
    /// - Parameter sql: SQL语句
    /// - Returns: 查询结果数组
    func executeQuery(_ sql: String) -> [[String: Any]] {
        var results: [[String: Any]] = []
        var statement: OpaquePointer?

        guard db != nil else {
            print("❌ 数据库未打开")
            return results
        }

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            // 获取列数
            let columnCount = sqlite3_column_count(statement)

            // 遍历所有行
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: Any] = [:]

                for i in 0..<columnCount {
                    let columnName = String(cString: sqlite3_column_name(statement, i))
                    let columnType = sqlite3_column_type(statement, i)

                    switch columnType {
                    case SQLITE_INTEGER:
                        row[columnName] = sqlite3_column_int64(statement, i)
                    case SQLITE_FLOAT:
                        row[columnName] = sqlite3_column_double(statement, i)
                    case SQLITE_TEXT:
                        if let text = sqlite3_column_text(statement, i) {
                            row[columnName] = String(cString: text)
                        }
                    case SQLITE_BLOB:
                        let dataSize = sqlite3_column_bytes(statement, i)
                        if let dataPointer = sqlite3_column_blob(statement, i) {
                            row[columnName] = Data(bytes: dataPointer, count: Int(dataSize))
                        }
                    case SQLITE_NULL:
                        row[columnName] = NSNull()
                    default:
                        break
                    }
                }

                results.append(row)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ SQL执行失败: \(errorMessage)")
            print("   SQL: \(sql)")
        }

        sqlite3_finalize(statement)
        return results
    }

    /// 执行更新（INSERT, UPDATE, DELETE）
    /// - Parameter sql: SQL语句
    /// - Returns: 是否成功
    @discardableResult
    func executeUpdate(_ sql: String) -> Bool {
        var statement: OpaquePointer?

        guard db != nil else {
            print("❌ 数据库未打开")
            return false
        }

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ SQL执行失败: \(errorMessage)")
                print("   SQL: \(sql)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ SQL准备失败: \(errorMessage)")
            print("   SQL: \(sql)")
        }

        sqlite3_finalize(statement)
        return false
    }

    /// 执行带参数的更新
    /// - Parameters:
    ///   - sql: SQL语句（使用?作为占位符）
    ///   - parameters: 参数数组
    /// - Returns: 是否成功
    @discardableResult
    func executeUpdate(_ sql: String, parameters: [Any]) -> Bool {
        var statement: OpaquePointer?

        guard db != nil else {
            print("❌ 数据库未打开")
            return false
        }

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            // 绑定参数
            for (index, parameter) in parameters.enumerated() {
                let bindIndex = Int32(index + 1)

                if let text = parameter as? String {
                    sqlite3_bind_text(statement, bindIndex, (text as NSString).utf8String, -1, nil)
                } else if let number = parameter as? Int {
                    sqlite3_bind_int64(statement, bindIndex, Int64(number))
                } else if let number = parameter as? Int64 {
                    sqlite3_bind_int64(statement, bindIndex, number)
                } else if let number = parameter as? Double {
                    sqlite3_bind_double(statement, bindIndex, number)
                } else if let data = parameter as? Data {
                    _ = data.withUnsafeBytes { bytes in
                        sqlite3_bind_blob(statement, bindIndex, bytes.baseAddress, Int32(data.count), nil)
                    }
                } else if parameter is NSNull {
                    sqlite3_bind_null(statement, bindIndex)
                }
            }

            // 执行
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ SQL执行失败: \(errorMessage)")
                print("   SQL: \(sql)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ SQL准备失败: \(errorMessage)")
            print("   SQL: \(sql)")
        }

        sqlite3_finalize(statement)
        return false
    }

    // MARK: - Transaction Support

    /// 开始事务
    func beginTransaction() -> Bool {
        return executeUpdate("BEGIN TRANSACTION;")
    }

    /// 提交事务
    func commitTransaction() -> Bool {
        return executeUpdate("COMMIT;")
    }

    /// 回滚事务
    func rollbackTransaction() -> Bool {
        return executeUpdate("ROLLBACK;")
    }

    // MARK: - Utility Methods

    /// 获取最后插入的行ID
    var lastInsertRowId: Int64 {
        guard let db = db else { return 0 }
        return sqlite3_last_insert_rowid(db)
    }

    /// 获取受影响的行数
    var changesCount: Int {
        guard let db = db else { return 0 }
        return Int(sqlite3_changes(db))
    }

    /// 清空所有表（仅用于测试）
    func clearAllTables() -> Bool {
        let tables = [
            "statistics_summary",
            "usage_records",
            "conflicts",
            "shortcuts",
            "applications"
        ]

        var success = true
        for table in tables {
            success = success && executeUpdate("DELETE FROM \(table);")
        }

        if success {
            print("🗑 所有表已清空")
        }

        return success
    }

    /// 删除数据库文件（仅用于测试）
    func deleteDatabase() -> Bool {
        closeDatabase()

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: databasePath) {
            do {
                try fileManager.removeItem(atPath: databasePath)
                print("🗑 数据库文件已删除")
                return true
            } catch {
                print("❌ 删除数据库文件失败: \(error.localizedDescription)")
                return false
            }
        }

        return true
    }
}
