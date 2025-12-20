//
//  ConflictInfo.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

enum ConflictType: String, Codable {
    case system = "系统级"
    case application = "应用级"
    case global = "全局"
    case functional = "功能"
}

enum ConflictSeverity: String, Codable {
    case low = "低"
    case medium = "中"
    case high = "高"
}

struct ConflictInfo: Identifiable, Codable, Hashable {
    let id: String
    let shortcutId: String
    let conflictType: ConflictType
    let conflictingApp: String?
    let severity: ConflictSeverity
    let suggestions: [String]

    init(
        id: String = UUID().uuidString,
        shortcutId: String,
        conflictType: ConflictType,
        conflictingApp: String? = nil,
        severity: ConflictSeverity,
        suggestions: [String]
    ) {
        self.id = id
        self.shortcutId = shortcutId
        self.conflictType = conflictType
        self.conflictingApp = conflictingApp
        self.severity = severity
        self.suggestions = suggestions
    }
}
