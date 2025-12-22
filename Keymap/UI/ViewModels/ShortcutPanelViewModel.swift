//
//  ShortcutPanelViewModel.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation
import Combine
import AppKit

class ShortcutPanelViewModel: ObservableObject {
    @Published var shortcuts: [ShortcutInfo] = []
    @Published var searchText: String = ""
    @Published var currentApp: String = ""
    @Published var currentAppIcon: NSImage? = nil
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let extractor = AppShortcutExtractor()
    private let cache = ShortcutCache()
    private let systemProvider = SystemShortcutProvider.shared
    private let keymapProvider = KeymapShortcutProvider.shared

    // MARK: - 修饰键名称映射

    /// 修饰键英文名称到符号的映射表
    private let modifierKeyMap: [String: String] = [
        "command": "⌘",
        "cmd": "⌘",
        "shift": "⇧",
        "option": "⌥",
        "opt": "⌥",
        "alt": "⌥",
        "control": "⌃",
        "ctrl": "⌃",
        "fn": "fn",
        "return": "↩",
        "enter": "↩",
        "tab": "⇥",
        "space": "Space",
        "delete": "⌫",
        "backspace": "⌫",
        "escape": "⎋",
        "esc": "⎋",
        "up": "↑",
        "down": "↓",
        "left": "←",
        "right": "→"
    ]

    /// 标准化搜索文本（将英文修饰键名转换为符号）
    private func normalizeSearchText(_ text: String) -> String {
        var normalized = text.lowercased()

        // 替换所有修饰键名称为符号
        for (englishName, symbol) in modifierKeyMap {
            normalized = normalized.replacingOccurrences(of: englishName, with: symbol, options: .caseInsensitive)
        }

        return normalized
    }

    var filteredShortcuts: [ShortcutInfo] {
        if searchText.isEmpty {
            return shortcuts
        }

        // ✅ 标准化搜索文本（支持英文修饰键名）
        let normalizedSearchText = normalizeSearchText(searchText)

        return shortcuts.filter { shortcut in
            // 支持原始搜索文本和标准化后的文本
            shortcut.keyCombination.localizedCaseInsensitiveContains(searchText) ||
            shortcut.keyCombination.localizedCaseInsensitiveContains(normalizedSearchText) ||
            shortcut.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var conflictShortcuts: [ShortcutInfo] {
        filteredShortcuts.filter { !$0.conflicts.isEmpty }
    }

    var normalShortcuts: [ShortcutInfo] {
        filteredShortcuts.filter { $0.conflicts.isEmpty }
    }

    // MARK: - 数据加载

    func loadCurrentAppShortcuts() {
        isLoading = true

        // 获取当前前端应用
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            currentApp = frontApp.localizedName ?? "Unknown"
            currentAppIcon = frontApp.icon
            loadShortcuts(for: frontApp)
        } else {
            currentApp = "未知应用"
            currentAppIcon = nil
            loadDemoShortcuts()
        }
    }

    private func loadShortcuts(for app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier else {
            print("⚠️ 应用没有Bundle ID")
            loadDemoShortcuts()
            return
        }

        Task { @MainActor in
            isLoading = true

            // ✅ 检查是否是Keymap自身
            if bundleId.contains("Keymap") || bundleId.contains("com.yourcompany") {
                print("ℹ️ 检测到Keymap应用，使用硬编码快捷键")
                self.shortcuts = keymapProvider.getKeymapShortcuts()
                isLoading = false
                return
            }

            // 1. 尝试从缓存获取
            if let cached = cache.getCachedShortcuts(for: bundleId) {
                print("📦 从缓存加载快捷键: \(bundleId)")
                self.shortcuts = mergeWithSystemShortcuts(cached)
                isLoading = false
                return
            }

            // 2. 提取快捷键
            print("🔍 开始提取快捷键: \(bundleId)")
            let extracted = await extractor.extractShortcuts(from: app)

            if extracted.isEmpty {
                print("⚠️ 未提取到快捷键，使用演示数据")
                loadDemoShortcuts()
                return
            }

            // 3. 缓存结果
            cache.cacheShortcuts(extracted, for: bundleId)

            // 4. 合并系统快捷键
            self.shortcuts = mergeWithSystemShortcuts(extracted)
            isLoading = false

            print("✅ 加载完成: \(self.shortcuts.count) 个快捷键")
        }
    }

    /// 合并应用快捷键和系统快捷键（带去重）
    private func mergeWithSystemShortcuts(_ appShortcuts: [ShortcutInfo]) -> [ShortcutInfo] {
        let systemShortcuts = systemProvider.getSystemShortcuts()

        // ✅ 去重：按 keyCombination 分组，应用快捷键优先
        var uniqueShortcuts: [String: ShortcutInfo] = [:]

        // 先添加应用快捷键（优先级更高）
        for shortcut in appShortcuts {
            uniqueShortcuts[shortcut.keyCombination] = shortcut
        }

        // 再添加系统快捷键（只添加不重复的）
        for shortcut in systemShortcuts {
            if uniqueShortcuts[shortcut.keyCombination] == nil {
                uniqueShortcuts[shortcut.keyCombination] = shortcut
            }
        }

        return Array(uniqueShortcuts.values)
    }

    private func loadDemoShortcuts() {
        // 演示数据 - 仅包含标准快捷键
        shortcuts = [
            ShortcutInfo(
                keyCombination: "⌘C",
                description: "复制",
                application: currentApp,
                category: .edit
            ),
            ShortcutInfo(
                keyCombination: "⌘V",
                description: "粘贴",
                application: currentApp,
                category: .edit
            ),
            ShortcutInfo(
                keyCombination: "⌘Z",
                description: "撤销",
                application: currentApp,
                category: .edit
            ),
            ShortcutInfo(
                keyCombination: "⌘S",
                description: "保存",
                application: currentApp,
                category: .file
            ),
            ShortcutInfo(
                keyCombination: "⌘N",
                description: "新建",
                application: currentApp,
                category: .file
            ),
            ShortcutInfo(
                keyCombination: "⌘W",
                description: "关闭窗口",
                application: currentApp,
                category: .window
            ),
            ShortcutInfo(
                keyCombination: "⌘Q",
                description: "退出应用",
                application: currentApp,
                category: .system
            ),
        ]

        isLoading = false
    }
}
