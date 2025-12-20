//
//  RemappingEngine.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation
import Carbon

/// 重映射规则
struct RemappingRule: Codable, Identifiable {
    var id: String { "\(bundleId):\(fromKey)" }
    let fromKey: String           // 原快捷键组合（如"⌘T"）
    let toKey: String             // 新快捷键组合（如"⇧⌘T"）
    let bundleId: String          // 应用Bundle ID
    let createdAt: Date           // 创建时间

    init(fromKey: String, toKey: String, bundleId: String) {
        self.fromKey = fromKey
        self.toKey = toKey
        self.bundleId = bundleId
        self.createdAt = Date()
    }
}

/// 快捷键重映射引擎
class RemappingEngine {

    // MARK: - Properties

    /// 重映射规则存储: [bundleId: [fromKey: toKey]]
    private var mappings: [String: [String: String]] = [:]

    /// 系统保留快捷键（不可重映射）
    private let systemReservedKeys: Set<String> = [
        "⌘Q",      // 退出应用
        "⌘⌥Esc",   // 强制退出
        "⌘Space",  // Spotlight
        "⌃⌘Q",     // 锁定屏幕
        "⌃⌘Power"  // 关机对话框
    ]

    // MARK: - Public Methods

    /// 添加重映射规则
    /// - Parameters:
    ///   - fromKey: 原快捷键组合
    ///   - toKey: 新快捷键组合
    ///   - bundleId: 应用Bundle ID
    /// - Returns: 是否成功
    func addRemapping(from fromKey: String, to toKey: String, in bundleId: String) -> Bool {
        // 验证规则
        guard validateRemapping(from: fromKey, to: toKey, in: bundleId) else {
            return false
        }

        // 初始化应用映射表
        if mappings[bundleId] == nil {
            mappings[bundleId] = [:]
        }

        // 添加映射
        mappings[bundleId]![fromKey] = toKey

        print("✅ 添加重映射: \(fromKey) → \(toKey) (\(bundleId))")
        return true
    }

    /// 移除重映射规则
    /// - Parameters:
    ///   - fromKey: 原快捷键组合
    ///   - bundleId: 应用Bundle ID
    func removeRemapping(from fromKey: String, in bundleId: String) {
        guard var appMappings = mappings[bundleId] else {
            return
        }

        if let removed = appMappings.removeValue(forKey: fromKey) {
            mappings[bundleId] = appMappings
            print("🗑 移除重映射: \(fromKey) → \(removed) (\(bundleId))")
        }

        // 清理空映射
        if appMappings.isEmpty {
            mappings.removeValue(forKey: bundleId)
        }
    }

    /// 获取重映射后的快捷键
    /// - Parameters:
    ///   - key: 原快捷键组合
    ///   - bundleId: 应用Bundle ID
    /// - Returns: 重映射后的快捷键，如果没有映射则返回nil
    func getRemappedKey(_ key: String, for bundleId: String) -> String? {
        return mappings[bundleId]?[key]
    }

    /// 清除指定应用的所有重映射
    /// - Parameter bundleId: 应用Bundle ID
    func clearRemappings(for bundleId: String) {
        if let count = mappings[bundleId]?.count {
            mappings.removeValue(forKey: bundleId)
            print("🗑 已清除 \(bundleId) 的 \(count) 条重映射规则")
        }
    }

    /// 清除所有重映射
    func clearAllRemappings() {
        let totalCount = mappings.values.reduce(0) { $0 + $1.count }
        mappings.removeAll()
        print("🗑 已清除所有 \(totalCount) 条重映射规则")
    }

    /// 获取所有重映射规则
    /// - Returns: 重映射规则数组
    func getAllRules() -> [RemappingRule] {
        var rules: [RemappingRule] = []

        for (bundleId, appMappings) in mappings {
            for (fromKey, toKey) in appMappings {
                rules.append(RemappingRule(
                    fromKey: fromKey,
                    toKey: toKey,
                    bundleId: bundleId
                ))
            }
        }

        return rules.sorted { $0.bundleId < $1.bundleId }
    }

    /// 获取指定应用的重映射规则
    /// - Parameter bundleId: 应用Bundle ID
    /// - Returns: 重映射规则数组
    func getRules(for bundleId: String) -> [RemappingRule] {
        guard let appMappings = mappings[bundleId] else {
            return []
        }

        return appMappings.map { fromKey, toKey in
            RemappingRule(fromKey: fromKey, toKey: toKey, bundleId: bundleId)
        }.sorted { $0.fromKey < $1.fromKey }
    }

    /// 获取重映射统计
    /// - Returns: (总规则数, 应用数)
    func getStatistics() -> (totalRules: Int, appCount: Int) {
        let totalRules = mappings.values.reduce(0) { $0 + $1.count }
        let appCount = mappings.count
        return (totalRules, appCount)
    }

    /// 检查快捷键是否已被重映射
    /// - Parameters:
    ///   - key: 快捷键组合
    ///   - bundleId: 应用Bundle ID
    /// - Returns: 是否已被重映射
    func isRemapped(_ key: String, in bundleId: String) -> Bool {
        return mappings[bundleId]?[key] != nil
    }

    // MARK: - Private Methods

    /// 验证重映射规则的有效性
    /// - Parameters:
    ///   - fromKey: 原快捷键组合
    ///   - toKey: 新快捷键组合
    ///   - bundleId: 应用Bundle ID
    /// - Returns: 是否有效
    private func validateRemapping(from fromKey: String, to toKey: String, in bundleId: String) -> Bool {
        // 1. 不能映射到相同的键
        if fromKey == toKey {
            print("❌ 重映射失败: 源键和目标键相同")
            return false
        }

        // 2. 不能映射系统保留快捷键
        if systemReservedKeys.contains(toKey) {
            print("❌ 重映射失败: \(toKey) 是系统保留快捷键")
            return false
        }

        // 3. 不能创建循环映射 (A→B, B→A)
        if let existingMapping = mappings[bundleId]?[toKey],
           existingMapping == fromKey {
            print("❌ 重映射失败: 检测到循环映射 \(fromKey)↔\(toKey)")
            return false
        }

        // 4. 不能创建链式映射 (A→B→C)
        if let existingMapping = mappings[bundleId]?[toKey] {
            print("❌ 重映射失败: \(toKey) 已被映射到 \(existingMapping)，不支持链式映射")
            return false
        }

        return true
    }

    /// 解析快捷键字符串为 KeyCombination 结构
    /// - Parameter keyString: 快捷键字符串（如"⌘T"）
    /// - Returns: KeyCombination 或 nil
    func parseKeyCombination(_ keyString: String) -> KeyCombination? {
        var modifiers: CGEventFlags = []
        var keyChar = ""

        // 解析修饰键
        for char in keyString {
            switch char {
            case "⌃":
                modifiers.insert(.maskControl)
            case "⌥":
                modifiers.insert(.maskAlternate)
            case "⇧":
                modifiers.insert(.maskShift)
            case "⌘":
                modifiers.insert(.maskCommand)
            default:
                keyChar.append(char)
            }
        }

        // 转换字符到键码
        guard let keyCode = charToKeyCode(keyChar.uppercased()) else {
            return nil
        }

        return KeyCombination(keyCode: Int(keyCode), modifiers: modifiers)
    }

    /// 字符到键码的映射
    /// - Parameter char: 字符
    /// - Returns: 键码或nil
    private func charToKeyCode(_ char: String) -> CGKeyCode? {
        let mapping: [String: CGKeyCode] = [
            "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3,
            "G": 5, "H": 4, "I": 34, "J": 38, "K": 40, "L": 37,
            "M": 46, "N": 45, "O": 31, "P": 35, "Q": 12, "R": 15,
            "S": 1, "T": 17, "U": 32, "V": 9, "W": 13, "X": 7,
            "Y": 16, "Z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21,
            "5": 23, "6": 22, "7": 26, "8": 28, "9": 25,
            " ": 49,      // Space
            "↵": 36,      // Return
            "⌫": 51,      // Delete
            "⎋": 53,      // Escape
            "⇥": 48       // Tab
        ]

        return mapping[char]
    }
}
