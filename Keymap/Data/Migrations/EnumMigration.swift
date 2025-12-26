//
//  EnumMigration.swift
//  Keymap
//
//  Created on 2025-12-25.
//  数据库枚举值迁移脚本：中文 rawValue → 英文 rawValue
//

import Foundation

/// 枚举值数据库迁移工具
class EnumMigration {

    // MARK: - Properties

    private static let migrationKey = "enum_migration_completed_v1"
    private static let db = DatabaseManager.shared

    // MARK: - Mapping Tables

    /// ShortcutCategory 映射表（中文 → 英文）
    private static let categoryMapping: [String: String] = [
        "文件": "file",
        "编辑": "edit",
        "视图": "view",
        "窗口": "window",
        "系统": "system",
        "导航": "navigation",
        "其他": "other"
    ]

    /// ConflictType 映射表
    private static let conflictTypeMapping: [String: String] = [
        "系统级": "system",
        "应用级": "application",
        "全局": "global",
        "功能": "functional"
    ]

    /// ConflictSeverity 映射表
    private static let severityMapping: [String: String] = [
        "低": "low",
        "中": "medium",
        "高": "high"
    ]

    /// UsageContext 映射表
    private static let contextMapping: [String: String] = [
        "正常": "normal",
        "冲突": "conflict",
        "重映射": "remapped"
    ]

    // MARK: - Migration Status

    /// 检查是否需要迁移
    static func needsMigration() -> Bool {
        // 如果已经标记为迁移完成，则不需要再次迁移
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return false
        }

        // 检查数据库中是否有中文枚举值
        return hasChinese(in: "shortcuts", column: "category") ||
               hasChinese(in: "conflicts", column: "conflict_type") ||
               hasChinese(in: "conflicts", column: "severity") ||
               hasChinese(in: "usage_records", column: "context")
    }

    /// 检查指定表和列是否包含中文值
    private static func hasChinese(in table: String, column: String) -> Bool {
        let sql = "SELECT DISTINCT \(column) FROM \(table) LIMIT 100;"
        let results = db.executeQuery(sql)

        for row in results {
            if let value = row[column] as? String {
                // 检查是否包含中文字符
                if value.range(of: "[\\u4e00-\\u9fa5]", options: .regularExpression) != nil {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Migration Execution

    /// 执行迁移
    static func migrate() throws {
        print("🔄 开始枚举值数据库迁移...")

        // 备份数据库（可选，安全起见）
        let backupPath = createBackup()
        print("📦 数据库已备份到: \(backupPath ?? "N/A")")

        // 开始事务
        guard db.beginTransaction() else {
            throw MigrationError.transactionFailed
        }

        do {
            // 迁移各个表
            try migrateShortcutsTable()
            try migrateConflictsTable()
            try migrateUsageRecordsTable()

            // 提交事务
            if db.commitTransaction() {
                // 标记迁移完成
                UserDefaults.standard.set(true, forKey: migrationKey)
                print("✅ 枚举值迁移成功")
            } else {
                throw MigrationError.commitFailed
            }
        } catch {
            // 回滚事务
            db.rollbackTransaction()
            print("❌ 迁移失败，已回滚: \(error.localizedDescription)")
            throw error
        }
    }

    /// 迁移 shortcuts 表的 category 列
    private static func migrateShortcutsTable() throws {
        print("   📋 迁移 shortcuts.category...")

        var updateCount = 0

        for (chinese, english) in categoryMapping {
            let sql = "UPDATE shortcuts SET category = ? WHERE category = ?;"
            if db.executeUpdate(sql, parameters: [english, chinese]) {
                updateCount += db.changesCount
            }
        }

        print("   ✅ shortcuts.category 迁移完成（更新 \(updateCount) 行）")
    }

    /// 迁移 conflicts 表的 conflict_type 和 severity 列
    private static func migrateConflictsTable() throws {
        print("   📋 迁移 conflicts.conflict_type 和 conflicts.severity...")

        var updateCount = 0

        // 迁移 conflict_type
        for (chinese, english) in conflictTypeMapping {
            let sql = "UPDATE conflicts SET conflict_type = ? WHERE conflict_type = ?;"
            if db.executeUpdate(sql, parameters: [english, chinese]) {
                updateCount += db.changesCount
            }
        }

        // 迁移 severity
        for (chinese, english) in severityMapping {
            let sql = "UPDATE conflicts SET severity = ? WHERE severity = ?;"
            if db.executeUpdate(sql, parameters: [english, chinese]) {
                updateCount += db.changesCount
            }
        }

        print("   ✅ conflicts 迁移完成（更新 \(updateCount) 行）")
    }

    /// 迁移 usage_records 表的 context 列
    private static func migrateUsageRecordsTable() throws {
        print("   📋 迁移 usage_records.context...")

        var updateCount = 0

        for (chinese, english) in contextMapping {
            let sql = "UPDATE usage_records SET context = ? WHERE context = ?;"
            if db.executeUpdate(sql, parameters: [english, chinese]) {
                updateCount += db.changesCount
            }
        }

        print("   ✅ usage_records.context 迁移完成（更新 \(updateCount) 行）")
    }

    // MARK: - Backup & Recovery

    /// 创建数据库备份
    private static func createBackup() -> String? {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let keymapDirectory = appSupportURL.appendingPathComponent("Keymap")
        let dbPath = keymapDirectory.appendingPathComponent("keymap.db").path

        // 备份文件名：keymap_backup_<timestamp>.db
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")

        let backupPath = keymapDirectory.appendingPathComponent("keymap_backup_\(timestamp).db").path

        do {
            try fileManager.copyItem(atPath: dbPath, toPath: backupPath)
            return backupPath
        } catch {
            print("⚠️ 数据库备份失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 回滚迁移（从备份恢复）
    static func rollback(from backupPath: String) -> Bool {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let keymapDirectory = appSupportURL.appendingPathComponent("Keymap")
        let dbPath = keymapDirectory.appendingPathComponent("keymap.db").path

        do {
            // 删除当前数据库
            if fileManager.fileExists(atPath: dbPath) {
                try fileManager.removeItem(atPath: dbPath)
            }

            // 从备份恢复
            try fileManager.copyItem(atPath: backupPath, toPath: dbPath)

            // 清除迁移标记
            UserDefaults.standard.removeObject(forKey: migrationKey)

            print("✅ 数据库已从备份恢复")
            return true
        } catch {
            print("❌ 数据库恢复失败: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Statistics

    /// 获取迁移统计信息
    static func getMigrationStatistics() -> MigrationStatistics {
        let shortcuts = countRecords(in: "shortcuts")
        let conflicts = countRecords(in: "conflicts")
        let usageRecords = countRecords(in: "usage_records")

        let chineseShortcuts = countChinese(in: "shortcuts", column: "category")
        let chineseConflicts = countChinese(in: "conflicts", column: "conflict_type") +
                              countChinese(in: "conflicts", column: "severity")
        let chineseUsageRecords = countChinese(in: "usage_records", column: "context")

        return MigrationStatistics(
            totalShortcuts: shortcuts,
            totalConflicts: conflicts,
            totalUsageRecords: usageRecords,
            chineseShortcuts: chineseShortcuts,
            chineseConflicts: chineseConflicts,
            chineseUsageRecords: chineseUsageRecords,
            isMigrated: UserDefaults.standard.bool(forKey: migrationKey)
        )
    }

    private static func countRecords(in table: String) -> Int {
        let sql = "SELECT COUNT(*) as count FROM \(table);"
        let results = db.executeQuery(sql)
        if let first = results.first, let count = first["count"] as? Int64 {
            return Int(count)
        }
        return 0
    }

    private static func countChinese(in table: String, column: String) -> Int {
        let sql = "SELECT COUNT(*) as count FROM \(table) WHERE \(column) GLOB '*[一-龥]*';"
        let results = db.executeQuery(sql)
        if let first = results.first, let count = first["count"] as? Int64 {
            return Int(count)
        }
        return 0
    }
}

// MARK: - Supporting Types

/// 迁移错误类型
enum MigrationError: LocalizedError {
    case transactionFailed
    case commitFailed
    case backupFailed

    var errorDescription: String? {
        switch self {
        case .transactionFailed:
            return "开始数据库事务失败"
        case .commitFailed:
            return "提交数据库事务失败"
        case .backupFailed:
            return "创建数据库备份失败"
        }
    }
}

/// 迁移统计信息
struct MigrationStatistics {
    let totalShortcuts: Int
    let totalConflicts: Int
    let totalUsageRecords: Int
    let chineseShortcuts: Int
    let chineseConflicts: Int
    let chineseUsageRecords: Int
    let isMigrated: Bool

    var needsMigration: Bool {
        return !isMigrated && (chineseShortcuts > 0 || chineseConflicts > 0 || chineseUsageRecords > 0)
    }

    var description: String {
        """
        📊 迁移统计信息:
           - 快捷键总数: \(totalShortcuts) (需迁移: \(chineseShortcuts))
           - 冲突总数: \(totalConflicts) (需迁移: \(chineseConflicts))
           - 使用记录总数: \(totalUsageRecords) (需迁移: \(chineseUsageRecords))
           - 迁移状态: \(isMigrated ? "✅ 已完成" : "⚠️ 未完成")
        """
    }
}
