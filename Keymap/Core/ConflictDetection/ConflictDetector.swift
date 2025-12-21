//
//  ConflictDetector.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

/// 冲突检测引擎 - 检测快捷键冲突并生成冲突信息
class ConflictDetector {

    // MARK: - Properties

    private let systemProvider = SystemShortcutProvider.shared

    // MARK: - Public Methods

    /// 检测快捷键冲突
    /// - Parameter shortcuts: 要检测的快捷键列表
    /// - Returns: 冲突信息数组
    func detectConflicts(shortcuts: [ShortcutInfo]) -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []

        // 1. 构建快捷键索引（按 keyCombination 分组）
        let index = buildShortcutIndex(shortcuts)

        // 2. 检测重复快捷键（同一组合被多个应用使用）
        let duplicateConflicts = detectDuplicates(index)
        conflicts.append(contentsOf: duplicateConflicts)

        // 3. 检测与系统快捷键的冲突
        let systemConflicts = detectSystemConflicts(shortcuts)
        conflicts.append(contentsOf: systemConflicts)

        // 4. 检测功能冲突（可选，未来实现）
        // let functionalConflicts = detectFunctionalConflicts(shortcuts)
        // conflicts.append(contentsOf: functionalConflicts)

        print("🔍 检测到 \(conflicts.count) 个冲突")

        return conflicts
    }

    /// 检测实时冲突（单个快捷键）
    /// - Parameters:
    ///   - keyCombination: 快捷键组合
    ///   - currentApp: 当前应用
    ///   - allShortcuts: 所有已知快捷键
    /// - Returns: 冲突信息数组
    func detectRealTimeConflict(
        _ keyCombination: String,
        in currentApp: String,
        allShortcuts: [ShortcutInfo]
    ) -> [ConflictInfo] {
        // 过滤匹配的快捷键
        let matchingShortcuts = allShortcuts.filter { $0.keyCombination == keyCombination }

        guard matchingShortcuts.count > 1 else {
            return []  // 无冲突
        }

        // 构建冲突信息
        var conflicts: [ConflictInfo] = []

        for shortcut in matchingShortcuts {
            // 检查是否为系统快捷键
            if shortcut.application == "System" {
                let conflict = ConflictInfo(
                    shortcutId: shortcut.id,
                    conflictType: .system,
                    conflictingApp: "系统",
                    severity: .high,
                    suggestions: [
                        "避免使用系统级快捷键",
                        "选择其他快捷键组合",
                        "在系统设置中禁用该系统快捷键"
                    ]
                )
                conflicts.append(conflict)
            }
            // 检查是否为其他应用的快捷键
            else if shortcut.application != currentApp {
                let conflict = ConflictInfo(
                    shortcutId: shortcut.id,
                    conflictType: .global,
                    conflictingApp: shortcut.application,
                    severity: .medium,
                    suggestions: [
                        "在 \(shortcut.application) 中禁用此快捷键",
                        "使用不同的快捷键组合",
                        "创建应用特定的快捷键映射"
                    ]
                )
                conflicts.append(conflict)
            }
        }

        return conflicts
    }

    // MARK: - Private Methods

    /// 构建快捷键索引
    /// - Parameter shortcuts: 快捷键列表
    /// - Returns: 按 keyCombination 分组的字典
    private func buildShortcutIndex(_ shortcuts: [ShortcutInfo]) -> [String: [ShortcutInfo]] {
        var index: [String: [ShortcutInfo]] = [:]

        for shortcut in shortcuts {
            let key = shortcut.keyCombination
            if index[key] == nil {
                index[key] = []
            }
            index[key]?.append(shortcut)
        }

        return index
    }

    /// 检测重复快捷键
    /// - Parameter index: 快捷键索引
    /// - Returns: 冲突信息数组
    private func detectDuplicates(_ index: [String: [ShortcutInfo]]) -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []

        for (_, shortcuts) in index {
            guard shortcuts.count > 1 else { continue }

            // 分析冲突的应用
            let apps = shortcuts.map { $0.application }
            let uniqueApps = Set(apps)

            // 如果同一快捷键被多个不同应用使用，创建冲突记录
            if uniqueApps.count > 1 {
                for shortcut in shortcuts {
                    let otherApps = uniqueApps.filter { $0 != shortcut.application }
                    let severity = calculateSeverity(.global, apps: Array(uniqueApps))

                    let conflict = ConflictInfo(
                        shortcutId: shortcut.id,
                        conflictType: .global,
                        conflictingApp: otherApps.joined(separator: ", "),
                        severity: severity,
                        suggestions: generateSuggestions(
                            for: shortcut,
                            conflictingWith: Array(otherApps)
                        )
                    )
                    conflicts.append(conflict)
                }
            }
            // 如果同一应用内有重复，创建应用级冲突
            else if shortcuts.count > 1 {
                for shortcut in shortcuts {
                    let conflict = ConflictInfo(
                        shortcutId: shortcut.id,
                        conflictType: .application,
                        conflictingApp: shortcut.application,
                        severity: .medium,
                        suggestions: [
                            "应用内有重复的快捷键定义",
                            "检查应用菜单设置",
                            "联系应用开发者修复"
                        ]
                    )
                    conflicts.append(conflict)
                }
            }
        }

        return conflicts
    }

    /// 检测与系统快捷键的冲突
    /// - Parameter shortcuts: 快捷键列表
    /// - Returns: 冲突信息数组
    private func detectSystemConflicts(_ shortcuts: [ShortcutInfo]) -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []

        // 获取系统快捷键列表
        let systemShortcuts = systemProvider.getSystemShortcuts()
        let systemKeys = Set(systemShortcuts.map { $0.keyCombination })

        // 检查每个快捷键是否与系统快捷键冲突
        for shortcut in shortcuts where shortcut.application != "System" {
            if systemKeys.contains(shortcut.keyCombination) {
                let conflict = ConflictInfo(
                    shortcutId: shortcut.id,
                    conflictType: .system,
                    conflictingApp: "系统",
                    severity: .high,
                    suggestions: [
                        "避免使用系统级快捷键",
                        "选择其他修饰键组合",
                        "在系统设置中禁用该系统快捷键"
                    ]
                )
                conflicts.append(conflict)
            }
        }

        return conflicts
    }

    /// 计算冲突严重程度
    /// - Parameters:
    ///   - conflictType: 冲突类型
    ///   - apps: 涉及的应用列表
    /// - Returns: 冲突严重程度
    private func calculateSeverity(_ conflictType: ConflictType, apps: [String]) -> ConflictSeverity {
        switch conflictType {
        case .system:
            return .high  // 系统级冲突总是高严重程度

        case .global:
            // 涉及3个或更多应用，严重程度高
            if apps.count >= 3 {
                return .high
            }
            // 涉及2个应用，严重程度中
            else if apps.count == 2 {
                return .medium
            }
            else {
                return .low
            }

        case .application:
            return .medium  // 应用级冲突为中等严重程度

        case .functional:
            return .low  // 功能冲突通常为低严重程度
        }
    }

    /// 生成冲突解决建议
    /// - Parameters:
    ///   - shortcut: 快捷键信息
    ///   - conflictingApps: 冲突的应用列表
    /// - Returns: 建议列表
    private func generateSuggestions(
        for shortcut: ShortcutInfo,
        conflictingWith conflictingApps: [String]
    ) -> [String] {
        var suggestions: [String] = []

        // 基础建议
        suggestions.append("当前快捷键 \(shortcut.keyCombination) 被多个应用使用")

        // 针对冲突应用的建议
        for app in conflictingApps {
            suggestions.append("在 \(app) 中禁用或修改此快捷键")
        }

        // 通用建议
        suggestions.append("选择不同的快捷键组合")
        suggestions.append("使用应用特定的快捷键配置文件")

        return suggestions
    }
}
