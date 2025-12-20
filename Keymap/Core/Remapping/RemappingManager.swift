//
//  RemappingManager.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

/// 重映射管理器 - 负责重映射规则的持久化和管理
class RemappingManager {

    // MARK: - Singleton

    static let shared = RemappingManager()

    // MARK: - Properties

    private let engine = RemappingEngine()
    private let defaults = UserDefaults.standard
    private let rulesKey = "remapping_rules"

    // MARK: - Initialization

    private init() {
        loadRemappings()
    }

    // MARK: - Public Methods

    /// 添加重映射规则
    /// - Parameters:
    ///   - rule: 重映射规则
    /// - Returns: 是否成功
    func addRemapping(_ rule: RemappingRule) -> Bool {
        guard engine.addRemapping(from: rule.fromKey, to: rule.toKey, in: rule.bundleId) else {
            return false
        }

        saveRemappings()
        return true
    }

    /// 移除重映射规则
    /// - Parameter rule: 重映射规则
    func removeRemapping(_ rule: RemappingRule) {
        engine.removeRemapping(from: rule.fromKey, in: rule.bundleId)
        saveRemappings()
    }

    /// 获取重映射后的快捷键
    /// - Parameters:
    ///   - key: 原快捷键组合
    ///   - bundleId: 应用Bundle ID
    /// - Returns: 重映射后的快捷键，如果没有映射则返回nil
    func getRemappedKey(_ key: String, for bundleId: String) -> String? {
        return engine.getRemappedKey(key, for: bundleId)
    }

    /// 清除指定应用的所有重映射
    /// - Parameter bundleId: 应用Bundle ID
    func clearRemappings(for bundleId: String) {
        engine.clearRemappings(for: bundleId)
        saveRemappings()
    }

    /// 清除所有重映射
    func clearAllRemappings() {
        engine.clearAllRemappings()
        saveRemappings()
    }

    /// 获取所有重映射规则
    /// - Returns: 重映射规则数组
    func getAllRules() -> [RemappingRule] {
        return engine.getAllRules()
    }

    /// 获取指定应用的重映射规则
    /// - Parameter bundleId: 应用Bundle ID
    /// - Returns: 重映射规则数组
    func getRules(for bundleId: String) -> [RemappingRule] {
        return engine.getRules(for: bundleId)
    }

    /// 获取重映射统计
    /// - Returns: (总规则数, 应用数)
    func getStatistics() -> (totalRules: Int, appCount: Int) {
        return engine.getStatistics()
    }

    /// 检查快捷键是否已被重映射
    /// - Parameters:
    ///   - key: 快捷键组合
    ///   - bundleId: 应用Bundle ID
    /// - Returns: 是否已被重映射
    func isRemapped(_ key: String, in bundleId: String) -> Bool {
        return engine.isRemapped(key, in: bundleId)
    }

    /// 验证重映射规则的有效性
    /// - Parameter rule: 重映射规则
    /// - Returns: (是否有效, 错误信息)
    func validateRemapping(_ rule: RemappingRule) -> (isValid: Bool, errorMessage: String?) {
        // 1. 检查键是否相同
        if rule.fromKey == rule.toKey {
            return (false, "源键和目标键不能相同")
        }

        // 2. 检查是否是系统保留快捷键
        let systemReservedKeys: Set<String> = [
            "⌘Q", "⌘⌥Esc", "⌘Space", "⌃⌘Q", "⌃⌘Power"
        ]

        if systemReservedKeys.contains(rule.toKey) {
            return (false, "\(rule.toKey) 是系统保留快捷键，不能作为目标")
        }

        // 3. 检查循环映射
        if let existingMapping = engine.getRemappedKey(rule.toKey, for: rule.bundleId),
           existingMapping == rule.fromKey {
            return (false, "会创建循环映射: \(rule.fromKey)↔\(rule.toKey)")
        }

        // 4. 检查链式映射
        if let existingMapping = engine.getRemappedKey(rule.toKey, for: rule.bundleId) {
            return (false, "\(rule.toKey) 已被映射到 \(existingMapping)，不支持链式映射")
        }

        // 5. 检查快捷键格式
        if !isValidKeyFormat(rule.fromKey) {
            return (false, "源键格式无效: \(rule.fromKey)")
        }

        if !isValidKeyFormat(rule.toKey) {
            return (false, "目标键格式无效: \(rule.toKey)")
        }

        return (true, nil)
    }

    /// 导出重映射规则
    /// - Returns: JSON 格式的规则数据
    func exportRemappings() -> Data? {
        let rules = engine.getAllRules()

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(rules)
        } catch {
            print("❌ 导出重映射规则失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 导入重映射规则
    /// - Parameter data: JSON 格式的规则数据
    /// - Returns: (成功数, 失败数)
    func importRemappings(_ data: Data) -> (success: Int, failed: Int) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let rules = try decoder.decode([RemappingRule].self, from: data)

            var successCount = 0
            var failedCount = 0

            for rule in rules {
                if addRemapping(rule) {
                    successCount += 1
                } else {
                    failedCount += 1
                }
            }

            print("📥 导入完成: 成功 \(successCount), 失败 \(failedCount)")
            return (successCount, failedCount)

        } catch {
            print("❌ 导入重映射规则失败: \(error.localizedDescription)")
            return (0, 0)
        }
    }

    // MARK: - Private Methods

    /// 保存重映射规则到 UserDefaults
    private func saveRemappings() {
        let rules = engine.getAllRules()

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(rules)
            defaults.set(data, forKey: rulesKey)
            print("💾 保存了 \(rules.count) 条重映射规则")
        } catch {
            print("❌ 保存重映射规则失败: \(error.localizedDescription)")
        }
    }

    /// 从 UserDefaults 加载重映射规则
    private func loadRemappings() {
        guard let data = defaults.data(forKey: rulesKey) else {
            print("ℹ️ 未找到已保存的重映射规则")
            return
        }

        do {
            let decoder = JSONDecoder()
            let rules = try decoder.decode([RemappingRule].self, from: data)

            for rule in rules {
                _ = engine.addRemapping(from: rule.fromKey, to: rule.toKey, in: rule.bundleId)
            }

            print("📦 加载了 \(rules.count) 条重映射规则")
        } catch {
            print("❌ 加载重映射规则失败: \(error.localizedDescription)")
        }
    }

    /// 检查快捷键格式是否有效
    /// - Parameter key: 快捷键字符串
    /// - Returns: 是否有效
    private func isValidKeyFormat(_ key: String) -> Bool {
        // 快捷键应该包含至少一个修饰键和一个字符
        let validModifiers = ["⌃", "⌥", "⇧", "⌘"]
        let hasModifier = validModifiers.contains { key.contains($0) }

        // 移除修饰键后应该还有字符
        var remainingKey = key
        for modifier in validModifiers {
            remainingKey = remainingKey.replacingOccurrences(of: modifier, with: "")
        }

        return hasModifier && !remainingKey.isEmpty
    }

    /// 解析快捷键到 KeyCombination
    /// - Parameter keyString: 快捷键字符串
    /// - Returns: KeyCombination 或 nil
    func parseKeyCombination(_ keyString: String) -> KeyCombination? {
        return engine.parseKeyCombination(keyString)
    }
}
