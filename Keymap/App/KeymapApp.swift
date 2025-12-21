//
//  KeymapApp.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import SwiftUI

@main
struct KeymapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 使用 Settings 但配置为由 AppDelegate 处理
        Settings {
            EmptyView()
        }
        .commands {
            // 替换默认的 Settings 命令，使用 AppDelegate 的实现
            CommandGroup(replacing: .appSettings) {
                Button("设置...") {
                    NotificationCenter.default.post(name: .showSettingsWindow, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .defaultSize(width: 0, height: 0)
    }
}
