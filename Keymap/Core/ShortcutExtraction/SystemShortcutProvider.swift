//
//  SystemShortcutProvider.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

/// 系统快捷键提供者 - 提供macOS系统级快捷键列表
class SystemShortcutProvider {

    // MARK: - Singleton

    static let shared = SystemShortcutProvider()

    private init() {}

    // MARK: - Public Methods

    /// 获取所有系统快捷键
    /// - Returns: 系统快捷键数组
    func getSystemShortcuts() -> [ShortcutInfo] {
        return commonSystemShortcuts + windowManagementShortcuts +
               screenshotShortcuts + spotlightShortcuts + accessibilityShortcuts
    }

    /// 获取内置快捷键（截图、Spotlight等）
    /// - Returns: 内置快捷键数组
    func getBuiltInShortcuts() -> [ShortcutInfo] {
        return screenshotShortcuts + spotlightShortcuts
    }

    // MARK: - System Shortcut Lists

    /// 常用系统快捷键
    private var commonSystemShortcuts: [ShortcutInfo] {
        [
            ShortcutInfo(
                id: "system_quit",
                keyCombination: "⌘Q",
                description: "system.quit_app".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_close",
                keyCombination: "⌘W",
                description: "system.close_window".localized(),
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_hide",
                keyCombination: "⌘H",
                description: "system.hide_app".localized(),
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_hide_others",
                keyCombination: "⌥⌘H",
                description: "system.hide_others".localized(),
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_minimize",
                keyCombination: "⌘M",
                description: "system.minimize_window".localized(),
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_new",
                keyCombination: "⌘N",
                description: "system.new_window".localized(),
                application: "System",
                category: .file,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_save",
                keyCombination: "⌘S",
                description: "system.save".localized(),
                application: "System",
                category: .file,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_print",
                keyCombination: "⌘P",
                description: "system.print".localized(),
                application: "System",
                category: .file,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_undo",
                keyCombination: "⌘Z",
                description: "system.undo".localized(),
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_redo",
                keyCombination: "⇧⌘Z",
                description: "system.redo".localized(),
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_cut",
                keyCombination: "⌘X",
                description: "system.cut".localized(),
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_copy",
                keyCombination: "⌘C",
                description: "system.copy".localized(),
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_paste",
                keyCombination: "⌘V",
                description: "system.paste".localized(),
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_select_all",
                keyCombination: "⌘A",
                description: "system.select_all".localized(),
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_find",
                keyCombination: "⌘F",
                description: "system.find".localized(),
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            )
        ]
    }

    /// 窗口管理快捷键
    private var windowManagementShortcuts: [ShortcutInfo] {
        [
            ShortcutInfo(
                id: "system_app_switcher",
                keyCombination: "⌘Tab",
                description: "system.app_switcher".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_window_switcher",
                keyCombination: "⌘`",
                description: "system.window_switcher".localized(),
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_mission_control",
                keyCombination: "⌃↑",
                description: "system.mission_control".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_show_desktop",
                keyCombination: "F11",
                description: "system.show_desktop".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_fullscreen",
                keyCombination: "⌃⌘F",
                description: "system.fullscreen".localized(),
                application: "System",
                category: .view,
                isCustom: false,
                conflicts: []
            )
        ]
    }

    /// 截图快捷键
    private var screenshotShortcuts: [ShortcutInfo] {
        [
            ShortcutInfo(
                id: "system_screenshot_full",
                keyCombination: "⇧⌘3",
                description: "system.screenshot_full".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_screenshot_selection",
                keyCombination: "⇧⌘4",
                description: "system.screenshot_selection".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_screenshot_window",
                keyCombination: "⇧⌘4 Space",
                description: "system.screenshot_window".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_screenshot_menu",
                keyCombination: "⇧⌘5",
                description: "system.screenshot_menu".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            )
        ]
    }

    /// Spotlight和搜索快捷键
    private var spotlightShortcuts: [ShortcutInfo] {
        [
            ShortcutInfo(
                id: "system_spotlight",
                keyCombination: "⌘Space",
                description: "system.spotlight".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_finder_search",
                keyCombination: "⌥⌘Space",
                description: "system.finder_search".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            )
        ]
    }

    /// 辅助功能快捷键
    private var accessibilityShortcuts: [ShortcutInfo] {
        [
            ShortcutInfo(
                id: "system_voiceover",
                keyCombination: "⌘F5",
                description: "system.voiceover".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_zoom",
                keyCombination: "⌥⌘8",
                description: "system.zoom".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_invert_colors",
                keyCombination: "⌃⌥⌘8",
                description: "system.invert_colors".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_emoji",
                keyCombination: "⌃⌘Space",
                description: "system.emoji".localized(),
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            )
        ]
    }
}
