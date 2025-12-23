//
//  StatisticsWindow.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import SwiftUI
import AppKit

/// 统计分析窗口
class StatisticsWindow: NSWindow {

    // MARK: - Properties

    private var hostingView: NSHostingView<StatisticsView>?

    // MARK: - Initialization

    init() {
        // 窗口配置
        let contentRect = NSRect(x: 0, y: 0, width: 800, height: 600)

        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
    }

    // MARK: - Setup

    private func setupWindow() {
        title = "统计分析"
        center()
        isReleasedWhenClosed = false

        // 设置窗口最小尺寸
        minSize = NSSize(width: 600, height: 400)

        // 设置窗口级别（普通窗口级别，但确保能置顶）
        level = .normal

        // 确保窗口可以成为主窗口
        collectionBehavior = [.managed, .fullScreenPrimary]
    }

    private func setupContent() {
        let statisticsView = StatisticsView()
        let hostingView = NSHostingView(rootView: statisticsView)

        contentView = hostingView
        self.hostingView = hostingView
    }

    // MARK: - Public Methods

    func showWindow() {
        // 显示窗口并确保在最前
        makeKeyAndOrderFront(nil)

        // 激活应用
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Statistics View

struct StatisticsView: View {

    // MARK: - State

    @Environment(\.colorScheme) var colorScheme  // 检测深色/浅色模式
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var selectedPeriod: StatisticsPeriod = .today
    @State private var selectedApp: String? = nil

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbarView
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // 主内容
            ScrollView {
                VStack(spacing: 20) {
                    // 概览卡片
                    overviewSection

                    // 使用频率排行
                    topShortcutsSection

                    // 使用趋势图
                    trendChartSection

                    // 高冲突快捷键
                    conflictsSection

                    // 优化建议
                    suggestionsSection
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            viewModel.loadStatistics(for: selectedPeriod)
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack {
            // 时间范围选择 - 自定义分段选择器
            HStack(spacing: 0) {
                ForEach([
                    (StatisticsPeriod.today, "今天"),
                    (StatisticsPeriod.week, "本周"),
                    (StatisticsPeriod.month, "本月"),
                    (StatisticsPeriod.all, "全部")
                ], id: \.0) { period, title in
                    Button(action: {
                        selectedPeriod = period
                        viewModel.loadStatistics(for: period)
                    }) {
                        Text(title)
                            .font(.body)
                            .fontWeight(selectedPeriod == period ? .semibold : .regular)
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .frame(width: 70, height: 28)
                            .contentShape(Rectangle())
                            .background(
                                selectedPeriod == period ? 
                                    Color.blue : 
                                    (colorScheme == .dark ? Color(white: 0.25) : Color.white)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
            )

            Spacer()

            // 刷新按钮
            Button(action: {
                viewModel.loadStatistics(for: selectedPeriod)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                    Text("刷新")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .dark ? Color(white: 0.25) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
            )
            .foregroundColor(.primary)

            // 导出按钮
            Button(action: {
                viewModel.exportStatistics()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                    Text("导出")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
            )
            .foregroundColor(.white)
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("概览")
                .font(.headline)

            HStack(spacing: 20) {
                // 总使用次数
                statisticCard(
                    title: "总使用次数",
                    value: "\(viewModel.summary.totalUsage)",
                    icon: "hand.tap.fill",
                    color: .blue
                )

                // 冲突次数
                statisticCard(
                    title: "冲突次数",
                    value: "\(viewModel.summary.conflictCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )

                // 无冲突率
                statisticCard(
                    title: "无冲突率",
                    value: String(format: "%.1f%%", viewModel.summary.efficiencyScore),
                    icon: "checkmark.shield.fill",
                    color: .green
                )

                // 活跃应用数
                statisticCard(
                    title: "活跃应用",
                    value: "\(viewModel.activeAppsCount)",
                    icon: "app.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(6)
    }

    // MARK: - Top Shortcuts Section

    private var topShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用频率排行 (Top 10)")
                .font(.headline)

            if viewModel.summary.topShortcuts.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.summary.topShortcuts.prefix(10).enumerated()), id: \.offset) { index, usage in
                        shortcutUsageRow(rank: index + 1, usage: usage)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func shortcutUsageRow(rank: Int, usage: ShortcutUsage) -> some View {
        HStack {
            // 排名
            Text("\(rank)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30)

            // 快捷键 - 使用 KeyBadgeView
            KeyBadgeView(keyCombination: usage.shortcut)
                .frame(width: 100, alignment: .leading)

            // 应用
            Text(usage.application)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            // 使用次数
            Text("\(usage.count) 次")
                .font(.caption)
                .foregroundColor(.secondary)

            // 使用频率条
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: geometry.size.width * CGFloat(usage.count) / CGFloat(viewModel.maxUsageCount))
            }
            .frame(width: 100, height: 8)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(4)
    }

    // MARK: - Trend Chart Section

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("使用趋势")
                    .font(.headline)

                Spacer()

                // 数据收集状态提示
                if viewModel.trendData.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("需要开启使用统计追踪")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            if viewModel.trendData.isEmpty {
                VStack(spacing: 12) {
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // 详细说明
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("确保在设置中开启了\"使用统计追踪\"功能")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("使用快捷键后，系统会自动记录使用数据")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("数据将在次日开始显示趋势图")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(4)
                }
                .padding()
            } else {
                // 简单的折线图（使用条形图模拟）
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.trendData, id: \.date) { point in
                            VStack(spacing: 4) {
                                // 数值
                                Text("\(point.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                // 条形
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: CGFloat(point.count) / CGFloat(viewModel.maxTrendValue) * 150)

                                // 日期
                                Text(formatDate(point.date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func formatDate(_ dateString: String) -> String {
        // 简化日期显示（如：12-19）
        if let date = ISO8601DateFormatter().date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
        return dateString.suffix(5).description
    }

    // MARK: - Conflicts Section

    private var conflictsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高冲突快捷键")
                .font(.headline)

            if viewModel.conflictingShortcuts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("太棒了！当前没有冲突")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.conflictingShortcuts, id: \.self) { shortcut in
                        conflictRow(shortcut: shortcut)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func conflictRow(shortcut: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)

            Spacer()

            Button("查看详情") {
                // TODO: 显示冲突详情
            }
            .buttonStyle(.link)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(4)
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("优化建议")
                .font(.headline)

            if viewModel.suggestions.isEmpty {
                Text("暂无建议")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        suggestionRow(suggestion: suggestion)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func suggestionRow(suggestion: Suggestion) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // 图标 - 垂直居中
            Image(systemName: suggestion.icon)
                .foregroundColor(suggestion.color)
                .font(.system(size: 14))
                .frame(width: 20, height: 20)

            // 文字 - 左对齐，自动换行
            Text(suggestion.text)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(minHeight: 36)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(4)
    }
}

// MARK: - Statistics View Model

class StatisticsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var summary: StatisticsSummary = StatisticsSummary.empty
    @Published var trendData: [TrendPoint] = []
    @Published var conflictingShortcuts: [String] = []
    @Published var suggestions: [Suggestion] = []
    @Published var activeAppsCount: Int = 0

    // MARK: - Computed Properties

    var maxUsageCount: Int {
        max(summary.topShortcuts.first?.count ?? 1, 1)  // 确保永远不会返回0
    }

    var maxTrendValue: Int {
        max(trendData.map(\.count).max() ?? 1, 1)  // 确保永远不会返回0
    }

    // MARK: - Dependencies

    private let usageRepository = UsageRepository()
    private let conflictDetector = ConflictDetector()

    // MARK: - Public Methods

    func loadStatistics(for period: StatisticsPeriod) {
        // 加载统计摘要
        summary = usageRepository.aggregateStatistics(for: period)

        // 加载趋势数据
        loadTrendData(for: period)

        // 加载冲突快捷键
        loadConflictingShortcuts()

        // 生成优化建议
        generateSuggestions()

        // 计算活跃应用数
        calculateActiveAppsCount(for: period)
    }

    func exportStatistics() {
        // 创建保存面板
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "keymap-statistics-\(Date().timeIntervalSince1970).json"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                // 导出数据
                let data = try self.exportData()
                try data.write(to: url)

                // 显示成功通知
                self.showNotification(title: "导出成功", message: "统计数据已保存到 \(url.lastPathComponent)")
            } catch {
                print("❌ 导出统计数据失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private Methods

    private func loadTrendData(for period: StatisticsPeriod) {
        // 根据周期获取趋势数据
        let days: Int
        switch period {
        case .today:
            days = 1
        case .week:
            days = 7
        case .month:
            days = 30
        case .all:
            days = 365
        }
        trendData = usageRepository.getTrendData(days: days)
    }

    private func loadConflictingShortcuts() {
        // 从冲突检测器获取高冲突快捷键
        conflictingShortcuts = conflictDetector.getHighConflictShortcuts()
    }

    private func generateSuggestions() {
        suggestions = []

        // 建议1: 重映射功能使用
        let remappingManager = RemappingManager.shared
        let stats = remappingManager.getStatistics()
        let remappingCount = stats.totalRules

        if remappingCount == 0 && summary.totalUsage > 100 {
            suggestions.append(Suggestion(
                icon: "arrow.triangle.2.circlepath",
                color: .blue,
                text: "您还未使用快捷键重映射功能，可以将不常用的快捷键重映射为更顺手的组合"
            ))
        } else if remappingCount > 0 {
            suggestions.append(Suggestion(
                icon: "checkmark.circle.fill",
                color: .green,
                text: "您已创建 \(remappingCount) 个快捷键重映射，善于定制工作流程"
            ))
        }

        // 建议2: 快捷键多样性分析
        if !summary.topShortcuts.isEmpty && summary.topShortcuts.count >= 5 {
            let top5Usage = summary.topShortcuts.prefix(5).reduce(0) { $0 + $1.count }
            let totalUsage = summary.topShortcuts.reduce(0) { $0 + $1.count }
            let top5Percentage = totalUsage > 0 ? Double(top5Usage) / Double(totalUsage) * 100.0 : 0

            if top5Percentage >= 80 {
                suggestions.append(Suggestion(
                    icon: "chart.pie.fill",
                    color: .orange,
                    text: "您 \(String(format: "%.0f%%", top5Percentage)) 的操作集中在前5个快捷键，可以探索学习更多快捷键以提升效率"
                ))
            } else if top5Percentage < 60 {
                suggestions.append(Suggestion(
                    icon: "star.fill",
                    color: .yellow,
                    text: "您善于使用多样化的快捷键组合，快捷键使用分布均衡"
                ))
            }
        }

        // 建议3: 高冲突
        if summary.conflictCount > 10 {
            suggestions.append(Suggestion(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                text: "检测到 \(summary.conflictCount) 个冲突，建议解决高优先级冲突以避免误操作"
            ))
        } else if summary.conflictCount > 0 {
            suggestions.append(Suggestion(
                icon: "info.circle.fill",
                color: .blue,
                text: "发现 \(summary.conflictCount) 个冲突，建议及时处理避免误操作"
            ))
        }

        // 建议4: 无冲突率评分
        if summary.efficiencyScore < 70 {
            let conflictRate = 100.0 - summary.efficiencyScore
            suggestions.append(Suggestion(
                icon: "chart.bar.fill",
                color: .orange,
                text: "当前快捷键冲突率为 \(String(format: "%.1f%%", conflictRate))，建议优化快捷键配置以减少冲突"
            ))
        } else if summary.efficiencyScore >= 90 {
            suggestions.append(Suggestion(
                icon: "checkmark.shield.fill",
                color: .green,
                text: "您的快捷键无冲突率高达 \(String(format: "%.1f%%", summary.efficiencyScore))，所有操作顺利执行，保持良好习惯！"
            ))
        }

        // 建议5: 使用统计
        if summary.totalUsage == 0 {
            suggestions.append(Suggestion(
                icon: "paperplane.fill",
                color: .blue,
                text: "开始使用快捷键来提升工作效率吧！Keymap 会自动记录和分析您的使用习惯"
            ))
        } else if summary.totalUsage < 50 {
            suggestions.append(Suggestion(
                icon: "bolt.fill",
                color: .orange,
                text: "继续探索快捷键功能，目前已使用 \(summary.totalUsage) 次"
            ))
        } else if summary.totalUsage >= 1000 {
            suggestions.append(Suggestion(
                icon: "trophy.fill",
                color: .yellow,
                text: "您已经使用快捷键 \(summary.totalUsage) 次，是一位快捷键高手！"
            ))
        }

        // 建议6: 应用覆盖度
        if activeAppsCount >= 5 {
            suggestions.append(Suggestion(
                icon: "app.badge.checkmark.fill",
                color: .purple,
                text: "您在 \(activeAppsCount) 个应用中使用了快捷键，善于利用工具提升效率"
            ))
        } else if activeAppsCount > 0 && activeAppsCount < 3 && summary.totalUsage > 50 {
            suggestions.append(Suggestion(
                icon: "app.dashed",
                color: .blue,
                text: "您主要在 \(activeAppsCount) 个应用中使用快捷键，可以尝试在更多常用应用中探索快捷键功能"
            ))
        }

        print("📊 生成了 \(suggestions.count) 条建议")
    }

    private func calculateActiveAppsCount(for period: StatisticsPeriod) {
        activeAppsCount = usageRepository.getActiveAppsCount(for: period)
    }

    private func exportData() throws -> Data {
        let exportData: [String: Any] = [
            "summary": [
                "totalUsage": summary.totalUsage,
                "conflictCount": summary.conflictCount,
                "efficiencyScore": summary.efficiencyScore,
                "timeRange": "\(summary.timeRange.start) - \(summary.timeRange.end)"
            ],
            "topShortcuts": summary.topShortcuts.map { [
                "shortcut": $0.shortcut,
                "application": $0.application,
                "count": $0.count
            ]},
            "trendData": trendData.map { [
                "date": $0.date,
                "count": $0.count
            ]},
            "conflicts": conflictingShortcuts,
            "suggestions": suggestions,
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]

        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }

    private func showNotification(title: String, message: String) {
        NotificationHelper.shared.send(title: title, message: message)
    }
}

// MARK: - Supporting Types

struct TrendPoint {
    let date: String
    let count: Int
}

struct Suggestion: Hashable {
    let icon: String
    let color: Color
    let text: String
}

extension StatisticsSummary {
    static var empty: StatisticsSummary {
        StatisticsSummary(
            totalUsage: 0,
            conflictCount: 0,
            efficiencyScore: 0,
            topShortcuts: [],
            timeRange: DateInterval(start: Date(), end: Date())
        )
    }
}

// MARK: - Repository Extensions

extension UsageRepository {

    func getTrendData(days: Int) -> [TrendPoint] {
        // 获取最近N天的每日使用趋势
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        var trendPoints: [TrendPoint] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }

            let dateString = ISO8601DateFormatter().string(from: date)
            let count = getDailyUsageCount(for: date)

            // 只添加有数据的点
            if count > 0 {
                trendPoints.append(TrendPoint(date: dateString, count: count))
            }
        }

        print("📈 趋势数据点数量: \(trendPoints.count)")
        return trendPoints
    }

    func getDailyUsageCount(for date: Date) -> Int {
        // 从 statistics_summary 表获取当天的使用次数
        let db = DatabaseManager.shared
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let sql = """
        SELECT SUM(usage_count) as total
        FROM statistics_summary
        WHERE date = '\(dateString)'
        """

        let results = db.executeQuery(sql)
        if let first = results.first, let total = first["total"] as? Int {
            print("📅 日期 \(dateString) 使用次数: \(total)")
            return total
        }

        print("📅 日期 \(dateString) 无数据")
        return 0
    }

    func getActiveAppsCount(for period: StatisticsPeriod) -> Int {
        // 获取活跃应用数量
        let db = DatabaseManager.shared
        let (startDate, endDate) = getPeriodDateRange(period)

        let sql = """
        SELECT COUNT(DISTINCT bundle_id) as count
        FROM usage_records
        WHERE timestamp >= \(startDate.timeIntervalSince1970) AND timestamp <= \(endDate.timeIntervalSince1970)
        """

        let results = db.executeQuery(sql)
        if let first = results.first, let count = first["count"] as? Int64 {
            print("📱 活跃应用数: \(count)")
            return Int(count)
        }

        print("⚠️ 无法获取活跃应用数")
        return 0
    }

    private func getPeriodDateRange(_ period: StatisticsPeriod) -> (Date, Date) {
        let calendar = Calendar.current
        let endDate = Date()

        var startDate: Date

        switch period {
        case .today:
            startDate = calendar.startOfDay(for: endDate)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .all:
            startDate = Date(timeIntervalSince1970: 0)
        }

        return (startDate, endDate)
    }
}

extension ConflictDetector {

    func getHighConflictShortcuts() -> [String] {
        // 获取高冲突快捷键列表
        let db = DatabaseManager.shared

        // 查询严重程度为 high 或 medium 的冲突，按出现次数排序
        let sql = """
        SELECT c.shortcut_id, s.key_combination, COUNT(*) as conflict_count
        FROM conflicts c
        JOIN shortcuts s ON c.shortcut_id = s.id
        WHERE c.severity IN ('high', 'medium')
        GROUP BY c.shortcut_id, s.key_combination
        HAVING conflict_count >= 2
        ORDER BY conflict_count DESC
        LIMIT 10;
        """

        let rows = db.executeQuery(sql)
        let shortcuts = rows.compactMap { row -> String? in
            return row["key_combination"] as? String
        }

        print("📊 高冲突快捷键数量: \(shortcuts.count)")
        return shortcuts
    }
}
