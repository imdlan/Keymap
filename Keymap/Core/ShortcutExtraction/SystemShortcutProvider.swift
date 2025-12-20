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
                description: "退出应用",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_close",
                keyCombination: "⌘W",
                description: "关闭窗口",
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_hide",
                keyCombination: "⌘H",
                description: "隐藏当前应用",
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_hide_others",
                keyCombination: "⌥⌘H",
                description: "隐藏其他应用",
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_minimize",
                keyCombination: "⌘M",
                description: "最小化窗口",
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_new",
                keyCombination: "⌘N",
                description: "新建窗口/文档",
                application: "System",
                category: .file,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_save",
                keyCombination: "⌘S",
                description: "保存",
                application: "System",
                category: .file,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_print",
                keyCombination: "⌘P",
                description: "打印",
                application: "System",
                category: .file,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_undo",
                keyCombination: "⌘Z",
                description: "撤销",
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_redo",
                keyCombination: "⇧⌘Z",
                description: "重做",
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_cut",
                keyCombination: "⌘X",
                description: "剪切",
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_copy",
                keyCombination: "⌘C",
                description: "复制",
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_paste",
                keyCombination: "⌘V",
                description: "粘贴",
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_select_all",
                keyCombination: "⌘A",
                description: "全选",
                application: "System",
                category: .edit,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_find",
                keyCombination: "⌘F",
                description: "查找",
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
                description: "切换应用",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_window_switcher",
                keyCombination: "⌘`",
                description: "切换同应用窗口",
                application: "System",
                category: .window,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_mission_control",
                keyCombination: "⌃↑",
                description: "Mission Control",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_show_desktop",
                keyCombination: "F11",
                description: "显示桌面",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_fullscreen",
                keyCombination: "⌃⌘F",
                description: "全屏切换",
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
                description: "截取整个屏幕",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_screenshot_selection",
                keyCombination: "⇧⌘4",
                description: "截取选定区域",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_screenshot_window",
                keyCombination: "⇧⌘4 Space",
                description: "截取窗口",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_screenshot_menu",
                keyCombination: "⇧⌘5",
                description: "截图和录屏工具",
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
                description: "Spotlight搜索",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_finder_search",
                keyCombination: "⌥⌘Space",
                description: "Finder搜索窗口",
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
                description: "开启/关闭VoiceOver",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_zoom",
                keyCombination: "⌥⌘8",
                description: "开启/关闭缩放",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_invert_colors",
                keyCombination: "⌃⌥⌘8",
                description: "反转颜色",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            ),
            ShortcutInfo(
                id: "system_emoji",
                keyCombination: "⌃⌘Space",
                description: "表情符号和符号",
                application: "System",
                category: .system,
                isCustom: false,
                conflicts: []
            )
        ]
    }
}
