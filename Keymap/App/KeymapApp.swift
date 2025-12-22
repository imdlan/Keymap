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
        // ✅ 使用空场景，不显示任何菜单栏
        WindowGroup {
            EmptyView()
        }
        .defaultSize(width: 0, height: 0)
        .commands {
            // 完全移除所有菜单组（第一组）
            CommandGroup(replacing: .appInfo) { }
            CommandGroup(replacing: .appSettings) { }
            CommandGroup(replacing: .appTermination) { }
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .pasteboard) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .windowSize) { }
            CommandGroup(replacing: .windowList) { }
            CommandGroup(replacing: .windowArrangement) { }
            CommandGroup(replacing: .help) { }
        }
        .commands {
            // 完全移除所有菜单组（第二组）
            CommandGroup(replacing: .textEditing) { }
            CommandGroup(replacing: .textFormatting) { }
            CommandGroup(replacing: .toolbar) { }
            CommandGroup(replacing: .sidebar) { }
            CommandGroup(replacing: .systemServices) { }
        }
    }
}
