//
//  KeyCombinationDetector.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Carbon
import Cocoa

struct KeyCombination: Hashable, Equatable {
    let keyCode: Int
    let modifiers: CGEventFlags

    // 手动实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifiers.rawValue)
    }

    static func == (lhs: KeyCombination, rhs: KeyCombination) -> Bool {
        return lhs.keyCode == rhs.keyCode && lhs.modifiers == rhs.modifiers
    }

    var displayString: String {
        var result = ""
        if modifiers.contains(.maskControl) { result += "⌃" }
        if modifiers.contains(.maskAlternate) { result += "⌥" }
        if modifiers.contains(.maskShift) { result += "⇧" }
        if modifiers.contains(.maskCommand) { result += "⌘" }
        result += keyCodeToString(keyCode)
        return result
    }

    private func keyCodeToString(_ keyCode: Int) -> String {
        // 将键码转换为可读字符
        switch keyCode {
        // 字母键 (A-Z)
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"

        // 数字键 (0-9)
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"

        // 特殊字符键
        case kVK_ANSI_Minus: return "-"           // 减号/连字符
        case kVK_ANSI_Equal: return "="           // 等号
        case kVK_ANSI_LeftBracket: return "["     // 左方括号
        case kVK_ANSI_RightBracket: return "]"    // 右方括号
        case kVK_ANSI_Quote: return "'"           // 单引号
        case kVK_ANSI_Semicolon: return ";"       // 分号
        case kVK_ANSI_Backslash: return "\\"      // 反斜杠
        case kVK_ANSI_Comma: return ","           // 逗号 (keyCode: 43)
        case kVK_ANSI_Slash: return "/"           // 斜杠
        case kVK_ANSI_Period: return "."          // 句号
        case kVK_ANSI_Grave: return "`"           // 反引号

        // 控制键
        case kVK_Return: return "↩"               // 回车
        case kVK_Tab: return "⇥"                  // Tab
        case kVK_Space: return "Space"            // 空格
        case kVK_Delete: return "⌫"               // 删除
        case kVK_Escape: return "⎋"               // ESC
        case kVK_ForwardDelete: return "⌦"        // Forward Delete
        case kVK_Home: return "↖"                 // Home
        case kVK_End: return "↘"                  // End
        case kVK_PageUp: return "⇞"               // Page Up
        case kVK_PageDown: return "⇟"             // Page Down

        // 方向键
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"

        // 功能键 (F1-F20)
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_F13: return "F13"
        case kVK_F14: return "F14"
        case kVK_F15: return "F15"
        case kVK_F16: return "F16"
        case kVK_F17: return "F17"
        case kVK_F18: return "F18"
        case kVK_F19: return "F19"
        case kVK_F20: return "F20"

        // 小键盘数字键
        case kVK_ANSI_Keypad0: return "0"
        case kVK_ANSI_Keypad1: return "1"
        case kVK_ANSI_Keypad2: return "2"
        case kVK_ANSI_Keypad3: return "3"
        case kVK_ANSI_Keypad4: return "4"
        case kVK_ANSI_Keypad5: return "5"
        case kVK_ANSI_Keypad6: return "6"
        case kVK_ANSI_Keypad7: return "7"
        case kVK_ANSI_Keypad8: return "8"
        case kVK_ANSI_Keypad9: return "9"

        // 小键盘运算符
        case kVK_ANSI_KeypadDecimal: return "."
        case kVK_ANSI_KeypadMultiply: return "*"
        case kVK_ANSI_KeypadPlus: return "+"
        case kVK_ANSI_KeypadClear: return "⌧"
        case kVK_ANSI_KeypadDivide: return "/"
        case kVK_ANSI_KeypadEnter: return "↩"
        case kVK_ANSI_KeypadMinus: return "-"
        case kVK_ANSI_KeypadEquals: return "="

        // 未知键码，显示为 [数字] 以便调试
        default: return "[\(keyCode)]"
        }
    }
}

class KeyCombinationDetector {
    func detectKeyCombination(event: CGEvent) -> KeyCombination? {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // 过滤掉非快捷键（没有修饰键）
        let hasModifier = flags.contains(.maskCommand) ||
                         flags.contains(.maskControl) ||
                         flags.contains(.maskAlternate) ||
                         flags.contains(.maskShift)

        guard hasModifier else { return nil }

        return KeyCombination(keyCode: keyCode, modifiers: flags)
    }
}
