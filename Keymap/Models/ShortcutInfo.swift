//
//  ShortcutInfo.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

enum ShortcutCategory: String, Codable, CaseIterable {
    case file = "file"
    case edit = "edit"
    case view = "view"
    case window = "window"
    case system = "system"
    case navigation = "navigation"
    case other = "other"

    /// 本地化显示名称
    var displayName: String {
        switch self {
        case .file:       return "category.file".localized()
        case .edit:       return "category.edit".localized()
        case .view:       return "category.view".localized()
        case .window:     return "category.window".localized()
        case .system:     return "category.system".localized()
        case .navigation: return "category.navigation".localized()
        case .other:      return "category.other".localized()
        }
    }
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
