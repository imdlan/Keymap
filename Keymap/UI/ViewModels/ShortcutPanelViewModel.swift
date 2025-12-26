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
    
    // ✅ 保存当前显示的应用（用于刷新时重新加载同一个应用的快捷键）
    private var currentRunningApp: NSRunningApplication?

    // MARK: - Dependencies

    private let extractor = AppShortcutExtractor()
    private let cache = ShortcutCache()
    private let systemProvider = SystemShortcutProvider.shared
    private let keymapProvider = KeymapShortcutProvider.shared
    private let conflictDetector = ConflictDetector()

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

    func loadCurrentAppShortcuts(targetApp: NSRunningApplication? = nil) {
        isLoading = true

        // ✅ 优先级：1. 传入的目标应用  2. 保存的当前应用  3. 前台应用
        let frontApp = targetApp ?? currentRunningApp ?? NSWorkspace.shared.frontmostApplication
        
        // 获取当前前端应用
        if let app = frontApp {
            // ✅ 保存当前应用（用于后续刷新）
            currentRunningApp = app
            
            currentApp = app.localizedName ?? "Unknown"
            currentAppIcon = app.icon
            print("🎯 准备加载应用快捷键: \(currentApp) (\(app.bundleIdentifier ?? "无Bundle ID"))")
            loadShortcuts(for: app)
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

        // ✅ 立即在主线程设置加载状态
        isLoading = true

        // ✅ 使用 Task.detached 在后台线程执行数据加载
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            // ✅ 检查是否是Keymap自身
            if bundleId.contains("Keymap") || bundleId.contains("com.yourcompany") {
                print("ℹ️ 检测到Keymap应用，使用硬编码快捷键")
                await MainActor.run {
                    self.shortcuts = self.keymapProvider.getKeymapShortcuts()
                    self.isLoading = false
                }
                return
            }

            // 1. 尝试从缓存获取
            if let cached = self.cache.getCachedShortcuts(for: bundleId) {
                print("📦 从缓存加载快捷键: \(bundleId)")
                await MainActor.run {
                    self.shortcuts = self.mergeWithSystemShortcuts(cached)
                    self.isLoading = false
                }
                return
            }

            // 2. 提取快捷键（在后台线程）
            print("🔍 开始提取快捷键: \(bundleId)")
            let extracted = await self.extractor.extractShortcuts(from: app)

            if extracted.isEmpty {
                print("⚠️ 未提取到快捷键，使用演示数据")
                await MainActor.run {
                    self.loadDemoShortcuts()
                }
                return
            }

            // 3. 缓存结果
            self.cache.cacheShortcuts(extracted, for: bundleId)

            // 4. 合并系统快捷键并在主线程更新UI
            await MainActor.run {
                self.shortcuts = self.mergeWithSystemShortcuts(extracted)
                self.isLoading = false
                print("✅ 加载完成: \(self.shortcuts.count) 个快捷键")
            }
        }
    }

    /// 加载指定应用的快捷键（通过 bundleId 和 appName）
    func loadShortcuts(for bundleId: String, appName: String) {
        print("📱 准备加载应用快捷键: \(appName) (\(bundleId))")
        
        // 设置当前应用信息
        currentApp = appName
        
        // 查找运行中的应用
        let runningApps = NSWorkspace.shared.runningApplications
        if let app = runningApps.first(where: { $0.bundleIdentifier == bundleId }) {
            currentAppIcon = app.icon
            currentRunningApp = app
            loadShortcuts(for: app)
        } else {
            print("⚠️ 应用未在运行中: \(bundleId)")
            // 应用未运行，从缓存加载或显示空
            isLoading = true
            
            Task.detached { [weak self] in
                guard let self = self else { return }
                
                // 尝试从缓存获取
                if let cached = self.cache.getCachedShortcuts(for: bundleId) {
                    print("📦 从缓存加载快捷键: \(bundleId)")
                    await MainActor.run {
                        self.shortcuts = self.mergeWithSystemShortcuts(cached)
                        self.isLoading = false
                    }
                } else {
                    // 没有缓存，显示空列表
                    print("ℹ️ 没有缓存数据")
                    await MainActor.run {
                        self.shortcuts = []
                        self.isLoading = false
                    }
                }
            }
        }
    }

    /// 合并应用快捷键和系统快捷键（带去重）
    private func mergeWithSystemShortcuts(_ appShortcuts: [ShortcutInfo]) -> [ShortcutInfo] {
        // ✅ 检查是否显示系统快捷键
        guard SettingsManager.shared.showSystemShortcuts else {
            // 如果不显示系统快捷键，直接返回应用快捷键
            return detectAndAssignConflicts(appShortcuts)
        }
        
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

        let mergedShortcuts = Array(uniqueShortcuts.values)
        
        // ✅ 检测冲突并添加到每个快捷键
        return detectAndAssignConflicts(mergedShortcuts)
    }
    
    /// 检测快捷键冲突并分配到每个快捷键
    private func detectAndAssignConflicts(_ shortcuts: [ShortcutInfo]) -> [ShortcutInfo] {
        // 使用冲突检测器检测所有冲突
        let allConflicts = conflictDetector.detectConflicts(shortcuts: shortcuts)
        
        // 按 shortcutId 分组冲突
        var conflictsByShortcutId: [String: [ConflictInfo]] = [:]
        for conflict in allConflicts {
            if conflictsByShortcutId[conflict.shortcutId] == nil {
                conflictsByShortcutId[conflict.shortcutId] = []
            }
            conflictsByShortcutId[conflict.shortcutId]?.append(conflict)
        }
        
        // 创建带冲突信息的新快捷键数组
        var shortcutsWithConflicts: [ShortcutInfo] = []
        for shortcut in shortcuts {
            let conflicts = conflictsByShortcutId[shortcut.id] ?? []
            let updatedShortcut = ShortcutInfo(
                id: shortcut.id,
                keyCombination: shortcut.keyCombination,
                description: shortcut.description,
                application: shortcut.application,
                category: shortcut.category,
                isCustom: shortcut.isCustom,
                conflicts: conflicts
            )
            shortcutsWithConflicts.append(updatedShortcut)
        }
        
        print("🔍 冲突检测完成: \(shortcuts.count) 个快捷键, \(allConflicts.count) 个冲突")
        
        return shortcutsWithConflicts
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
