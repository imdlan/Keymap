//
//  ConflictInfo.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

enum ConflictType: String, Codable {
    case system = "system"
    case application = "application"
    case global = "global"
    case functional = "functional"

    /// 本地化显示名称
    var displayName: String {
        switch self {
        case .system:      return "conflict.type.system".localized()
        case .application: return "conflict.type.application".localized()
        case .global:      return "conflict.type.global".localized()
        case .functional:  return "conflict.type.functional".localized()
        }
    }
}

enum ConflictSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    /// 本地化显示名称
    var displayName: String {
        switch self {
        case .low:    return "conflict.severity.low".localized()
        case .medium: return "conflict.severity.medium".localized()
        case .high:   return "conflict.severity.high".localized()
        }
    }
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
