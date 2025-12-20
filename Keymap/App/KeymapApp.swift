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
        Settings {
            EmptyView()
        }
    }
}
