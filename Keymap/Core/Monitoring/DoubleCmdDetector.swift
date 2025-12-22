//
//  DoubleCmdDetector.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Cocoa

/// 双击修饰键检测器（支持Cmd、Option、Control）
class DoubleCmdDetector {
    
    // MARK: - 修饰键类型
    
    enum ModifierKey {
        case command
        case option
        case control
        
        var displayName: String {
            switch self {
            case .command: return "Cmd"
            case .option: return "Option"
            case .control: return "Control"
            }
        }
        
        var flagMask: CGEventFlags {
            switch self {
            case .command: return .maskCommand
            case .option: return .maskAlternate
            case .control: return .maskControl
            }
        }
    }
    
    // MARK: - Properties
    
    private var firstPressTime: Date?
    private var firstReleaseTime: Date?
    private var keyIsPressed = false
    
    // 从设置读取配置
    private let settings = SettingsManager.shared
    
    private var doublePressThreshold: TimeInterval {
        return settings.doubleCmdThreshold
    }
    
    private var modifierKey: ModifierKey {
        switch settings.triggerKey {
        case "doubleOption":
            return .option
        case "doubleControl":
            return .control
        default:
            return .command
        }
    }

    // MARK: - Detection
    
    func detectDoubleCmdPress(event: CGEvent) -> Bool {
        let flags = event.flags
        let currentKey = modifierKey
        let keyPressed = flags.contains(currentKey.flagMask)
        let now = Date()

        // 修饰键被按下
        if keyPressed && !keyIsPressed {
            keyIsPressed = true
            Logger.debug("⬇️ \(currentKey.displayName) 按下")

            // 检查是否是第二次按下
            if let lastRelease = firstReleaseTime {
                let interval = now.timeIntervalSince(lastRelease)
                Logger.debug("⏱️ 距上次释放: \(String(format: "%.3f", interval))秒，阈值: \(String(format: "%.3f", doublePressThreshold))秒")

                if interval < doublePressThreshold {
                    // 检测到双击
                    Logger.info("✅ 检测到双击 \(currentKey.displayName)！")
                    // 重置状态
                    firstPressTime = nil
                    firstReleaseTime = nil
                    return true
                }
            }

            // 记录这次按下作为第一次按下
            firstPressTime = now
            firstReleaseTime = nil
        }

        // 修饰键被释放
        if !keyPressed && keyIsPressed {
            keyIsPressed = false
            firstReleaseTime = now
            Logger.debug("⬆️ \(currentKey.displayName) 释放")
        }

        return false
    }
}
