//
//  UsageRepository.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

/// 时间段枚举
enum StatisticsPeriod {
    case today      // 今天
    case week       // 本周
    case month      // 本月
    case all        // 全部

    var days: Int {
        switch self {
        case .today: return 1
        case .week: return 7
        case .month: return 30
        case .all: return 3650  // 10年
        }
    }
}

/// 使用记录数据访问层
class UsageRepository {

    // MARK: - Properties

    private let db = DatabaseManager.shared

    // MARK: - Public Methods

    /// 记录使用
    /// - Parameter record: 使用记录
    /// - Returns: 是否成功
    func recordUsage(_ record: UsageRecord) -> Bool {
        let sql = """
        INSERT INTO usage_records (id, shortcut_key, bundle_id, timestamp, context)
        VALUES (?, ?, ?, ?, ?);
        """

        let parameters: [Any] = [
            record.id,
            record.shortcutKey,
            record.application,  // application字段对应数据库的bundle_id
            Int64(record.timestamp.timeIntervalSince1970),
            record.context.rawValue
        ]

        let success = db.executeUpdate(sql, parameters: parameters)

        if success {
            // 异步更新统计摘要表
            Task {
                await updateDailySummary(
                    shortcutKey: record.shortcutKey,
                    bundleId: record.application,
                    date: dateString(from: record.timestamp)
                )
            }
        }

        return success
    }

    /// 获取时间段内的使用记录
    /// - Parameters:
    ///   - from: 开始时间
    ///   - to: 结束时间
    /// - Returns: 使用记录数组
    func fetchUsageRecords(from: Date, to: Date) -> [UsageRecord] {
        let fromTimestamp = Int64(from.timeIntervalSince1970)
        let toTimestamp = Int64(to.timeIntervalSince1970)

        let sql = """
        SELECT * FROM usage_records
        WHERE timestamp >= \(fromTimestamp) AND timestamp <= \(toTimestamp)
        ORDER BY timestamp DESC
        LIMIT 1000;
        """

        let rows = db.executeQuery(sql)
        return rows.compactMap { parseUsageRecord(from: $0) }
    }

    /// 获取快捷键的使用次数
    /// - Parameters:
    ///   - shortcutKey: 快捷键组合
    ///   - period: 时间段
    /// - Returns: 使用次数
    func getUsageCount(for shortcutKey: String, period: StatisticsPeriod = .all) -> Int {
        let startDate = startDate(for: period)
        let timestamp = Int64(startDate.timeIntervalSince1970)

        let sql = """
        SELECT COUNT(*) as count FROM usage_records
        WHERE shortcut_key = '\(shortcutKey)'
        AND timestamp >= \(timestamp);
        """

        let rows = db.executeQuery(sql)
        let count = rows.first?["count"] as? Int64 ?? 0
        return Int(count)
    }

    /// 聚合统计数据
    /// - Parameter period: 时间段
    /// - Returns: 统计摘要
    func aggregateStatistics(for period: StatisticsPeriod) -> StatisticsSummary {
        let startDate = startDate(for: period)
        let endDate = Date()
        let timestamp = Int64(startDate.timeIntervalSince1970)

        // 调试输出
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let periodName: String
        switch period {
        case .today: periodName = "今天"
        case .week: periodName = "本周"
        case .month: periodName = "本月"
        case .all: periodName = "全部"
        }
        print("📊 统计周期: \(periodName)")
        print("📊 开始时间: \(formatter.string(from: startDate)) (timestamp: \(timestamp))")
        print("📊 结束时间: \(formatter.string(from: endDate))")

        // 1. 总使用次数
        let totalSQL = """
        SELECT COUNT(*) as count FROM usage_records
        WHERE timestamp >= \(timestamp);
        """
        let totalRows = db.executeQuery(totalSQL)
        let totalUsage = Int(totalRows.first?["count"] as? Int64 ?? 0)
        print("📊 总使用次数: \(totalUsage)")

        // 2. 冲突次数
        let conflictSQL = """
        SELECT COUNT(*) as count FROM usage_records
        WHERE timestamp >= \(timestamp) AND context = '\(UsageContext.conflict.rawValue)';
        """
        let conflictRows = db.executeQuery(conflictSQL)
        let conflictCount = Int(conflictRows.first?["count"] as? Int64 ?? 0)
        print("📊 冲突次数: \(conflictCount)")

        // 3. Top 10 快捷键（按应用分组）
        let topShortcutsSQL = """
        SELECT shortcut_key, bundle_id, COUNT(*) as count
        FROM usage_records
        WHERE timestamp >= \(timestamp)
        GROUP BY shortcut_key, bundle_id
        ORDER BY count DESC
        LIMIT 10;
        """
        let shortcutRows = db.executeQuery(topShortcutsSQL)
        let topShortcuts = shortcutRows.compactMap { row -> ShortcutUsage? in
            guard let key = row["shortcut_key"] as? String,
                  let bundleId = row["bundle_id"] as? String,
                  let count = row["count"] as? Int64 else {
                return nil
            }
            return ShortcutUsage(
                shortcut: key,
                application: bundleId,
                count: Int(count)
            )
        }
        print("📊 Top快捷键数量: \(topShortcuts.count)")

        // 4. 无冲突率（无冲突的使用占比）
        let efficiencyScore = totalUsage > 0
            ? Double(totalUsage - conflictCount) / Double(totalUsage) * 100.0
            : 100.0

        // 5. 时间范围
        let timeRange = DateInterval(start: startDate, end: endDate)

        return StatisticsSummary(
            totalUsage: totalUsage,
            conflictCount: conflictCount,
            efficiencyScore: efficiencyScore,
            topShortcuts: topShortcuts,
            timeRange: timeRange
        )
    }

    /// 清理旧记录
    /// - Parameter days: 保留天数
    /// - Returns: 是否成功
    func cleanOldRecords(olderThan days: Int) -> Bool {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let timestamp = Int64(cutoffDate.timeIntervalSince1970)

        let sql = "DELETE FROM usage_records WHERE timestamp < \(timestamp);"
        let success = db.executeUpdate(sql)

        if success {
            let count = db.changesCount
            print("🗑 已清理 \(count) 条旧使用记录（保留\(days)天内）")
        }

        return success
    }

    /// 获取应用的使用统计
    /// - Parameters:
    ///   - bundleId: 应用Bundle ID
    ///   - period: 时间段
    /// - Returns: (总次数, Top快捷键)
    func getApplicationStatistics(
        for bundleId: String,
        period: StatisticsPeriod = .week
    ) -> (totalCount: Int, topShortcuts: [(key: String, count: Int)]) {
        let startDate = startDate(for: period)
        let timestamp = Int64(startDate.timeIntervalSince1970)

        // 总次数
        let totalSQL = """
        SELECT COUNT(*) as count FROM usage_records
        WHERE bundle_id = '\(bundleId)' AND timestamp >= \(timestamp);
        """
        let totalRows = db.executeQuery(totalSQL)
        let totalCount = Int(totalRows.first?["count"] as? Int64 ?? 0)

        // Top快捷键
        let topSQL = """
        SELECT shortcut_key, COUNT(*) as count
        FROM usage_records
        WHERE bundle_id = '\(bundleId)' AND timestamp >= \(timestamp)
        GROUP BY shortcut_key
        ORDER BY count DESC
        LIMIT 5;
        """
        let topRows = db.executeQuery(topSQL)
        let topShortcuts = topRows.compactMap { row -> (String, Int)? in
            guard let key = row["shortcut_key"] as? String,
                  let count = row["count"] as? Int64 else {
                return nil
            }
            return (key, Int(count))
        }

        return (totalCount, topShortcuts)
    }

    /// 获取快捷键使用趋势
    /// - Parameters:
    ///   - shortcutKey: 快捷键组合
    ///   - days: 天数
    /// - Returns: 每日使用次数
    func getUsageTrend(for shortcutKey: String, days: Int = 7) -> [(date: String, count: Int)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let sql = """
        SELECT date, SUM(usage_count) as count
        FROM statistics_summary
        WHERE shortcut_key = '\(shortcutKey)'
        AND date >= '\(dateString(from: startDate))'
        GROUP BY date
        ORDER BY date;
        """

        let rows = db.executeQuery(sql)
        return rows.compactMap { row -> (String, Int)? in
            guard let date = row["date"] as? String,
                  let count = row["count"] as? Int64 else {
                return nil
            }
            return (date, Int(count))
        }
    }

    // MARK: - Private Methods

    /// 更新每日统计摘要
    private func updateDailySummary(shortcutKey: String, bundleId: String, date: String) async {
        // 检查记录是否存在
        let checkSQL = """
        SELECT usage_count FROM statistics_summary
        WHERE bundle_id = '\(bundleId)'
        AND shortcut_key = '\(shortcutKey)'
        AND date = '\(date)';
        """

        let rows = db.executeQuery(checkSQL)

        if let existingRow = rows.first,
           let currentCount = existingRow["usage_count"] as? Int64 {
            // 更新计数
            let updateSQL = """
            UPDATE statistics_summary
            SET usage_count = ?
            WHERE bundle_id = ? AND shortcut_key = ? AND date = ?;
            """

            _ = db.executeUpdate(updateSQL, parameters: [
                currentCount + 1,
                bundleId,
                shortcutKey,
                date
            ])
        } else {
            // 插入新记录
            let insertSQL = """
            INSERT INTO statistics_summary (bundle_id, shortcut_key, date, usage_count)
            VALUES (?, ?, ?, ?);
            """

            _ = db.executeUpdate(insertSQL, parameters: [
                bundleId,
                shortcutKey,
                date,
                1
            ])
        }
    }

    /// 从数据库行解析UsageRecord
    private func parseUsageRecord(from row: [String: Any]) -> UsageRecord? {
        guard let id = row["id"] as? String,
              let shortcutKey = row["shortcut_key"] as? String,
              let bundleId = row["bundle_id"] as? String,
              let timestampInt = row["timestamp"] as? Int64,
              let contextString = row["context"] as? String,
              let context = UsageContext(rawValue: contextString) else {
            return nil
        }

        return UsageRecord(
            id: id,
            shortcutKey: shortcutKey,
            application: bundleId,
            timestamp: Date(timeIntervalSince1970: TimeInterval(timestampInt)),
            context: context
        )
    }

    /// 计算时间段的起始日期
    private func startDate(for period: StatisticsPeriod) -> Date {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .today:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .all:
            return Date(timeIntervalSince1970: 0)
        }
    }

    /// 日期转字符串（YYYY-MM-DD）
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
