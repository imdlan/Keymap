//
//  MenuItemParser.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation
import AppKit
import ApplicationServices
import Carbon

/// 菜单项解析器 - 从AXUIElement提取菜单项信息
class MenuItemParser {

    // MARK: - Public Methods

    /// 解析单个菜单项
    /// - Parameter element: AXUIElement菜单项元素
    /// - Returns: MenuItem对象，如果解析失败返回nil
    func parseMenuItem(_ element: AXUIElement) -> MenuItem? {
        // 提取标题
        guard let title = extractTitle(element), !title.isEmpty else {
            return nil
        }

        // 提取快捷键
        let shortcut = extractShortcut(element)

        // 提取状态
        let isEnabled = extractEnabled(element)
        let hasSubmenu = extractHasSubmenu(element)

        return MenuItem(
            title: title,
            shortcut: shortcut,
            isEnabled: isEnabled,
            hasSubmenu: hasSubmenu
        )
    }

    // MARK: - Private Methods

    /// 提取菜单标题
    func extractTitle(_ element: AXUIElement) -> String? {
        var title: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXTitleAttribute as CFString,
            &title
        )

        guard result == .success, let titleString = title as? String else {
            return nil
        }

        return titleString
    }

    /// 提取快捷键组合
    func extractShortcut(_ element: AXUIElement) -> KeyCombination? {
        // 提取快捷键字符
        guard let cmdChar = extractCmdChar(element) else {
            return nil
        }

        // 提取修饰键
        let modifiers = extractCmdModifiers(element)

        // 将字符转换为键码
        guard let keyCode = charToKeyCode(cmdChar) else {
            return nil
        }

        return KeyCombination(keyCode: keyCode, modifiers: modifiers)
    }

    /// 提取快捷键字符
    private func extractCmdChar(_ element: AXUIElement) -> String? {
        var cmdChar: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXMenuItemCmdCharAttribute as CFString,
            &cmdChar
        )

        guard result == .success, let charString = cmdChar as? String else {
            return nil
        }

        return charString
    }

    /// 提取修饰键
    private func extractCmdModifiers(_ element: AXUIElement) -> CGEventFlags {
        var cmdModifiers: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXMenuItemCmdModifiersAttribute as CFString,
            &cmdModifiers
        )

        guard result == .success, let modifierValue = cmdModifiers as? Int else {
            // 默认返回Command修饰键
            return .maskCommand
        }

        return parseModifiers(modifierValue)
    }

    /// 解析修饰键位掩码
    /// - Parameter modifierValue: 修饰键整数值
    /// - Returns: CGEventFlags
    func parseModifiers(_ modifierValue: Int) -> CGEventFlags {
        var flags: CGEventFlags = []

        // macOS菜单项修饰键位掩码定义：
        // Control: 0x0001
        // Shift:   0x0002
        // Option:  0x0004
        // Command: 0x0008

        if modifierValue & 0x0001 != 0 {
            flags.insert(.maskControl)
        }
        if modifierValue & 0x0002 != 0 {
            flags.insert(.maskShift)
        }
        if modifierValue & 0x0004 != 0 {
            flags.insert(.maskAlternate)  // Option键
        }
        if modifierValue & 0x0008 != 0 {
            flags.insert(.maskCommand)
        }

        return flags
    }

    /// 将字符转换为键码
    private func charToKeyCode(_ char: String) -> Int? {
        guard let firstChar = char.uppercased().first else {
            return nil
        }

        // 字母键映射
        switch firstChar {
        case "A": return kVK_ANSI_A
        case "B": return kVK_ANSI_B
        case "C": return kVK_ANSI_C
        case "D": return kVK_ANSI_D
        case "E": return kVK_ANSI_E
        case "F": return kVK_ANSI_F
        case "G": return kVK_ANSI_G
        case "H": return kVK_ANSI_H
        case "I": return kVK_ANSI_I
        case "J": return kVK_ANSI_J
        case "K": return kVK_ANSI_K
        case "L": return kVK_ANSI_L
        case "M": return kVK_ANSI_M
        case "N": return kVK_ANSI_N
        case "O": return kVK_ANSI_O
        case "P": return kVK_ANSI_P
        case "Q": return kVK_ANSI_Q
        case "R": return kVK_ANSI_R
        case "S": return kVK_ANSI_S
        case "T": return kVK_ANSI_T
        case "U": return kVK_ANSI_U
        case "V": return kVK_ANSI_V
        case "W": return kVK_ANSI_W
        case "X": return kVK_ANSI_X
        case "Y": return kVK_ANSI_Y
        case "Z": return kVK_ANSI_Z

        // 数字键映射
        case "0": return kVK_ANSI_0
        case "1": return kVK_ANSI_1
        case "2": return kVK_ANSI_2
        case "3": return kVK_ANSI_3
        case "4": return kVK_ANSI_4
        case "5": return kVK_ANSI_5
        case "6": return kVK_ANSI_6
        case "7": return kVK_ANSI_7
        case "8": return kVK_ANSI_8
        case "9": return kVK_ANSI_9

        // 特殊字符
        case "-": return kVK_ANSI_Minus
        case "=": return kVK_ANSI_Equal
        case "[": return kVK_ANSI_LeftBracket
        case "]": return kVK_ANSI_RightBracket
        case ";": return kVK_ANSI_Semicolon
        case "'": return kVK_ANSI_Quote
        case ",": return kVK_ANSI_Comma
        case ".": return kVK_ANSI_Period
        case "/": return kVK_ANSI_Slash
        case "\\": return kVK_ANSI_Backslash
        case "`": return kVK_ANSI_Grave

        default:
            return nil
        }
    }

    /// 提取菜单项是否启用
    private func extractEnabled(_ element: AXUIElement) -> Bool {
        var enabled: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXEnabledAttribute as CFString,
            &enabled
        )

        guard result == .success, let enabledBool = enabled as? Bool else {
            return true  // 默认启用
        }

        return enabledBool
    }

    /// 检查是否有子菜单
    private func extractHasSubmenu(_ element: AXUIElement) -> Bool {
        var children: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &children
        )

        guard result == .success,
              let childrenArray = children as? [AXUIElement] else {
            return false
        }

        return !childrenArray.isEmpty
    }
}
