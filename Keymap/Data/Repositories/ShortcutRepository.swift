//
//  ShortcutRepository.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation
import AppKit

/// 快捷键数据访问层
class ShortcutRepository {

    // MARK: - Properties

    private let db = DatabaseManager.shared

    // MARK: - Public Methods

    /// 保存快捷键
    /// - Parameter shortcut: 快捷键信息
    /// - Returns: 是否成功
    func save(_ shortcut: ShortcutInfo) -> Bool {
        // 1. 确保应用记录存在
        if !ensureApplicationExists(bundleId: shortcut.application, name: shortcut.application) {
            print("❌ 创建应用记录失败: \(shortcut.application)")
            return false
        }

        // 2. 检查快捷键是否已存在
        if shortcutExists(id: shortcut.id) {
            return updateShortcut(shortcut)
        } else {
            return insertShortcut(shortcut)
        }
    }

    /// 批量保存快捷键
    /// - Parameter shortcuts: 快捷键数组
    /// - Returns: 成功保存的数量
    func saveBatch(_ shortcuts: [ShortcutInfo]) -> Int {
        var successCount = 0

        _ = db.beginTransaction()

        for shortcut in shortcuts {
            if save(shortcut) {
                successCount += 1
            }
        }

        if successCount == shortcuts.count {
            _ = db.commitTransaction()
        } else {
            _ = db.rollbackTransaction()
            print("⚠️ 批量保存失败，已回滚")
            return 0
        }

        print("✅ 批量保存成功: \(successCount)/\(shortcuts.count)")
        return successCount
    }

    /// 获取应用的所有快捷键
    /// - Parameter bundleId: 应用Bundle ID
    /// - Returns: 快捷键数组
    func fetchShortcuts(for bundleId: String) -> [ShortcutInfo] {
        let sql = """
        SELECT * FROM shortcuts
        WHERE bundle_id = '\(bundleId)'
        ORDER BY category, description;
        """

        let rows = db.executeQuery(sql)
        return rows.compactMap { parseShortcutInfo(from: $0) }
    }

    /// 获取所有快捷键
    /// - Returns: 快捷键数组
    func fetchAllShortcuts() -> [ShortcutInfo] {
        let sql = """
        SELECT * FROM shortcuts
        ORDER BY bundle_id, category, description;
        """

        let rows = db.executeQuery(sql)
        return rows.compactMap { parseShortcutInfo(from: $0) }
    }

    /// 搜索快捷键
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的快捷键数组
    func searchShortcuts(query: String) -> [ShortcutInfo] {
        let sanitizedQuery = query.replacingOccurrences(of: "'", with: "''")

        let sql = """
        SELECT * FROM shortcuts
        WHERE description LIKE '%\(sanitizedQuery)%'
           OR key_combination LIKE '%\(sanitizedQuery)%'
           OR bundle_id LIKE '%\(sanitizedQuery)%'
        ORDER BY bundle_id, description
        LIMIT 100;
        """

        let rows = db.executeQuery(sql)
        return rows.compactMap { parseShortcutInfo(from: $0) }
    }

    /// 根据快捷键组合查找
    /// - Parameter keyCombination: 快捷键组合
    /// - Returns: 匹配的快捷键数组
    func findByKeyCombination(_ keyCombination: String) -> [ShortcutInfo] {
        let sql = """
        SELECT * FROM shortcuts
        WHERE key_combination = '\(keyCombination)'
        ORDER BY bundle_id;
        """

        let rows = db.executeQuery(sql)
        return rows.compactMap { parseShortcutInfo(from: $0) }
    }

    /// 删除快捷键
    /// - Parameter id: 快捷键ID
    /// - Returns: 是否成功
    func deleteShortcut(id: String) -> Bool {
        let sql = "DELETE FROM shortcuts WHERE id = '\(id)';"
        let success = db.executeUpdate(sql)

        if success {
            print("✅ 快捷键已删除: \(id)")
        }

        return success
    }

    /// 删除应用的所有快捷键
    /// - Parameter bundleId: 应用Bundle ID
    /// - Returns: 是否成功
    func deleteShortcuts(for bundleId: String) -> Bool {
        let sql = "DELETE FROM shortcuts WHERE bundle_id = '\(bundleId)';"
        let success = db.executeUpdate(sql)

        if success {
            let count = db.changesCount
            print("✅ 已删除 \(bundleId) 的 \(count) 个快捷键")
        }

        return success
    }

    /// 获取快捷键数量统计
    /// - Returns: (总数, 自定义数, 应用数)
    func getStatistics() -> (total: Int, custom: Int, appCount: Int) {
        // 总数
        let totalSQL = "SELECT COUNT(*) as count FROM shortcuts;"
        let totalRows = db.executeQuery(totalSQL)
        let total = totalRows.first?["count"] as? Int64 ?? 0

        // 自定义数
        let customSQL = "SELECT COUNT(*) as count FROM shortcuts WHERE is_custom = 1;"
        let customRows = db.executeQuery(customSQL)
        let custom = customRows.first?["count"] as? Int64 ?? 0

        // 应用数
        let appSQL = "SELECT COUNT(DISTINCT bundle_id) as count FROM shortcuts;"
        let appRows = db.executeQuery(appSQL)
        let appCount = appRows.first?["count"] as? Int64 ?? 0

        return (Int(total), Int(custom), Int(appCount))
    }

    /// 获取应用列表
    /// - Returns: Bundle ID 数组
    func getApplications() -> [String] {
        let sql = """
        SELECT DISTINCT bundle_id FROM shortcuts
        ORDER BY bundle_id;
        """

        let rows = db.executeQuery(sql)
        return rows.compactMap { $0["bundle_id"] as? String }
    }

    // MARK: - Private Methods

    /// 检查快捷键是否存在
    private func shortcutExists(id: String) -> Bool {
        let sql = "SELECT COUNT(*) as count FROM shortcuts WHERE id = '\(id)';"
        let rows = db.executeQuery(sql)
        let count = rows.first?["count"] as? Int64 ?? 0
        return count > 0
    }

    /// 插入快捷键
    private func insertShortcut(_ shortcut: ShortcutInfo) -> Bool {
        let sql = """
        INSERT INTO shortcuts (id, key_combination, description, bundle_id, category, is_custom, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """

        let parameters: [Any] = [
            shortcut.id,
            shortcut.keyCombination,
            shortcut.description,
            shortcut.application,
            shortcut.category.rawValue,
            0,  // is_custom = 0（非自定义）
            Int64(Date().timeIntervalSince1970)
        ]

        return db.executeUpdate(sql, parameters: parameters)
    }

    /// 更新快捷键
    private func updateShortcut(_ shortcut: ShortcutInfo) -> Bool {
        let sql = """
        UPDATE shortcuts
        SET key_combination = ?, description = ?, bundle_id = ?, category = ?
        WHERE id = ?;
        """

        let parameters: [Any] = [
            shortcut.keyCombination,
            shortcut.description,
            shortcut.application,
            shortcut.category.rawValue,
            shortcut.id
        ]

        return db.executeUpdate(sql, parameters: parameters)
    }

    /// 确保应用记录存在
    private func ensureApplicationExists(bundleId: String, name: String) -> Bool {
        // 检查是否已存在
        let checkSQL = "SELECT COUNT(*) as count FROM applications WHERE bundle_id = '\(bundleId)';"
        let rows = db.executeQuery(checkSQL)
        let count = rows.first?["count"] as? Int64 ?? 0

        if count > 0 {
            // 更新最后更新时间
            let updateSQL = """
            UPDATE applications
            SET last_updated = ?
            WHERE bundle_id = ?;
            """
            return db.executeUpdate(updateSQL, parameters: [
                Int64(Date().timeIntervalSince1970),
                bundleId
            ])
        } else {
            // 创建新记录
            let insertSQL = """
            INSERT INTO applications (bundle_id, name, first_seen, last_updated)
            VALUES (?, ?, ?, ?);
            """

            let timestamp = Int64(Date().timeIntervalSince1970)
            return db.executeUpdate(insertSQL, parameters: [
                bundleId,
                name,
                timestamp,
                timestamp
            ])
        }
    }

    /// 从数据库行解析ShortcutInfo
    private func parseShortcutInfo(from row: [String: Any]) -> ShortcutInfo? {
        guard let id = row["id"] as? String,
              let keyCombination = row["key_combination"] as? String,
              let description = row["description"] as? String,
              let bundleId = row["bundle_id"] as? String,
              let categoryString = row["category"] as? String,
              let category = ShortcutCategory(rawValue: categoryString) else {
            return nil
        }

        return ShortcutInfo(
            id: id,
            keyCombination: keyCombination,
            description: description,
            application: bundleId,
            category: category
        )
    }
}
