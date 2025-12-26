//
//  KeymapShortcutProvider.swift
//  Keymap
//
//  Created on 2025-12-22.
//

import Foundation

/// Keymap应用快捷键提供者 - 提供Keymap自身的快捷键列表
class KeymapShortcutProvider {

    // MARK: - Singleton

    static let shared = KeymapShortcutProvider()

    private init() {}

    // MARK: - Public Methods

    /// 获取Keymap应用的所有快捷键
    /// - Returns: Keymap快捷键数组
    func getKeymapShortcuts() -> [ShortcutInfo] {
        return [
            ShortcutInfo(
                id: "keymap_show_panel",
                keyCombination: "⌘⌘",
                description: "keymap.shortcut.show_panel".localized(),
                application: "Keymap",
                category: .other,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "keymap_statistics",
                keyCombination: "⌘D",
                description: "keymap.shortcut.statistics".localized(),
                application: "Keymap",
                category: .other,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "keymap_settings",
                keyCombination: "⌘,",
                description: "keymap.shortcut.settings".localized(),
                application: "Keymap",
                category: .other,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "keymap_quit",
                keyCombination: "⌘Q",
                description: "keymap.shortcut.quit".localized(),
                application: "Keymap",
                category: .system,
                isCustom: false,
                conflicts: []
            )
        ]
    }
}
