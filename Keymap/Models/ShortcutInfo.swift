//
//  ShortcutInfo.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

enum ShortcutCategory: String, Codable, CaseIterable {
    case file = "文件"
    case edit = "编辑"
    case view = "视图"
    case window = "窗口"
    case system = "系统"
    case navigation = "导航"
    case other = "其他"
}

struct ShortcutInfo: Identifiable, Codable, Hashable {
    let id: String
    let keyCombination: String
    let description: String
    let application: String
    let category: ShortcutCategory
    let isCustom: Bool
    var conflicts: [ConflictInfo]

    init(
        id: String = UUID().uuidString,
        keyCombination: String,
        description: String,
        application: String,
        category: ShortcutCategory = .other,
        isCustom: Bool = false,
        conflicts: [ConflictInfo] = []
    ) {
        self.id = id
        self.keyCombination = keyCombination
        self.description = description
        self.application = application
        self.category = category
        self.isCustom = isCustom
        self.conflicts = conflicts
    }
}
