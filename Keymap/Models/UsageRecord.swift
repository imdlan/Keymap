//
//  UsageRecord.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

enum UsageContext: String, Codable {
    case normal = "正常"
    case conflict = "冲突"
    case remapped = "重映射"
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
