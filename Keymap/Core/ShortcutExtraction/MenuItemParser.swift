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

        // 如果通过Accessibility API未能获取快捷键，尝试从标题中解析
        let finalShortcut: KeyCombination?
        if shortcut == nil {
            finalShortcut = extractShortcutFromTitle(title)
        } else {
            finalShortcut = shortcut
        }

        // 提取状态
        let isEnabled = extractEnabled(element)
        let hasSubmenu = extractHasSubmenu(element)

        return MenuItem(
            title: title,
            shortcut: finalShortcut,
            isEnabled: isEnabled,
            hasSubmenu: hasSubmenu
        )
    }

    /// 从菜单项标题中提取快捷键（备用方法）
    /// 格式示例："New Tab\t⌘T" 或 "New Tab    ⌘T"
    private func extractShortcutFromTitle(_ title: String) -> KeyCombination? {
        // 查找Tab字符或多个空格后的快捷键
        let components = title.components(separatedBy: CharacterSet(charactersIn: "\t "))

        // 查找包含修饰键符号的部分
        for component in components.reversed() {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // 检查是否包含修饰键符号
            if trimmed.contains("⌘") || trimmed.contains("⇧") ||
               trimmed.contains("⌥") || trimmed.contains("⌃") {
                return parseShortcutString(trimmed)
            }
        }

        return nil
    }

    /// 解析快捷键字符串（如"⌘T"或"⇧⌘N"）
    private func parseShortcutString(_ shortcutStr: String) -> KeyCombination? {
        var modifiers: CGEventFlags = []
        var mainKey = ""

        for char in shortcutStr {
            let charStr = String(char)
            switch charStr {
            case "⌘":
                modifiers.insert(.maskCommand)
            case "⇧":
                modifiers.insert(.maskShift)
            case "⌥":
                modifiers.insert(.maskAlternate)
            case "⌃":
                modifiers.insert(.maskControl)
            default:
                mainKey += charStr
            }
        }

        guard !mainKey.isEmpty, let keyCode = charToKeyCode(mainKey) else {
            return nil
        }

        return KeyCombination(keyCode: keyCode, modifiers: modifiers)
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
        var modifiers = extractCmdModifiers(element)

        // 智能修饰键修正：如果有快捷键字符但没有修饰键，默认添加Command键
        // 原因：macOS中几乎所有的单字符快捷键都需要至少一个修饰键
        // Chrome、VS Code等应用在Accessibility API中暴露的修饰键值可能为0
        if modifiers.isEmpty && cmdChar.count == 1 {
            // 检查是否是字母、数字或常见的快捷键字符
            let validShortcutChars = CharacterSet.alphanumerics
                .union(CharacterSet(charactersIn: "[]\\;',./`-="))

            if cmdChar.rangeOfCharacter(from: validShortcutChars) != nil {
                modifiers.insert(.maskCommand)
            }
        }

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

        // macOS菜单项修饰键位掩码定义（有两种格式）：
        //
        // 标准格式（大多数应用）：
        // Control: 0x0001
        // Shift:   0x0002
        // Option:  0x0004
        // Command: 0x0008
        //
        // Chrome等应用使用的格式（带有额外的cmdKey标志位）：
        // Control: 0x0001 (controlKey)
        // Shift:   0x0002 (shiftKey)
        // Option:  0x0004 (optionKey)
        // Command: 0x0008 (cmdKey)
        // 额外的：0x0010 (cmdKeyBit) - Chrome在有Command键时会同时设置这一位

        if modifierValue & 0x0001 != 0 {
            flags.insert(.maskControl)
        }
        if modifierValue & 0x0002 != 0 {
            flags.insert(.maskShift)
        }
        if modifierValue & 0x0004 != 0 {
            flags.insert(.maskAlternate)  // Option键
        }
        // Command键：检查 0x0008 或 0x0010（Chrome格式）
        if (modifierValue & 0x0008) != 0 || (modifierValue & 0x0010) != 0 {
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
