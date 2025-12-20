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
            return []
        }

        // 提取菜单项
        let menuItems = extractMenuItems(from: menuBar)
        print("✅ 提取到 \(menuItems.count) 个菜单项")

        // 解析为ShortcutInfo
        var shortcuts: [ShortcutInfo] = []
        for (index, menuItem) in menuItems.enumerated() {
            if let shortcut = parseShortcutInfo(from: menuItem, app: bundleId, index: index) {
                shortcuts.append(shortcut)
            }
        }

        print("✅ 成功解析 \(shortcuts.count) 个快捷键")
        return shortcuts
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
            // 尝试解析当前元素
            if let menuItem = parser.parseMenuItem(child) {
                items.append(menuItem)
            }

            // 递归提取子菜单
            let subItems = extractMenuItems(from: child)
            items.append(contentsOf: subItems)
        }

        return items
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
