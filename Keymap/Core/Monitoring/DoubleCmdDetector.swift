//
//  DoubleCmdDetector.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Cocoa

class DoubleCmdDetector {
    private var firstPressTime: Date?
    private var firstReleaseTime: Date?
    private var cmdIsPressed = false
    private let doublePressThreshold: TimeInterval = 0.5  // 两次按下之间的最大间隔

    func detectDoubleCmdPress(event: CGEvent) -> Bool {
        let flags = event.flags
        let cmdPressed = flags.contains(.maskCommand)
        let now = Date()

        // Cmd 键被按下
        if cmdPressed && !cmdIsPressed {
            cmdIsPressed = true
            print("⬇️ Cmd 按下")

            // 检查是否是第二次按下
            if let lastRelease = firstReleaseTime {
                let interval = now.timeIntervalSince(lastRelease)
                print("⏱️ 距上次释放: \(String(format: "%.3f", interval))秒")

                if interval < doublePressThreshold {
                    // 检测到双击
                    print("✅ 检测到双击 Cmd！")
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

        // Cmd 键被释放
        if !cmdPressed && cmdIsPressed {
            cmdIsPressed = false
            firstReleaseTime = now
            print("⬆️ Cmd 释放")
        }

        return false
    }
}
