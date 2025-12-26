//
//  UsageRecord.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

enum UsageContext: String, Codable {
    case normal = "normal"
    case conflict = "conflict"
    case remapped = "remapped"

    /// 本地化显示名称
    var displayName: String {
        switch self {
        case .normal:   return "usage.context.normal".localized()
        case .conflict: return "usage.context.conflict".localized()
        case .remapped: return "usage.context.remapped".localized()
        }
    }
}

struct UsageRecord: Identifiable, Codable {
    let id: String
    let shortcutKey: String
    let application: String
    let timestamp: Date
    let context: UsageContext

    init(
        id: String = UUID().uuidString,
        shortcutKey: String,
        application: String,
        timestamp: Date = Date(),
        context: UsageContext = .normal
    ) {
        self.id = id
        self.shortcutKey = shortcutKey
        self.application = application
        self.timestamp = timestamp
        self.context = context
    }
}
