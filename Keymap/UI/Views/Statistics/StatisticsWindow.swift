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
    private var viewModel: StatisticsViewModel?

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
        title = "window.statistics".localized()
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
        let viewModel = StatisticsViewModel()
        let statisticsView = StatisticsView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: statisticsView)

        contentView = hostingView
        self.hostingView = hostingView
        self.viewModel = viewModel
    }

    // MARK: - Public Methods

    func showWindow() {
        // 显示窗口并确保在最前
        makeKeyAndOrderFront(nil)

        // 激活应用
        NSApp.activate(ignoringOtherApps: true)
        
        // 刷新数据
        viewModel?.refresh()
    }
}

// MARK: - Statistics View

struct StatisticsView: View {

    // MARK: - State

    @Environment(\.colorScheme) var colorScheme  // 检测深色/浅色模式
    @ObservedObject var viewModel: StatisticsViewModel
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
                    (StatisticsPeriod.today, "statistics.period.today".localized()),
                    (StatisticsPeriod.week, "statistics.period.week".localized()),
                    (StatisticsPeriod.month, "statistics.period.month".localized()),
                    (StatisticsPeriod.all, "statistics.period.all".localized())
                ], id: \.0) { period, title in
                    Button(action: {
                        selectedPeriod = period
                        viewModel.loadStatistics(for: period)
                    }) {
                        Text(title)
                            .font(.body)
                            .fontWeight(selectedPeriod == period ? .semibold : .regular)
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .padding(.horizontal, 12)
                            .frame(height: 28)
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
                    Text("statistics.refresh".localized())
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
                    Text("statistics.export".localized())
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
            Text("statistics.overview".localized())
                .font(.headline)

            HStack(spacing: 20) {
                // 总使用次数
                AnimatedStatisticCard(
                    title: "statistics.card.total_usage".localized(),
                    targetValue: viewModel.summary.totalUsage,
                    icon: "hand.tap.fill",
                    color: .blue,
                    isAnimating: viewModel.isAnimating
                )

                // 冲突次数
                AnimatedStatisticCard(
                    title: "statistics.card.conflict_count".localized(),
                    targetValue: viewModel.summary.conflictCount,
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    isAnimating: viewModel.isAnimating
                )

                // 无冲突率
                AnimatedStatisticCard(
                    title: "statistics.card.efficiency_rate".localized(),
                    targetValue: Int(viewModel.summary.efficiencyScore * 10),
                    icon: "checkmark.shield.fill",
                    color: .green,
                    isAnimating: viewModel.isAnimating,
                    isPercentage: true
                )

                // 活跃应用数
                AnimatedStatisticCard(
                    title: "statistics.card.active_apps".localized(),
                    targetValue: viewModel.activeAppsCount,
                    icon: "app.fill",
                    color: .purple,
                    isAnimating: viewModel.isAnimating
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }



    // MARK: - Top Shortcuts Section

    private var topShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("statistics.top_shortcuts".localized())
                .font(.headline)

            if viewModel.summary.topShortcuts.isEmpty {
                Text("statistics.no_data".localized())
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
            Text(String(format: "statistics.count_times".localized(), usage.count))
                .font(.caption)
                .foregroundColor(.secondary)

            // 使用频率条 - 带动画
            AnimatedProgressBar(
                progress: CGFloat(usage.count) / CGFloat(viewModel.maxUsageCount),
                isAnimating: viewModel.isAnimating
            )
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
                Text("statistics.usage_trend".localized())
                    .font(.headline)

                Spacer()

                // 数据收集状态提示
                if viewModel.trendData.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("statistics.tracking_disabled".localized())
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            if viewModel.trendData.isEmpty {
                VStack(spacing: 12) {
                    Text("statistics.no_data".localized())
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
                            Text("statistics.tracking_hint_2".localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("statistics.tracking_hint_3".localized())
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
                            AnimatedBarView(
                                value: point.count,
                                maxValue: viewModel.maxTrendValue,
                                date: formatDate(point.date),
                                isAnimating: viewModel.isAnimating
                            )
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
            Text("statistics.high_conflict_shortcuts".localized())
                .font(.headline)

            if viewModel.conflictingShortcuts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("statistics.no_conflicts".localized())
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

            Button("button.view_details".localized()) {
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
            Text("statistics.optimization_suggestions".localized())
                .font(.headline)

            if viewModel.suggestions.isEmpty {
                Text("statistics.no_suggestions".localized())
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
    @Published var isAnimating: Bool = false
    
    // 当前选择的时间周期
    var currentPeriod: StatisticsPeriod = .today

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
        // 记录当前周期
        currentPeriod = period
        
        let periodName: String
        switch period {
        case .today: periodName = "statistics.period.today".localized()
        case .week: periodName = "statistics.period.week".localized()  
        case .month: periodName = "statistics.period.month".localized()
        case .all: periodName = "statistics.period.all".localized()
        }
        print("🔄 ViewModel.loadStatistics 被调用，周期: \(periodName)")
        
        // 加载统计数据
        summary = usageRepository.aggregateStatistics(for: period)
        print("🔄 加载完成，总使用次数: \(summary.totalUsage)")
        
        loadTrendData(for: period)
        loadConflictingShortcuts()
        generateSuggestions()
        calculateActiveAppsCount(for: period)
        
        // 触发动画 - 先重置再触发，确保onChange被调用
        isAnimating = false
        DispatchQueue.main.async {
            self.isAnimating = true
            
            // 1秒后重置动画状态（允许再次触发）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isAnimating = false
            }
        }
    }
    
    /// 刷新当前数据（使用当前周期）
    func refresh() {
        loadStatistics(for: currentPeriod)
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
                text: "statistics.suggestion.no_remapping".localized()
            ))
        } else if remappingCount > 0 {
            suggestions.append(Suggestion(
                icon: "checkmark.circle.fill",
                color: .green,
                text: String(format: "statistics.suggestion.remapping_enabled".localized(), remappingCount)
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
                    text: String(format: "statistics.suggestion.usage_concentrated".localized(), top5Percentage)
                ))
            } else if top5Percentage < 60 {
                suggestions.append(Suggestion(
                    icon: "star.fill",
                    color: .yellow,
                    text: "statistics.suggestion.diverse_usage".localized()
                ))
            }
        }

        // 建议3: 高冲突
        if summary.conflictCount > 10 {
            suggestions.append(Suggestion(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                text: String(format: "statistics.suggestion.high_conflicts".localized(), summary.conflictCount)
            ))
        } else if summary.conflictCount > 0 {
            suggestions.append(Suggestion(
                icon: "info.circle.fill",
                color: .blue,
                text: String(format: "statistics.suggestion.some_conflicts".localized(), summary.conflictCount)
            ))
        }

        // 建议4: 无冲突率评分
        if summary.efficiencyScore < 70 {
            let conflictRate = 100.0 - summary.efficiencyScore
            suggestions.append(Suggestion(
                icon: "chart.bar.fill",
                color: .orange,
                text: String(format: "statistics.suggestion.conflict_rate_high".localized(), conflictRate)
            ))
        } else if summary.efficiencyScore >= 90 {
            suggestions.append(Suggestion(
                icon: "checkmark.shield.fill",
                color: .green,
                text: String(format: "statistics.suggestion.efficiency_excellent".localized(), summary.efficiencyScore)
            ))
        }

        // 建议5: 使用统计
        if summary.totalUsage == 0 {
            suggestions.append(Suggestion(
                icon: "paperplane.fill",
                color: .blue,
                text: "statistics.suggestion.start_using".localized()
            ))
        } else if summary.totalUsage < 50 {
            suggestions.append(Suggestion(
                icon: "bolt.fill",
                color: .orange,
                text: String(format: "statistics.suggestion.continuing_usage".localized(), summary.totalUsage)
            ))
        } else if summary.totalUsage >= 1000 {
            suggestions.append(Suggestion(
                icon: "trophy.fill",
                color: .yellow,
                text: String(format: "statistics.suggestion.power_user".localized(), summary.totalUsage)
            ))
        }

        // 建议6: 应用覆盖度
        if activeAppsCount >= 5 {
            suggestions.append(Suggestion(
                icon: "app.badge.checkmark.fill",
                color: .purple,
                text: String(format: "statistics.suggestion.multi_app_user".localized(), activeAppsCount)
            ))
        } else if activeAppsCount > 0 && activeAppsCount < 3 && summary.totalUsage > 50 {
            suggestions.append(Suggestion(
                icon: "app.dashed",
                color: .blue,
                text: String(format: "statistics.suggestion.explore_more_apps".localized(), activeAppsCount)
            ))
        }

        print("📊 生成了 \(suggestions.count) 条建议")
    }

    private func calculateActiveAppsCount(for period: StatisticsPeriod) {
        activeAppsCount = usageRepository.getActiveAppsCount(for: period)
    }

    private func exportData() throws -> Data {
        // 手动构建 JSON 以确保严格的顺序控制
        var jsonString = "{\n"

        // 1. 导出日期
        let dateFormatter = ISO8601DateFormatter()
        jsonString += "  \"exportDate\" : \"\(dateFormatter.string(from: Date()))\",\n"

        // 2. 概览
        jsonString += "  \"summary\" : {\n"
        jsonString += "    \"totalUsage\" : \(summary.totalUsage),\n"
        jsonString += "    \"conflictCount\" : \(summary.conflictCount),\n"
        jsonString += "    \"efficiencyScore\" : \(summary.efficiencyScore),\n"
        jsonString += "    \"timeRange\" : \"\(summary.timeRange.start) - \(summary.timeRange.end)\"\n"
        jsonString += "  },\n"

        // 3. 使用频率排行
        jsonString += "  \"topShortcuts\" : [\n"
        for (index, shortcut) in summary.topShortcuts.enumerated() {
            jsonString += "    {\n"
            jsonString += "      \"shortcut\" : \"\(escapeJSON(shortcut.shortcut))\",\n"
            jsonString += "      \"application\" : \"\(escapeJSON(shortcut.application))\",\n"
            jsonString += "      \"count\" : \(shortcut.count)\n"
            jsonString += "    }"
            jsonString += (index < summary.topShortcuts.count - 1) ? ",\n" : "\n"
        }
        jsonString += "  ],\n"

        // 4. 使用趋势
        jsonString += "  \"trendData\" : [\n"
        for (index, trend) in trendData.enumerated() {
            jsonString += "    {\n"
            jsonString += "      \"date\" : \"\(trend.date)\",\n"
            jsonString += "      \"count\" : \(trend.count)\n"
            jsonString += "    }"
            jsonString += (index < trendData.count - 1) ? ",\n" : "\n"
        }
        jsonString += "  ],\n"

        // 5. 高冲突快捷键
        jsonString += "  \"conflicts\" : [\n"
        for (index, conflict) in conflictingShortcuts.enumerated() {
            jsonString += "    \"\(escapeJSON(conflict))\""
            jsonString += (index < conflictingShortcuts.count - 1) ? ",\n" : "\n"
        }
        jsonString += "  ],\n"

        // 6. 优化建议
        jsonString += "  \"suggestions\" : [\n"
        for (index, suggestion) in suggestions.enumerated() {
            jsonString += "    {\n"
            jsonString += "      \"icon\" : \"\(escapeJSON(suggestion.icon))\",\n"
            jsonString += "      \"text\" : \"\(escapeJSON(suggestion.text))\"\n"
            jsonString += "    }"
            jsonString += (index < suggestions.count - 1) ? ",\n" : "\n"
        }
        jsonString += "  ]\n"

        jsonString += "}"

        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "Keymap", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法生成 JSON 数据"])
        }

        return data
    }

    /// 转义 JSON 字符串中的特殊字符
    private func escapeJSON(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
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
        // 获取最近N天的每日使用趋势（包括今天）
        let calendar = Calendar.current
        let endDate = Date()
        // 修正：包括今天，所以startDate应该往前推days-1天
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate)!

        var trendPoints: [TrendPoint] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }

            // 使用统一的日期格式器
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
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
        // 从 usage_records 表获取当天的使用次数（与概览统计一致，避免数据不同步）
        let db = DatabaseManager.shared
        let calendar = Calendar.current
        
        // 获取当天的开始和结束时间戳
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTimestamp = Int64(startOfDay.timeIntervalSince1970)
        let endTimestamp = Int64(endOfDay.timeIntervalSince1970)
        
        let sql = """
        SELECT COUNT(*) as count
        FROM usage_records
        WHERE timestamp >= \(startTimestamp) AND timestamp < \(endTimestamp)
        """
        
        let results = db.executeQuery(sql)
        if let first = results.first, let count = first["count"] as? Int64 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            print("📅 日期 \(dateString) 使用次数: \(count)")
            return Int(count)
        }
        
        print("📅 日期 \(date) 无数据")
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

// MARK: - Animated Components

/// 带数字滚动动画的统计卡片
struct AnimatedStatisticCard: View {
    let title: String
    let targetValue: Int
    let icon: String
    let color: Color
    let isAnimating: Bool
    var isPercentage: Bool = false
    
    @State private var displayValue: Int = 0
    @State private var animationTimer: Timer?
    @State private var pendingTargetValue: Int = 0  // 缓存待使用的目标值
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(formattedValue)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(6)
        .onChange(of: targetValue) { _, newValue in
            // 立即缓存新的目标值
            pendingTargetValue = newValue
            print("🔄 AnimatedStatisticCard[\(title)]: targetValue changed to \(newValue), cached as pendingTargetValue")

            // 如果不在动画中，直接更新显示值
            if !isAnimating {
                displayValue = newValue
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                // isAnimating 变为 true 时，使用缓存的目标值开始动画
                print("🎬 AnimatedStatisticCard[\(title)]: isAnimating=true, starting animation with pendingTarget=\(pendingTargetValue)")
                startAnimation(target: pendingTargetValue)
            }
        }
        .onAppear {
            // 首次显示时直接设置目标值和缓存值
            print("👀 AnimatedStatisticCard[\(title)]: onAppear, targetValue=\(targetValue)")
            pendingTargetValue = targetValue
            displayValue = targetValue
        }
        .onDisappear {
            // 清理定时器
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    private var formattedValue: String {
        if isPercentage {
            return String(format: "%.1f%%", Double(displayValue) / 10.0)
        } else {
            return "\(displayValue)"
        }
    }
    
    private func startAnimation(target: Int) {
        // 取消旧动画
        animationTimer?.invalidate()
        animationTimer = nil
        
        print("▶️ AnimatedStatisticCard[\(title)]: 开始动画 target=\(target)")
        
        // 重置为0开始动画
        displayValue = 0
        
        // 计算动画步数和间隔
        let duration: TimeInterval = 0.8  // 总动画时长
        let steps = 30  // 动画步数
        let stepDuration = duration / Double(steps)
        
        // 使用Timer逐步增加数值
        var currentStep = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            
            if currentStep >= steps {
                displayValue = target
                timer.invalidate()
                animationTimer = nil
                print("✅ AnimatedStatisticCard[\(title)]: 动画完成 displayValue=\(target)")
            } else {
                let progress = Double(currentStep) / Double(steps)
                // 使用easeOut曲线：开始快，结束慢
                let easedProgress = 1 - pow(1 - progress, 3)
                displayValue = Int(Double(target) * easedProgress)
            }
        }
    }
}

/// 带动画的进度条（从左到右增长）
struct AnimatedProgressBar: View {
    let progress: CGFloat
    let isAnimating: Bool
    
    @State private var animatedProgress: CGFloat = 0
    @State private var pendingProgress: CGFloat = 0  // 缓存待使用的进度
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: geometry.size.width * animatedProgress)
        }
        .onChange(of: progress) { _, newValue in
            // 立即缓存新的目标进度
            pendingProgress = newValue

            // 如果不在动画中，直接更新显示进度
            if !isAnimating {
                animatedProgress = newValue
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                // isAnimating 变为 true 时，使用缓存的目标值开始动画
                animateProgress()
            }
        }
        .onAppear {
            // 首次显示时直接设置目标进度和缓存值
            pendingProgress = progress
            animatedProgress = progress
        }
    }
    
    private func animateProgress() {
        // 重置进度为0
        animatedProgress = 0
        
        // 使用动画增长到缓存的目标进度
        withAnimation(.easeOut(duration: 0.8)) {
            animatedProgress = pendingProgress
        }
    }
}

/// 带生长动画的柱状图条
struct AnimatedBarView: View {
    let value: Int
    let maxValue: Int
    let date: String
    let isAnimating: Bool
    
    @State private var animatedHeight: CGFloat = 0
    @State private var pendingHeight: CGFloat = 0  // 缓存待使用的目标高度
    
    private let maxBarHeight: CGFloat = 150
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部数值和柱状图区域（固定高度）
            VStack(spacing: 4) {
                // 数值（固定在柱状图上方）
                Text("\(value)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(animatedHeight > 0 ? 1 : 0)
                    .frame(height: 16)  // 固定高度避免布局跳动
                
                // 柱状图容器（固定高度 = maxBarHeight）
                VStack {
                    Spacer(minLength: 0)  // 顶部弹性空间
                    
                    // 条形（从底部向上增长）
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 40, height: animatedHeight)
                }
                .frame(height: maxBarHeight)  // 固定容器高度
            }
            
            // 日期
            Text(date)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(height: 16)  // 固定高度
        }
        .onChange(of: targetHeight) { _, newValue in
            // 立即缓存新的目标高度
            pendingHeight = newValue

            // 如果不在动画中，直接更新显示高度
            if !isAnimating {
                animatedHeight = newValue
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                // isAnimating 变为 true 时，使用缓存的目标值开始动画
                animateBar()
            }
        }
        .onAppear {
            // 首次显示时直接设置目标高度和缓存值
            pendingHeight = targetHeight
            animatedHeight = targetHeight
        }
    }
    
    private var targetHeight: CGFloat {
        return CGFloat(value) / CGFloat(max(maxValue, 1)) * maxBarHeight
    }
    
    private func animateBar() {
        // 重置高度为0
        animatedHeight = 0
        
        // 使用动画增长到缓存的目标高度
        withAnimation(.easeOut(duration: 0.8)) {
            animatedHeight = pendingHeight
        }
    }
}
