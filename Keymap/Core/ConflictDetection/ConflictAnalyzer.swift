//
//  ConflictAnalyzer.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

/// 冲突分析器 - 深度分析冲突并生成详细建议
class ConflictAnalyzer {

    // MARK: - Properties

    private let systemProvider = SystemShortcutProvider.shared

    // MARK: - Public Methods

    /// 深度分析冲突严重程度
    /// - Parameter conflict: 冲突信息
    /// - Returns: 更新后的严重程度
    func analyzeSeverity(_ conflict: ConflictInfo) -> ConflictSeverity {
        // 基于冲突类型和涉及的应用进行深度分析
        switch conflict.conflictType {
        case .system:
            // 系统级冲突始终为高严重程度
            return .high

        case .global:
            // 分析涉及的应用数量
            if let apps = conflict.conflictingApp {
                let appCount = apps.components(separatedBy: ", ").count
                if appCount >= 3 {
                    return .high
                } else if appCount == 2 {
                    return .medium
                }
            }
            return .low

        case .application:
            // 应用内冲突为中等严重程度
            return .medium

        case .functional:
            // 功能冲突为低严重程度
            return .low
        }
    }

    /// 生成详细的解决建议
    /// - Parameters:
    ///   - conflict: 冲突信息
    ///   - shortcuts: 所有快捷键列表
    /// - Returns: 建议列表
    func generateDetailedSuggestions(
        for conflict: ConflictInfo,
        shortcuts: [ShortcutInfo]
    ) -> [String] {
        var suggestions: [String] = []

        // 找到冲突的快捷键
        guard let shortcut = shortcuts.first(where: { $0.id == conflict.shortcutId }) else {
            return ["无法找到冲突的快捷键信息"]
        }

        // 根据冲突类型生成建议
        switch conflict.conflictType {
        case .system:
            suggestions = generateSystemConflictSuggestions(shortcut)

        case .global:
            suggestions = generateGlobalConflictSuggestions(shortcut, conflict)

        case .application:
            suggestions = generateApplicationConflictSuggestions(shortcut)

        case .functional:
            suggestions = generateFunctionalConflictSuggestions(shortcut)
        }

        // 添加替代快捷键建议
        let alternatives = findAlternativeShortcuts(shortcut, existingShortcuts: shortcuts)
        if !alternatives.isEmpty {
            suggestions.append("建议使用替代快捷键：")
            suggestions.append(contentsOf: alternatives.map { "  - \($0)" })
        }

        return suggestions
    }

    /// 寻找替代快捷键
    /// - Parameters:
    ///   - shortcut: 当前快捷键
    ///   - existingShortcuts: 已存在的快捷键列表
    /// - Returns: 替代快捷键字符串数组
    func findAlternativeShortcuts(
        _ shortcut: ShortcutInfo,
        existingShortcuts: [ShortcutInfo]
    ) -> [String] {
        var alternatives: [String] = []

        // 获取已使用的快捷键组合
        let usedCombinations = Set(existingShortcuts.map { $0.keyCombination })

        // 当前快捷键的字符
        let currentKey = extractKey(from: shortcut.keyCombination)

        // 策略1: 添加不同的修饰键
        let modifierVariations = generateModifierVariations(key: currentKey)
        for variation in modifierVariations {
            if !usedCombinations.contains(variation) {
                alternatives.append(variation)
                if alternatives.count >= 3 { break }
            }
        }

        // 策略2: 使用相邻的字母键
        if alternatives.count < 3 {
            let adjacentKeys = generateAdjacentKeys(from: currentKey)
            let currentModifiers = extractModifiers(from: shortcut.keyCombination)

            for adjacentKey in adjacentKeys {
                let combination = currentModifiers + adjacentKey
                if !usedCombinations.contains(combination) {
                    alternatives.append(combination)
                    if alternatives.count >= 3 { break }
                }
            }
        }

        return Array(alternatives.prefix(5))  // 最多返回5个建议
    }

    /// 分析冲突影响范围
    /// - Parameter conflict: 冲突信息
    /// - Returns: 影响描述
    func analyzeImpact(_ conflict: ConflictInfo) -> String {
        switch conflict.severity {
        case .high:
            return "严重影响：此冲突可能导致快捷键完全无法使用"

        case .medium:
            return "中等影响：此冲突可能在特定场景下导致快捷键失效"

        case .low:
            return "轻微影响：此冲突通常不会造成实际问题"
        }
    }

    // MARK: - Private Methods

    /// 生成系统级冲突建议
    private func generateSystemConflictSuggestions(_ shortcut: ShortcutInfo) -> [String] {
        return [
            "⚠️ 此快捷键与系统快捷键冲突",
            "系统快捷键具有最高优先级，应用快捷键可能被覆盖",
            "建议：",
            "  1. 在应用中修改此快捷键",
            "  2. 在系统设置中禁用对应的系统快捷键",
            "  3. 使用不同的修饰键组合（如添加⌥或⌃）"
        ]
    }

    /// 生成全局冲突建议
    private func generateGlobalConflictSuggestions(
        _ shortcut: ShortcutInfo,
        _ conflict: ConflictInfo
    ) -> [String] {
        var suggestions = [
            "⚠️ 多个应用使用相同的快捷键 \(shortcut.keyCombination)",
            "冲突应用：\(conflict.conflictingApp ?? "未知")",
            "建议："
        ]

        if let apps = conflict.conflictingApp {
            let appList = apps.components(separatedBy: ", ")
            for app in appList {
                suggestions.append("  - 在 \(app) 中禁用或修改此快捷键")
            }
        }

        suggestions.append("  - 使用应用特定的快捷键配置")

        return suggestions
    }

    /// 生成应用级冲突建议
    private func generateApplicationConflictSuggestions(_ shortcut: ShortcutInfo) -> [String] {
        return [
            "⚠️ 应用内有重复的快捷键定义",
            "这可能是应用的配置问题",
            "建议：",
            "  1. 检查 \(shortcut.application) 的快捷键设置",
            "  2. 重置应用的快捷键配置",
            "  3. 联系应用开发者报告此问题"
        ]
    }

    /// 生成功能冲突建议
    private func generateFunctionalConflictSuggestions(_ shortcut: ShortcutInfo) -> [String] {
        return [
            "ℹ️ 检测到功能相似的快捷键",
            "这可能导致使用混淆",
            "建议：",
            "  1. 统一相似功能的快捷键",
            "  2. 保留最常用的快捷键",
            "  3. 在应用设置中调整快捷键映射"
        ]
    }

    /// 从快捷键字符串中提取按键字符
    private func extractKey(from combination: String) -> String {
        // 移除修饰键符号
        var key = combination
        key = key.replacingOccurrences(of: "⌘", with: "")
        key = key.replacingOccurrences(of: "⇧", with: "")
        key = key.replacingOccurrences(of: "⌥", with: "")
        key = key.replacingOccurrences(of: "⌃", with: "")
        return key.trimmingCharacters(in: .whitespaces)
    }

    /// 从快捷键字符串中提取修饰键
    private func extractModifiers(from combination: String) -> String {
        var modifiers = ""
        if combination.contains("⌃") { modifiers += "⌃" }
        if combination.contains("⌥") { modifiers += "⌥" }
        if combination.contains("⇧") { modifiers += "⇧" }
        if combination.contains("⌘") { modifiers += "⌘" }
        return modifiers
    }

    /// 生成不同修饰键组合
    private func generateModifierVariations(key: String) -> [String] {
        return [
            "⌘\(key)",           // Command only
            "⇧⌘\(key)",          // Shift + Command
            "⌥⌘\(key)",          // Option + Command
            "⌃⌘\(key)",          // Control + Command
            "⇧⌥⌘\(key)",         // Shift + Option + Command
            "⌃⌥⌘\(key)"          // Control + Option + Command
        ]
    }

    /// 生成相邻按键
    private func generateAdjacentKeys(from key: String) -> [String] {
        // QWERTY键盘布局的相邻键
        let adjacencyMap: [String: [String]] = [
            "A": ["S", "Q", "W", "Z"],
            "B": ["V", "G", "H", "N"],
            "C": ["X", "D", "F", "V"],
            "D": ["S", "E", "R", "F", "C", "X"],
            "E": ["W", "R", "D", "S"],
            "F": ["D", "R", "T", "G", "V", "C"],
            "G": ["F", "T", "Y", "H", "B", "V"],
            "H": ["G", "Y", "U", "J", "N", "B"],
            "I": ["U", "O", "K", "J"],
            "J": ["H", "U", "I", "K", "M", "N"],
            "K": ["J", "I", "O", "L", "M"],
            "L": ["K", "O", "P"],
            "M": ["N", "J", "K"],
            "N": ["B", "H", "J", "M"],
            "O": ["I", "P", "L", "K"],
            "P": ["O", "L"],
            "Q": ["W", "A", "S"],
            "R": ["E", "T", "F", "D"],
            "S": ["A", "W", "E", "D", "X", "Z"],
            "T": ["R", "Y", "G", "F"],
            "U": ["Y", "I", "J", "H"],
            "V": ["C", "F", "G", "B"],
            "W": ["Q", "E", "S", "A"],
            "X": ["Z", "S", "D", "C"],
            "Y": ["T", "U", "H", "G"],
            "Z": ["A", "S", "X"]
        ]

        return adjacencyMap[key.uppercased()] ?? []
    }
}
