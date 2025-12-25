//
//  KeyRecorder.swift
//  Keymap
//
//  Created on 2025-12-22.
//

import Foundation
import AppKit
import Carbon

/// 快捷键录制器 - 用于录制用户自定义快捷键
class KeyRecorder {
    
    // MARK: - Properties
    
    /// 录制回调
    var onKeyRecorded: ((KeyCombination) -> Void)?
    
    /// 是否正在录制
    private(set) var isRecording = false
    
    /// 事件监听器
    private var eventMonitor: Any?
    
    // MARK: - Singleton
    
    static let shared = KeyRecorder()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 开始录制快捷键
    func startRecording(callback: @escaping (KeyCombination) -> Void) {
        guard !isRecording else {
            Logger.warning("录制已在进行中")
            return
        }
        
        isRecording = true
        onKeyRecorded = callback
        
        Logger.info("🎙️ 开始录制快捷键...")
        
        // 添加本地事件监听器
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event -> NSEvent? in
            guard let self = self else { return event }
            
            // 获取修饰键
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            
            // 忽略单独的修饰键（必须有字母或数字键）
            guard event.keyCode != 54 && event.keyCode != 55 && // Cmd
                  event.keyCode != 58 && event.keyCode != 61 && // Option
                  event.keyCode != 59 && event.keyCode != 62 && // Control
                  event.keyCode != 56 && event.keyCode != 60    // Shift
            else {
                return nil // 拦截修饰键，不传递
            }
            
            // 创建快捷键组合
            let keyCombination = KeyCombination(
                keyCode: Int(event.keyCode),
                modifiers: self.convertModifiers(modifiers)
            )
            
            Logger.info("📝 录制到快捷键: \(keyCombination.displayString)")
            
            // 停止录制
            self.stopRecording()
            
            // 调用回调
            self.onKeyRecorded?(keyCombination)
            
            // 拦截事件，不传递
            return nil
        }
        
        NotificationHelper.shared.send(
            title: "开始录制",
            message: "请按下要录制的快捷键组合"
        )
    }
    
    /// 停止录制快捷键
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        Logger.info("🛑 停止录制快捷键")
    }
    
    // MARK: - Private Methods
    
    /// 转换修饰键
    private func convertModifiers(_ modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        
        if modifiers.contains(.command) {
            flags.insert(.maskCommand)
        }
        if modifiers.contains(.option) {
            flags.insert(.maskAlternate)
        }
        if modifiers.contains(.control) {
            flags.insert(.maskControl)
        }
        if modifiers.contains(.shift) {
            flags.insert(.maskShift)
        }
        
        return flags
    }
    
    /// 格式化显示字符串
    private func formatDisplayString(event: NSEvent, modifiers: NSEvent.ModifierFlags) -> String {
        var components: [String] = []
        
        // 添加修饰键
        if modifiers.contains(.control) {
            components.append("⌃")
        }
        if modifiers.contains(.option) {
            components.append("⌥")
        }
        if modifiers.contains(.shift) {
            components.append("⇧")
        }
        if modifiers.contains(.command) {
            components.append("⌘")
        }
        
        // 添加主键
        if let characters = event.charactersIgnoringModifiers?.uppercased() {
            components.append(characters)
        } else {
            // 特殊键
            components.append(specialKeyName(for: event.keyCode))
        }
        
        return components.joined()
    }
    
    /// 获取特殊键名称
    private func specialKeyName(for keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_ForwardDelete: return "⌦"
        case kVK_F1...kVK_F20:
            return "F\(Int(keyCode) - kVK_F1 + 1)"
        default: return "Key\(keyCode)"
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        stopRecording()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// 录制到新的快捷键
    static let keyRecorded = Notification.Name("com.keymap.keyRecorded")
}
