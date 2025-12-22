//
//  AppShortcutExtractor.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation
import AppKit
import ApplicationServices

/// 应用快捷键提取器 - 从应用菜单中提取快捷键信息
class AppShortcutExtractor {

    // MARK: - Properties

    private let parser = MenuItemParser()
    private let timeout: TimeInterval = 5.0  // 5秒超时

    // MARK: - Public Methods

    /// 提取指定应用的所有快捷键
    /// - Parameter app: 要提取快捷键的应用
    /// - Returns: 快捷键信息数组
    func extractShortcuts(from app: NSRunningApplication) async -> [ShortcutInfo] {
        guard let bundleId = app.bundleIdentifier else {
            print("⚠️ 应用没有Bundle ID: \(app.localizedName ?? "Unknown")")
            return []
        }

        // 跳过Keymap自己的快捷键提取（避免NSMenu错误）
        if bundleId.contains("Keymap") || bundleId.contains("com.yourcompany") {
            print("ℹ️ 跳过Keymap自身的快捷键提取")
            return []
        }

        print("🔍 开始提取快捷键: \(app.localizedName ?? bundleId)")

        return await withTaskGroup(of: [ShortcutInfo].self) { group in
            // 使用TaskGroup实现超时机制
            group.addTask {
                return await self.performExtraction(from: app, bundleId: bundleId)
            }

            // 添加超时任务
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(self.timeout * 1_000_000_000))
                return []  // 超时返回空数组
            }

            // 返回第一个完成的结果
            if let firstResult = await group.next() {
                group.cancelAll()  // 取消其他任务
                return firstResult
            }

            return []
        }
    }

    // MARK: - Private Methods

    /// 执行实际的提取操作
    private func performExtraction(from app: NSRunningApplication, bundleId: String) async -> [ShortcutInfo] {
        // 创建应用的Accessibility元素
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        // 获取菜单栏
        guard let menuBar = getMenuBar(from: appElement) else {
            print("⚠️ 无法获取应用菜单栏: \(bundleId)")
            print("   请确保已授予辅助功能权限")
            return []
        }

        print("✅ 成功获取菜单栏: \(bundleId)")

        // 提取菜单项
        let menuItems = extractMenuItems(from: menuBar)
        print("✅ 提取到 \(menuItems.count) 个菜单项")

        // 调试：显示前5个菜单项
        if menuItems.isEmpty {
            print("⚠️ 未提取到任何菜单项,可能原因:")
            print("   1. 应用没有快捷键")
            print("   2. 菜单结构不标准")
            print("   3. 辅助功能权限问题")
        } else {
            print("📋 前5个菜单项:")
            for (i, item) in menuItems.prefix(5).enumerated() {
                print("   \(i+1). \(item.title) -> \(item.shortcut?.displayString ?? "无快捷键")")
            }
        }

        // 解析为ShortcutInfo
        var shortcuts: [ShortcutInfo] = []
        for (index, menuItem) in menuItems.enumerated() {
            if let shortcut = parseShortcutInfo(from: menuItem, app: bundleId, index: index) {
                shortcuts.append(shortcut)
            }
        }

        // ✅ 新增：去重步骤
        let deduplicatedShortcuts = deduplicateShortcuts(shortcuts)

        print("📊 去重统计: \(shortcuts.count) → \(deduplicatedShortcuts.count) (移除 \(shortcuts.count - deduplicatedShortcuts.count) 个重复项)")
        print("✅ 成功解析 \(deduplicatedShortcuts.count) 个快捷键")

        return deduplicatedShortcuts
    }

    /// 获取应用的菜单栏
    private func getMenuBar(from appElement: AXUIElement) -> AXUIElement? {
        var menuBar: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXMenuBarAttribute as CFString,
            &menuBar
        )

        guard result == .success, let menuBar = menuBar else {
            return nil
        }

        return (menuBar as! AXUIElement)
    }

    /// 判断是否为叶子菜单项（实际包含快捷键的项）
    private func isLeafMenuItem(_ element: AXUIElement) -> Bool {
        // 检查是否有快捷键字符（叶子节点的特征）
        var cmdChar: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXMenuItemCmdCharAttribute as CFString,
            &cmdChar
        )

        // 有快捷键字符 = 叶子节点
        return result == .success && (cmdChar as? String)?.isEmpty == false
    }

    /// 递归提取菜单项
    private func extractMenuItems(from element: AXUIElement) -> [MenuItem] {
        var items: [MenuItem] = []

        // 获取子元素
        var children: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &children
        )

        guard result == .success,
              let childrenArray = children as? [AXUIElement] else {
            return items
        }

        // 遍历子元素
        for child in childrenArray {
            // ✅ 只解析叶子节点
            if isLeafMenuItem(child) {
                if let menuItem = parser.parseMenuItem(child) {
                    items.append(menuItem)
                }
            }

            // ✅ 无论如何都递归（遍历整棵树）
            let subItems = extractMenuItems(from: child)
            items.append(contentsOf: subItems)
        }

        return items
    }

    /// 去重快捷键（同一应用的相同快捷键组合只保留一个）
    private func deduplicateShortcuts(_ shortcuts: [ShortcutInfo]) -> [ShortcutInfo] {
        // 按 keyCombination 分组
        var groupedByKey: [String: [ShortcutInfo]] = [:]

        for shortcut in shortcuts {
            if groupedByKey[shortcut.keyCombination] == nil {
                groupedByKey[shortcut.keyCombination] = []
            }
            groupedByKey[shortcut.keyCombination]?.append(shortcut)
        }

        // 对每组选择最佳的一个
        var result: [ShortcutInfo] = []

        for (key, group) in groupedByKey {
            if group.count == 1 {
                result.append(group[0])
            } else {
                let best = selectBestShortcut(from: group)
                result.append(best)

                // 调试日志
                let titles = group.map { $0.description }.joined(separator: ", ")
                print("🔄 去重: \(key) 有 \(group.count) 个: [\(titles)] → 保留: \(best.description)")
            }
        }

        return result
    }

    /// 从重复的快捷键中选择最佳的一个（英文优先）
    private func selectBestShortcut(from shortcuts: [ShortcutInfo]) -> ShortcutInfo {
        let sorted = shortcuts.sorted { shortcut1, shortcut2 in
            let desc1 = shortcut1.description
            let desc2 = shortcut2.description

            // 策略：英文优先（ASCII 字符占比高）
            let ascii1 = desc1.filter { $0.isASCII }.count
            let ascii2 = desc2.filter { $0.isASCII }.count
            let ratio1 = Double(ascii1) / Double(max(desc1.count, 1))
            let ratio2 = Double(ascii2) / Double(max(desc2.count, 1))

            // ASCII 占比差异明显时，优先选择英文
            if abs(ratio1 - ratio2) > 0.5 {
                return ratio1 > ratio2
            }

            // 否则选择较短的标题
            if desc1.count != desc2.count {
                return desc1.count < desc2.count
            }

            // 最后按字母顺序（稳定性）
            return desc1 < desc2
        }

        return sorted.first ?? shortcuts[0]
    }

    /// 将MenuItem解析为ShortcutInfo
    private func parseShortcutInfo(from menuItem: MenuItem, app: String, index: Int) -> ShortcutInfo? {
        // 如果没有快捷键，跳过
        guard let keyCombo = menuItem.shortcut else {
            return nil
        }

        // 生成唯一ID
        let id = "\(app)_\(index)_\(keyCombo.displayString)"

        // 确定分类
        let category = determineCategory(from: menuItem.title)

        return ShortcutInfo(
            id: id,
            keyCombination: keyCombo.displayString,
            description: menuItem.title,
            application: app,
            category: category,
            isCustom: false,
            conflicts: []  // 初始时没有冲突
        )
    }

    /// 根据标题确定快捷键分类
    private func determineCategory(from title: String) -> ShortcutCategory {
        let lowerTitle = title.lowercased()

        // 文件操作
        if lowerTitle.contains("new") || lowerTitle.contains("open") ||
           lowerTitle.contains("save") || lowerTitle.contains("close") ||
           lowerTitle.contains("print") || lowerTitle.contains("export") {
            return .file
        }

        // 编辑操作
        if lowerTitle.contains("undo") || lowerTitle.contains("redo") ||
           lowerTitle.contains("cut") || lowerTitle.contains("copy") ||
           lowerTitle.contains("paste") || lowerTitle.contains("delete") ||
           lowerTitle.contains("select") || lowerTitle.contains("find") {
            return .edit
        }

        // 视图操作
        if lowerTitle.contains("zoom") || lowerTitle.contains("view") ||
           lowerTitle.contains("show") || lowerTitle.contains("hide") ||
           lowerTitle.contains("full screen") {
            return .view
        }

        // 窗口操作
        if lowerTitle.contains("window") || lowerTitle.contains("minimize") ||
           lowerTitle.contains("maximize") {
            return .window
        }

        // 导航操作
        if lowerTitle.contains("next") || lowerTitle.contains("previous") ||
           lowerTitle.contains("go to") || lowerTitle.contains("back") ||
           lowerTitle.contains("forward") {
            return .navigation
        }

        return .other
    }
}

// MARK: - MenuItem Structure

/// 菜单项数据结构
struct MenuItem {
    let title: String
    let shortcut: KeyCombination?
    let isEnabled: Bool
    let hasSubmenu: Bool
}
