//
//  SettingsWindow.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import SwiftUI
import AppKit

/// 设置窗口
class SettingsWindow: NSWindow {

    // MARK: - Properties

    private var hostingView: NSHostingView<SettingsView>?

    // MARK: - Initialization

    init() {
        // 窗口配置
        let contentRect = NSRect(x: 0, y: 0, width: 600, height: 500)

        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
    }

    // MARK: - Setup

    private func setupWindow() {
        title = "设置"
        center()
        isReleasedWhenClosed = false

        // 设置窗口固定尺寸
        minSize = NSSize(width: 600, height: 500)
        maxSize = NSSize(width: 600, height: 500)

        // 设置窗口级别（普通窗口级别，但确保能置顶）
        level = .normal

        // 确保窗口可以成为主窗口
        collectionBehavior = [.managed, .fullScreenPrimary]
    }

    private func setupContent() {
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)

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

// MARK: - Settings View

struct SettingsView: View {

    // MARK: - State

    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedTab: SettingsTab = .general

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // 侧边栏
            sidebarView
                .frame(width: 150)
                .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // 内容区域
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 600, height: 500)
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: tab.icon)
                            .frame(width: 20, alignment: .center)
                        Text(tab.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }

            Spacer()
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .general:
            generalSettingsView
        case .shortcuts:
            shortcutSettingsView
        case .data:
            dataSettingsView
        case .advanced:
            advancedSettingsView
        case .about:
            aboutView
        }
    }

    // MARK: - General Settings

    private var generalSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("通用设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                    .padding(.top, 16)

                // 开机自动启动
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("开机自动启动")
                            .font(.body)
                        Text("应用将在系统启动时自动运行")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.launchAtLogin)
                        .toggleStyle(.switch)
                        .onChange(of: viewModel.launchAtLogin) { _, newValue in
                            viewModel.updateLaunchAtLogin(newValue)
                        }
                }

                Divider()

                // 在Dock显示图标
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("在Dock显示图标")
                            .font(.body)
                        Text("关闭后应用仅在菜单栏显示")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.showInDock)
                        .toggleStyle(.switch)
                        .onChange(of: viewModel.showInDock) { _, newValue in
                            viewModel.settings.showInDock = newValue
                        }
                }

                Divider()

                // 实时冲突检测
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("启用实时冲突检测")
                            .font(.body)
                        Text("在使用快捷键时实时检测并提示冲突")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.enableRealTimeDetection)
                        .toggleStyle(.switch)
                }

                Divider()

                // 使用统计追踪
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("启用使用统计追踪")
                            .font(.body)
                        Text("记录快捷键使用情况以提供统计分析")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.enableUsageTracking)
                        .toggleStyle(.switch)
                }

                Divider()

                // 冲突通知
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("显示冲突通知")
                            .font(.body)
                        Text("检测到冲突时显示系统通知")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.showConflictNotifications)
                        .toggleStyle(.switch)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 16)
    }

    // MARK: - Shortcut Settings

    private var shortcutSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("快捷键设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                    .padding(.top, 16)

                // 双击Cmd阈值
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("双击Cmd阈值")
                        Spacer()
                        Text(String(format: "%.2f 秒", viewModel.doubleCmdThreshold))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $viewModel.doubleCmdThreshold, in: 0.1...1.0, step: 0.05)
                        .accentColor(.blue)

                    Text("调整双击Cmd键的灵敏度（越小越灵敏）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // 触发快捷键选择
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("触发快捷键")
                            .font(.body)
                        Text("选择触发快捷键面板的方式")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $viewModel.triggerKey) {
                        Text("双击Cmd").tag("doubleCmd")
                        Text("双击Option").tag("doubleOption")
                        Text("双击Control").tag("doubleControl")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                Divider()

                // 面板显示时长
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("面板自动关闭延迟")
                        Spacer()
                        Text(viewModel.panelAutoCloseDelay == 0 ? "从不" : "\(Int(viewModel.panelAutoCloseDelay)) 秒")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $viewModel.panelAutoCloseDelay, in: 0...30, step: 5)
                        .accentColor(.blue)

                    Text("设置为0则不自动关闭")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 16)
    }

    // MARK: - Data Settings

    private var dataSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("数据管理")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                    .padding(.top, 16)

                // 缓存设置
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("缓存时长")
                        Spacer()
                        Text("\(viewModel.cacheDuration) 小时")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(viewModel.cacheDuration) },
                        set: { viewModel.cacheDuration = Int($0) }
                    ), in: 1...72, step: 1)
                    .accentColor(.blue)

                    Text("快捷键提取结果的缓存有效期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // 最大缓存应用数
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("最大缓存应用数")
                        Spacer()
                        Text("\(viewModel.maxCachedApps) 个")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(viewModel.maxCachedApps) },
                        set: { viewModel.maxCachedApps = Int($0) }
                    ), in: 10...100, step: 10)
                    .accentColor(.blue)

                    Text("内存中最多缓存的应用数量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // 清理旧数据
                VStack(alignment: .leading, spacing: 8) {
                    Text("清理旧数据")

                    HStack(spacing: 12) {
                        Button("清除缓存") {
                            viewModel.clearCache()
                        }

                        Button("清除使用记录") {
                            viewModel.clearUsageRecords()
                        }

                        Button("清除所有数据") {
                            viewModel.clearAllData()
                        }
                        .foregroundColor(.red)
                    }

                    Text("清除操作不可恢复，请谨慎操作")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Divider()

                // 导出/导入
                VStack(alignment: .leading, spacing: 8) {
                    Text("导出/导入")

                    HStack(spacing: 12) {
                        Button("导出重映射规则") {
                            viewModel.exportRemappings()
                        }

                        Button("导入重映射规则") {
                            viewModel.importRemappings()
                        }

                        Button("导出设置") {
                            viewModel.exportSettings()
                        }
                    }

                    Text("可以备份并在其他设备上使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // 数据库信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("数据库信息")
                        .font(.headline)

                    HStack {
                        Text("数据库大小:")
                        Text(viewModel.databaseSize)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("使用记录数:")
                        Text("\(viewModel.usageRecordsCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("快捷键数:")
                        Text("\(viewModel.shortcutsCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 16)
    }

    // MARK: - Advanced Settings

    private var advancedSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("高级设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                    .padding(.top, 16)

                // 日志级别
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("日志级别")
                            .font(.body)
                        Text("设置控制台日志的详细程度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $viewModel.logLevel) {
                        Text("关闭").tag(0)
                        Text("错误").tag(1)
                        Text("警告").tag(2)
                        Text("信息").tag(3)
                        Text("调试").tag(4)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }

                Divider()

                // 性能监控
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("启用性能监控")
                            .font(.body)
                        Text("监控CPU和内存使用情况（可能影响性能）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.enablePerformanceMonitoring)
                        .toggleStyle(.switch)
                }

                Divider()

                // 实验性功能
                VStack(alignment: .leading, spacing: 12) {
                    Text("实验性功能")
                        .font(.headline)

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("全局快捷键重映射")
                                .font(.body)
                            Text("⚠️ 实验性功能，可能不稳定")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.enableGlobalRemapping)
                            .toggleStyle(.switch)
                    }

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("快捷键录制模式")
                                .font(.body)
                            Text("⚠️ 允许录制自定义快捷键")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.enableRecordingMode)
                            .toggleStyle(.switch)
                    }
                }

                Divider()

                // 重置设置
                VStack(alignment: .leading, spacing: 8) {
                    Text("重置")
                        .font(.headline)

                    Button("重置所有设置") {
                        viewModel.resetAllSettings()
                    }
                    .foregroundColor(.red)

                    Text("将所有设置恢复为默认值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 16)
    }

    // MARK: - About View

    private var aboutView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo和名称
                VStack(spacing: 12) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                            .cornerRadius(16)
                    } else {
                        Image(systemName: "keyboard")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                    }

                    Text("Keymap")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("一个适用于macOS平台的快捷键冲突检测与管理工具")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 16)

                Divider()
                    .padding(.horizontal, 40)

                // 版本信息
                VStack(spacing: 8) {
                    HStack {
                        Text("版本:")
                            .foregroundColor(.secondary)
                        Text("1.0.0 (Build 1)")
                    }

                    HStack {
                        Text("系统要求:")
                            .foregroundColor(.secondary)
                        Text("macOS 14.0+")
                    }
                }

                Divider()
                    .padding(.horizontal, 40)

                // 版权信息
                VStack(spacing: 8) {
                    Text("Copyright 2025 David Lan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
    }
}

// MARK: - Settings Tab

enum SettingsTab: CaseIterable {
    case general
    case shortcuts
    case data
    case advanced
    case about

    var title: String {
        switch self {
        case .general: return "通用"
        case .shortcuts: return "快捷键"
        case .data: return "数据"
        case .advanced: return "高级"
        case .about: return "关于"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "keyboard"
        case .data: return "externaldrive"
        case .advanced: return "hammer"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Settings View Model

class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    // 通用设置
    @Published var launchAtLogin: Bool = false
    @Published var showInDock: Bool = true
    @Published var enableRealTimeDetection: Bool = true
    @Published var enableUsageTracking: Bool = true
    @Published var showConflictNotifications: Bool = true

    // 快捷键设置
    @Published var doubleCmdThreshold: Double = 0.3
    @Published var triggerKey: String = "doubleCmd"
    @Published var panelAutoCloseDelay: Double = 0

    // 数据设置
    @Published var cacheDuration: Int = 24
    @Published var maxCachedApps: Int = 50

    // 高级设置
    @Published var logLevel: Int = 2
    @Published var enablePerformanceMonitoring: Bool = false
    @Published var enableGlobalRemapping: Bool = false
    @Published var enableRecordingMode: Bool = false

    // 数据库信息
    @Published var databaseSize: String = "计算中..."
    @Published var usageRecordsCount: Int = 0
    @Published var shortcutsCount: Int = 0

    // MARK: - Dependencies

    let settings = SettingsManager.shared
    private let remappingManager = RemappingManager.shared
    private let databaseManager = DatabaseManager.shared

    // MARK: - Initialization

    init() {
        loadSettings()
        loadDatabaseInfo()
    }

    // MARK: - Public Methods

    func updateLaunchAtLogin(_ enabled: Bool) {
        // 实现开机自动启动
        // 需要使用 SMLoginItemSetEnabled 或 ServiceManagement framework
        print(enabled ? "✅ 启用开机自动启动" : "❌ 禁用开机自动启动")
    }

    func clearCache() {
        let alert = NSAlert()
        alert.messageText = "确认清除缓存？"
        alert.informativeText = "这将清除所有应用快捷键的缓存数据"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            // 清除缓存
            UserDefaults.standard.removeObject(forKey: "shortcut_cache")
            showNotification(title: "缓存已清除", message: "快捷键缓存已全部清除")
        }
    }

    func clearUsageRecords() {
        let alert = NSAlert()
        alert.messageText = "确认清除使用记录？"
        alert.informativeText = "这将删除所有快捷键使用统计数据"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            // 清除使用记录
            let sql = "DELETE FROM usage_records"
            if databaseManager.executeUpdate(sql, parameters: []) {
                showNotification(title: "使用记录已清除", message: "所有使用统计数据已删除")
                loadDatabaseInfo()
            }
        }
    }

    func clearAllData() {
        let alert = NSAlert()
        alert.messageText = "确认清除所有数据？"
        alert.informativeText = "这将删除所有数据，包括缓存、使用记录、重映射规则等。此操作不可恢复！"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            // 清除所有数据
            clearCache()
            remappingManager.clearAllRemappings()

            let tables = ["usage_records", "statistics_summary", "conflicts", "shortcuts", "applications"]
            for table in tables {
                let sql = "DELETE FROM \(table)"
                _ = databaseManager.executeUpdate(sql, parameters: [])
            }

            showNotification(title: "所有数据已清除", message: "应用数据已全部删除")
            loadDatabaseInfo()
        }
    }

    func exportRemappings() {
        guard let data = remappingManager.exportRemappings() else {
            showAlert(title: "导出失败", message: "无法导出重映射规则")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "keymap-remappings.json"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                try data.write(to: url)
                self.showNotification(title: "导出成功", message: "重映射规则已保存")
            } catch {
                self.showAlert(title: "导出失败", message: error.localizedDescription)
            }
        }
    }

    func importRemappings() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            guard response == .OK, let url = openPanel.url else { return }

            do {
                let data = try Data(contentsOf: url)
                let (success, failed) = self.remappingManager.importRemappings(data)
                self.showNotification(
                    title: "导入完成",
                    message: "成功导入 \(success) 条规则，失败 \(failed) 条"
                )
            } catch {
                self.showAlert(title: "导入失败", message: error.localizedDescription)
            }
        }
    }

    func exportSettings() {
        let settingsData = settings.exportSettings()

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "keymap-settings.json"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                let data = try JSONSerialization.data(withJSONObject: settingsData, options: .prettyPrinted)
                try data.write(to: url)
                self.showNotification(title: "导出成功", message: "设置已保存")
            } catch {
                self.showAlert(title: "导出失败", message: error.localizedDescription)
            }
        }
    }

    func resetAllSettings() {
        let alert = NSAlert()
        alert.messageText = "确认重置所有设置？"
        alert.informativeText = "这将恢复所有设置为默认值"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            settings.resetToDefaults()
            loadSettings()
            showNotification(title: "设置已重置", message: "所有设置已恢复为默认值")
        }
    }

    func showLicenses() {
        showAlert(
            title: "开源许可",
            message: """
            Apache License 2.0

            Copyright 2025 David Lan. Licensed under Apache-2.0.

            Licensed under the Apache License, Version 2.0 (the "License");
            you may not use this file except in compliance with the License.
            You may obtain a copy of the License at

                http://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software
            distributed under the License is distributed on an "AS IS" BASIS,
            WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            See the License for the specific language governing permissions and
            limitations under the License.
            """
        )
    }

    // MARK: - Private Methods

    private func loadSettings() {
        // 从 SettingsManager 加载设置
        doubleCmdThreshold = settings.doubleCmdThreshold
        triggerKey = settings.triggerKey
        showInDock = settings.showInDock
        enableRealTimeDetection = settings.enableRealTimeDetection
        enableUsageTracking = settings.enableUsageTracking
        cacheDuration = settings.cacheDuration
        maxCachedApps = settings.maxCachedApps

        // 监听设置变化
        observeSettings()
    }

    private func observeSettings() {
        // 通用设置
        $enableRealTimeDetection.sink { newValue in
            self.settings.enableRealTimeDetection = newValue
        }.store(in: &cancellables)

        $enableUsageTracking.sink { newValue in
            self.settings.enableUsageTracking = newValue
        }.store(in: &cancellables)

        // 快捷键设置
        $doubleCmdThreshold.sink { newValue in
            self.settings.doubleCmdThreshold = newValue
        }.store(in: &cancellables)

        $triggerKey.sink { newValue in
            self.settings.triggerKey = newValue
        }.store(in: &cancellables)

        // 数据设置
        $cacheDuration.sink { newValue in
            self.settings.cacheDuration = newValue
        }.store(in: &cancellables)

        $maxCachedApps.sink { newValue in
            self.settings.maxCachedApps = newValue
        }.store(in: &cancellables)
    }

    private func loadDatabaseInfo() {
        // 获取数据库文件大小
        if let dbPath = databaseManager.getDatabasePath() {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: dbPath)
                if let fileSize = attributes[.size] as? Int64 {
                    databaseSize = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
                }
            } catch {
                databaseSize = "未知"
            }
        }

        // 获取使用记录数
        let usageSql = "SELECT COUNT(*) as count FROM usage_records"
        let usageResults = databaseManager.executeQuery(usageSql)
        if let first = usageResults.first, let count = first["count"] as? Int {
            usageRecordsCount = count
        }

        // 获取快捷键数
        let shortcutsSql = "SELECT COUNT(*) as count FROM shortcuts"
        let shortcutsResults = databaseManager.executeQuery(shortcutsSql)
        if let first = shortcutsResults.first, let count = first["count"] as? Int {
            shortcutsCount = count
        }
    }

    private func showNotification(title: String, message: String) {
        NotificationHelper.shared.send(title: title, message: message)
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - DatabaseManager Extension

extension DatabaseManager {
    func getDatabasePath() -> String? {
        // 返回数据库文件路径
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupportDir = paths.first else { return nil }
        let keymapDir = appSupportDir.appendingPathComponent("Keymap")
        return keymapDir.appendingPathComponent("keymap.db").path
    }
}

// MARK: - Import Combine

import Combine
