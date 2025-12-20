//
//  StatisticsSummary.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

struct ShortcutUsage: Identifiable, Codable {
    var id: String { "\(shortcut)|\(application)" }
    let shortcut: String
    let application: String
    let count: Int
}

struct StatisticsSummary: Codable {
    let totalUsage: Int
    let conflictCount: Int
    let efficiencyScore: Double
    let topShortcuts: [ShortcutUsage]
    let timeRange: DateInterval

    init(
        totalUsage: Int,
        conflictCount: Int,
        efficiencyScore: Double,
        topShortcuts: [ShortcutUsage],
        timeRange: DateInterval
    ) {
        self.totalUsage = totalUsage
        self.conflictCount = conflictCount
        self.efficiencyScore = efficiencyScore
        self.topShortcuts = topShortcuts
        self.timeRange = timeRange
    }
}
