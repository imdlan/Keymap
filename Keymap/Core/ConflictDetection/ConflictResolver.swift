//
//  ConflictResolver.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

/// 冲突解决策略
enum ResolutionStrategy: String, Codable {
    case disable = "禁用"     // 禁用某个应用的快捷键
    case remap = "重映射"     // 重新映射快捷键
    case ignore = "忽略"      // 忽略冲突
    case manual = "手动处理"  // 需要用户手动处理
}

/// 解决方案记录
struct ResolutionRecord: Codable {
    let conflictId: String
    let strategy: ResolutionStrategy
    let timestamp: Date
    let details: String

    init(
        conflictId: String,
        strategy: ResolutionStrategy,
        details: String = ""
    ) {
        self.conflictId = conflictId
        self.strategy = strategy
        self.timestamp = Date()
        self.details = details
    }
}

/// 冲突解决器 - 执行冲突解决方案
class ConflictResolver {

    // MARK: - Properties

    /// 解决方案记录（存储用户的选择）
    private var resolutionRecords: [String: ResolutionRecord] = [:]

    /// UserDefaults 键
    private let recordsKey = "conflict_resolution_records"

    // MARK: - Initialization

    init() {
        loadRecords()
    }

    // MARK: - Public Methods

    /// 执行冲突解决策略
    /// - Parameters:
    ///   - conflict: 冲突信息
    ///   - strategy: 解决策略
    /// - Returns: 是否成功
    func resolveConflict(
        _ conflict: ConflictInfo,
        strategy: ResolutionStrategy
    ) -> Bool {
        print("🔧 执行冲突解决: \(conflict.id) - 策略: \(strategy.rawValue)")

        switch strategy {
        case .disable:
            return disableShortcut(conflict)

        case .remap:
            // 重映射功能在阶段5实现
            print("⚠️ 重映射功能尚未实现（阶段5）")
            return false

        case .ignore:
            return ignoreConflict(conflict)

        case .manual:
            return markForManualResolution(conflict)
        }
    }

    /// 禁用指定快捷键
    /// - Parameter conflict: 冲突信息
    /// - Returns: 是否成功
    func disableShortcut(_ conflict: ConflictInfo) -> Bool {
        // 记录禁用操作
        let record = ResolutionRecord(
            conflictId: conflict.id,
            strategy: .disable,
            details: "已禁用快捷键: \(conflict.shortcutId)"
        )

        resolutionRecords[conflict.id] = record
        saveRecords()

        print("✅ 已禁用快捷键: \(conflict.shortcutId)")

        // 注意：实际的禁用操作需要与快捷键管理系统集成
        // 这里只是记录用户的选择，真正的禁用会在阶段5的重映射功能中实现

        return true
    }

    /// 忽略冲突
    /// - Parameter conflict: 冲突信息
    /// - Returns: 是否成功
    func ignoreConflict(_ conflict: ConflictInfo) -> Bool {
        let record = ResolutionRecord(
            conflictId: conflict.id,
            strategy: .ignore,
            details: "用户选择忽略此冲突"
        )

        resolutionRecords[conflict.id] = record
        saveRecords()

        print("ℹ️ 已忽略冲突: \(conflict.id)")
        return true
    }

    /// 标记为手动处理
    /// - Parameter conflict: 冲突信息
    /// - Returns: 是否成功
    func markForManualResolution(_ conflict: ConflictInfo) -> Bool {
        let record = ResolutionRecord(
            conflictId: conflict.id,
            strategy: .manual,
            details: "标记为需要手动处理"
        )

        resolutionRecords[conflict.id] = record
        saveRecords()

        print("📝 已标记为手动处理: \(conflict.id)")
        return true
    }

    /// 获取冲突的解决方案
    /// - Parameter conflictId: 冲突ID
    /// - Returns: 解决方案记录
    func getResolution(for conflictId: String) -> ResolutionRecord? {
        return resolutionRecords[conflictId]
    }

    /// 检查冲突是否已解决
    /// - Parameter conflictId: 冲突ID
    /// - Returns: 是否已解决
    func isResolved(_ conflictId: String) -> Bool {
        guard let record = resolutionRecords[conflictId] else {
            return false
        }

        // 忽略策略不算真正解决
        return record.strategy != .ignore && record.strategy != .manual
    }

    /// 获取所有解决记录
    /// - Returns: 解决记录数组
    func getAllResolutions() -> [ResolutionRecord] {
        return Array(resolutionRecords.values)
    }

    /// 清除指定冲突的解决记录
    /// - Parameter conflictId: 冲突ID
    func clearResolution(for conflictId: String) {
        resolutionRecords.removeValue(forKey: conflictId)
        saveRecords()
        print("🗑 已清除解决记录: \(conflictId)")
    }

    /// 清除所有解决记录
    func clearAllResolutions() {
        resolutionRecords.removeAll()
        saveRecords()
        print("🗑 已清除所有解决记录")
    }

    /// 获取解决统计
    /// - Returns: (总数, 已解决, 已忽略, 待手动处理)
    func getResolutionStatistics() -> (total: Int, resolved: Int, ignored: Int, manual: Int) {
        let total = resolutionRecords.count
        var resolved = 0
        var ignored = 0
        var manual = 0

        for record in resolutionRecords.values {
            switch record.strategy {
            case .disable, .remap:
                resolved += 1
            case .ignore:
                ignored += 1
            case .manual:
                manual += 1
            }
        }

        return (total, resolved, ignored, manual)
    }

    // MARK: - Private Methods

    /// 加载解决记录
    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            let records = try decoder.decode([String: ResolutionRecord].self, from: data)
            resolutionRecords = records
            print("📦 加载了 \(records.count) 条解决记录")
        } catch {
            print("❌ 加载解决记录失败: \(error.localizedDescription)")
        }
    }

    /// 保存解决记录
    private func saveRecords() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(resolutionRecords)
            UserDefaults.standard.set(data, forKey: recordsKey)
            print("💾 保存了 \(resolutionRecords.count) 条解决记录")
        } catch {
            print("❌ 保存解决记录失败: \(error.localizedDescription)")
        }
    }
}
