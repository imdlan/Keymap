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
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let extractor = AppShortcutExtractor()
    private let cache = ShortcutCache()
    private let systemProvider = SystemShortcutProvider.shared

    var filteredShortcuts: [ShortcutInfo] {
        if searchText.isEmpty {
            return shortcuts
        }
        return shortcuts.filter { shortcut in
            shortcut.keyCombination.localizedCaseInsensitiveContains(searchText) ||
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
            loadShortcuts(for: frontApp)
        } else {
            currentApp = "未知应用"
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

    /// 合并应用快捷键和系统快捷键
    private func mergeWithSystemShortcuts(_ appShortcuts: [ShortcutInfo]) -> [ShortcutInfo] {
        let systemShortcuts = systemProvider.getSystemShortcuts()
        return appShortcuts + systemShortcuts
    }

    private func loadDemoShortcuts() {
        // 演示数据
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
                category: .system,
                conflicts: [
                    ConflictInfo(
                        shortcutId: UUID().uuidString,
                        conflictType: .system,
                        conflictingApp: "系统",
                        severity: .high,
                        suggestions: ["避免使用系统级快捷键", "选择其他组合"]
                    )
                ]
            ),
        ]

        isLoading = false
    }
}
