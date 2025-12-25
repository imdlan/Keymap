//
//  SettingsWindow.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import SwiftUI
import AppKit
import ServiceManagement

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

    @Environment(\.colorScheme) var colorScheme  // 检测深色/浅色模式
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedTab: SettingsTab = .general
    
    // MARK: - Computed Properties
    
    /// 触发键的显示名称
    private var triggerKeyDisplayName: String {
        switch viewModel.triggerKey {
        case "doubleCmd":
            return "Cmd"
        case "doubleOption":
            return "Option"
        case "doubleControl":
            return "Control"
        default:
            return "Cmd"
        }
    }

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
                            .font(.system(size: 16))
                            .frame(width: 20, alignment: .center)
                        Text(tab.title)
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
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
        .padding(.top, 22)
        .padding(.bottom, 22)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .general:
            generalSettingsView
        case .conflictResolution:
            conflictResolutionView
        case .data:
            dataSettingsView
        case .about:
            aboutView
        }
    }

    // MARK: - Reusable Components

    /// 设置板块卡片容器 - 圆角透明背景
    @ViewBuilder
    private func settingsSectionCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.98))
        )
    }

    /// 板块标题 - 包含下方分割线
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Divider()
        }
    }

    // MARK: - General Settings

    private var generalSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ===== 应用行为板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("应用行为")

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

                        // 语言选择
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("语言")
                                    .font(.body)
                                Text("选择应用界面语言")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorScheme == .dark ? Color(white: 0.25) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
                                    )

                                Picker("", selection: $viewModel.selectedLanguage) {
                                    Text("跟随系统").tag("system")
                                    Text("简体中文").tag("zh-Hans")
                                    Text("English").tag("en")
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .buttonStyle(.plain)
                                .opacity(0.01)

                                HStack {
                                    Text(viewModel.selectedLanguage == "system" ? "跟随系统" :
                                         viewModel.selectedLanguage == "zh-Hans" ? "简体中文" : "English")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 8)
                                }
                                .allowsHitTesting(false)
                            }
                            .frame(width: 150, height: 28)
                        }
                    }
                }

                // ===== 快捷键设置板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("快捷键设置")

                        // 双击阈值
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("双击\(triggerKeyDisplayName)阈值")
                                Spacer()
                                Text(String(format: "%.2f 秒", viewModel.doubleCmdThreshold))
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: $viewModel.doubleCmdThreshold, in: 0.1...1.0, step: 0.05)
                                .accentColor(.blue)

                            Text("调整双击\(triggerKeyDisplayName)键的灵敏度（越小越灵敏）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

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

                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorScheme == .dark ? Color(white: 0.25) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
                                    )

                                Picker("", selection: $viewModel.triggerKey) {
                                    Text("双击Cmd").tag("doubleCmd")
                                    Text("双击Option").tag("doubleOption")
                                    Text("双击Control").tag("doubleControl")
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .buttonStyle(.plain)
                                .opacity(0.01)

                                HStack {
                                    Text(viewModel.triggerKey == "doubleCmd" ? "双击Cmd" :
                                         viewModel.triggerKey == "doubleOption" ? "双击Option" : "双击Control")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 8)
                                }
                                .allowsHitTesting(false)
                            }
                            .frame(width: 150, height: 28)
                        }

                        // 面板自动关闭延迟
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
                }
            }
            .padding(.top, 32)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Conflict Resolution

    private var conflictResolutionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ===== 检测设置板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("检测设置")

                        // 启用实时冲突检测
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("启用实时冲突检测")
                                    .font(.body)
                                Text("使用快捷键时实时检测冲突")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.enableRealTimeDetection)
                                .toggleStyle(.switch)
                        }

                        // 显示冲突通知
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

                        // 启用使用统计追踪
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("启用使用统计追踪")
                                    .font(.body)
                                Text("记录快捷键使用情况，用于冲突分析")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.enableUsageTracking)
                                .toggleStyle(.switch)
                        }
                    }
                }

                // ===== 长驻应用板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        // 标题行：包含标题、tips图标、刷新按钮
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("长驻应用")
                                    .font(.headline)
                                
                                Image(systemName: "info.circle")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .help("查看后台长驻应用的快捷键，帮助识别冲突源")
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.refreshBackgroundApps()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .frame(width: 28, height: 28)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .help("刷新长驻应用")
                            }
                            
                            Divider()
                        }

                        // 应用列表
                        if viewModel.isLoadingBackgroundApps {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("正在扫描长驻应用...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if viewModel.backgroundApps.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("暂未检测到长驻应用")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text("点击刷新按钮扫描系统中的长驻应用")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.backgroundApps) { app in
                                    backgroundAppRow(app: app)
                                }
                            }
                        }
                    }
                }

                // ===== 快捷键重映射板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        // 标题行：包含标题、tips图标、添加按钮
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("快捷键重映射")
                                    .font(.headline)
                                
                                Image(systemName: "info.circle")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .help("创建重映射规则以解决快捷键冲突或个性化定制")
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.showAddRemappingSheet = true
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .frame(width: 28, height: 28)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .help("添加重映射规则")
                            }
                            
                            Divider()
                        }

                        // 启用全局重映射开关
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("启用全局快捷键重映射")
                                    .font(.body)
                                Text("启用后所有重映射规则将生效")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.enableGlobalRemapping)
                                .toggleStyle(.switch)
                        }

                        // 规则列表
                        if viewModel.remappingRules.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.left.arrow.right.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("暂无映射规则")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text("点击上方「添加重映射规则」按钮创建新规则")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.remappingRules) { rule in
                                    remappingRuleRow(rule)
                                }
                            }

                            // 清空所有按钮
                            if !viewModel.remappingRules.isEmpty {
                                HStack {
                                    Text("共 \(viewModel.remappingRules.count) 条映射规则")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button(action: {
                                        viewModel.showClearAllAlert = true
                                    }) {
                                        Text("清空所有")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .frame(height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.red.opacity(0.15))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                    )
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $viewModel.showAddRemappingSheet) {
            AddRemappingSheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.editingRule) { rule in
            EditRemappingSheet(viewModel: viewModel, rule: rule)
        }
        .alert("确认清空", isPresented: $viewModel.showClearAllAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                viewModel.clearAllRemappings()
            }
        } message: {
            Text("确定要清空所有映射规则吗？此操作不可恢复。")
        }
        .onAppear {
            // 首次打开标签页时，快速加载长驻应用
            if viewModel.backgroundApps.isEmpty {
                viewModel.quickLoadBackgroundApps()
            }
        }
    }

    // 映射规则行
    private func remappingRuleRow(_ rule: RemappingRule) -> some View {
        HStack(spacing: 12) {
            // 应用图标
            if let appIcon = viewModel.getAppIcon(for: rule.bundleId) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            }

            // 映射信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(rule.fromKey)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .primary : .white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(colorScheme == .dark ? Color(white: 0.3) : Color(white: 0.25))
                        .cornerRadius(4)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(rule.toKey)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .primary : .white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(colorScheme == .dark ? Color(white: 0.3) : Color(white: 0.25))
                        .cornerRadius(4)
                }

                Text(viewModel.getAppName(for: rule.bundleId))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 操作按钮
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.editingRule = rule
                }) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Button(action: {
                    viewModel.deleteRemappingRule(rule)
                }) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }

        private func backgroundAppRow(app: BackgroundAppInfo) -> some View {
        HStack(spacing: 12) {
            // 应用图标
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
            
            // 应用信息
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    // 激活策略标签
                    Text(app.policyDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 快捷键数量
                    Text("\(app.shortcutCount) 个快捷键")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 用户标记指示器
                    if app.isUserMarked {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("手动标记")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // 键盘图标按钮
            Button(action: {
                viewModel.showShortcutsForApp(bundleId: app.bundleId)
            }) {
                Image(systemName: "keyboard")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("查看快捷键")
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Data Settings

    private var dataSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ===== 缓存设置板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("缓存设置")

                        // 缓存时长
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
                    }
                }

                // ===== 清理旧数据板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("清理旧数据")

                        HStack(spacing: 12) {
                            Button(action: {
                                viewModel.clearCache()
                            }) {
                                Text("清除缓存")
                                    .font(.body)
                                    .fontWeight(.medium)
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

                            Button(action: {
                                viewModel.clearUsageRecords()
                            }) {
                                Text("清除使用记录")
                                    .font(.body)
                                    .fontWeight(.medium)
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

                            Button(action: {
                                viewModel.clearAllData()
                            }) {
                                Text("清除所有数据")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .frame(height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(.red)
                        }

                        Text("清除操作不可恢复，请谨慎操作")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // ===== 导出/导入板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("导出/导入")

                        HStack(spacing: 12) {
                            Button(action: {
                                viewModel.exportRemappings()
                            }) {
                                Text("导出重映射规则")
                                    .font(.body)
                                    .fontWeight(.medium)
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

                            Button(action: {
                                viewModel.importRemappings()
                            }) {
                                Text("导入重映射规则")
                                    .font(.body)
                                    .fontWeight(.medium)
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

                            Button(action: {
                                viewModel.exportSettings()
                            }) {
                                Text("导出设置")
                                    .font(.body)
                                    .fontWeight(.medium)
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

                        Text("可以备份并在其他设备上使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // ===== 数据库信息板块 =====
                settingsSectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("数据库信息")

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
                            Text("已用快捷键:")
                            Text("\(viewModel.shortcutsCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - About View

    private var aboutView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Logo和名称
                VStack(spacing: 8) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                    } else {
                        Image(systemName: "keyboard")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                    }

                    Text("Keymap")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("一个适用于macOS平台的快捷键冲突检测与管理工具")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 16)

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

                // 版权信息
                VStack(spacing: 8) {
                    Text("Copyright 2025 David Lan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.top, 32)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Settings Tab

enum SettingsTab: CaseIterable {
    case general
    case conflictResolution
    case data
    case about

    var title: String {
        switch self {
        case .general: return "通用"
        case .conflictResolution: return "检测"
        case .data: return "数据"
        case .about: return "关于"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .conflictResolution: return "exclamationmark.triangle"
        case .data: return "externaldrive"
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
    @Published var enableGlobalRemapping: Bool = false
    @Published var selectedLanguage: String = "system"

    // 全局映射
    @Published var remappingRules: [RemappingRule] = []
    @Published var showAddRemappingSheet: Bool = false
    @Published var editingRule: RemappingRule? = nil
    @Published var showClearAllAlert: Bool = false

    // 数据库信息
    @Published var databaseSize: String = "计算中..."
    @Published var usageRecordsCount: Int = 0
    @Published var shortcutsCount: Int = 0
    
    // 长驻应用
    @Published var backgroundApps: [BackgroundAppInfo] = []
    @Published var isLoadingBackgroundApps: Bool = false

    // MARK: - Dependencies

    let settings = SettingsManager.shared
    private let remappingManager = RemappingManager.shared
    private let databaseManager = DatabaseManager.shared
    private let globalDatabase = GlobalShortcutDatabase.shared

    // MARK: - Initialization

    init() {
        loadSettings()
        loadDatabaseInfo()
        // ✅ 移除自动加载长驻应用，改为用户打开标签页时懒加载
    }

    // MARK: - Public Methods

    func updateLaunchAtLogin(_ enabled: Bool) {
        // 保存设置
        settings.launchAtLogin = enabled
        
        // macOS 13+ 使用 SMAppService
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    // 注册登录项
                    try SMAppService.mainApp.register()
                    showNotification(title: "开机自动启动已启用", message: "Keymap将在系统启动时自动运行")
                } else {
                    // 取消注册登录项
                    try SMAppService.mainApp.unregister()
                    showNotification(title: "开机自动启动已禁用", message: "Keymap不会在系统启动时自动运行")
                }
            } catch {
                showAlert(title: "设置失败", message: "无法更改开机自动启动设置：\(error.localizedDescription)")
            }
        } else {
            // macOS 13 以下版本，提示用户手动设置
            showAlert(
                title: "需要手动设置",
                message: "请前往「系统设置 → 用户与群组 → 登录项」手动添加或移除Keymap"
            )
        }
        
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
    
    /// 快速加载长驻应用（仅从缓存获取，不提取新快捷键）
    func quickLoadBackgroundApps() {
        isLoadingBackgroundApps = true
        Task {
            await globalDatabase.quickScanBackgroundApps()
            await MainActor.run {
                loadBackgroundApps()
                isLoadingBackgroundApps = false
            }
        }
    }
    
    /// 刷新长驻应用（完整扫描并提取快捷键）
    func refreshBackgroundApps() {
        isLoadingBackgroundApps = true
        Task {
            await globalDatabase.scanRunningApplications()
            await MainActor.run {
                loadBackgroundApps()
                isLoadingBackgroundApps = false
            }
        }
    }
    
    func showShortcutsForApp(bundleId: String) {
        // 通知 AppDelegate 显示指定应用的快捷键面板
        NotificationCenter.default.post(
            name: Notification.Name("ShowShortcutsForApp"),
            object: nil,
            userInfo: ["bundleId": bundleId]
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
        showConflictNotifications = settings.showConflictNotifications
        cacheDuration = settings.cacheDuration
        maxCachedApps = settings.maxCachedApps
        panelAutoCloseDelay = settings.panelAutoCloseDelay
        enableGlobalRemapping = settings.enableGlobalRemapping
        selectedLanguage = settings.selectedLanguage

        // 加载映射规则
        remappingRules = remappingManager.getAllRules()

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

        $showConflictNotifications.sink { newValue in
            self.settings.showConflictNotifications = newValue
        }.store(in: &cancellables)

        // 快捷键设置
        $doubleCmdThreshold.sink { newValue in
            self.settings.doubleCmdThreshold = newValue
        }.store(in: &cancellables)

        $triggerKey.sink { newValue in
            self.settings.triggerKey = newValue
        }.store(in: &cancellables)

        $panelAutoCloseDelay.sink { newValue in
            self.settings.panelAutoCloseDelay = newValue
        }.store(in: &cancellables)

        // 数据设置
        $cacheDuration.sink { newValue in
            self.settings.cacheDuration = newValue
        }.store(in: &cancellables)

        $maxCachedApps.sink { newValue in
            self.settings.maxCachedApps = newValue
        }.store(in: &cancellables)

        // 高级设置
        $enableGlobalRemapping.sink { newValue in
            self.settings.enableGlobalRemapping = newValue
        }.store(in: &cancellables)

        $selectedLanguage.sink { newValue in
            self.settings.selectedLanguage = newValue
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
        if let first = usageResults.first, let count = first["count"] as? Int64 {
            usageRecordsCount = Int(count)
        }

        // 获取不同快捷键数（已使用的快捷键种类）
        let shortcutsSql = "SELECT COUNT(DISTINCT shortcut_key) as count FROM usage_records"
        let shortcutsResults = databaseManager.executeQuery(shortcutsSql)
        if let first = shortcutsResults.first, let count = first["count"] as? Int64 {
            shortcutsCount = Int(count)
        }
    }

    private func loadBackgroundApps() {
        backgroundApps = globalDatabase.getBackgroundApps()
        Logger.shared.info("✅ 已加载 \(backgroundApps.count) 个长驻应用")
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

    // MARK: - Global Remapping Methods

    func addRemappingRule(_ rule: RemappingRule) {
        if remappingManager.addRemapping(rule) {
            remappingRules = remappingManager.getAllRules()
            showNotification(title: "映射规则已添加", message: "\(rule.fromKey) → \(rule.toKey)")
        } else {
            showAlert(title: "添加失败", message: "无法添加映射规则，请检查规则是否有效")
        }
    }

    func deleteRemappingRule(_ rule: RemappingRule) {
        remappingManager.removeRemapping(rule)
        remappingRules = remappingManager.getAllRules()
        showNotification(title: "映射规则已删除", message: "\(rule.fromKey) → \(rule.toKey)")
    }

    func clearAllRemappings() {
        remappingManager.clearAllRemappings()
        remappingRules = []
        showNotification(title: "已清空所有映射规则", message: "")
    }

    func getAppName(for bundleId: String) -> String {
        if bundleId == "*" {
            return "全局应用"
        }

        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            return app.localizedName ?? bundleId
        }

        return bundleId
    }

    func getAppIcon(for bundleId: String) -> NSImage? {
        if bundleId == "*" {
            return NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        }

        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            return app.icon
        }

        return nil
    }

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Add Remapping Sheet

struct AddRemappingSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @State private var fromKey: String = ""
    @State private var toKey: String = ""
    @State private var bundleId: String = "*"
    @State private var errorMessage: String? = nil
    @State private var isRecordingFrom: Bool = false
    @State private var isRecordingTo: Bool = false

    private let settings = SettingsManager.shared

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 4) {
                Text("添加映射规则")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("自定义快捷键重映射，将源键映射到目标键")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                // 源快捷键
                VStack(alignment: .leading, spacing: 8) {
                Text("源快捷键")
                    .font(.body)

                HStack(spacing: 8) {
                    // 输入框
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecordingFrom ? Color.gray.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        TextField(isRecordingFrom ? "请按下快捷键..." : "例如: ⌘T", text: $fromKey)
                            .font(.body)
                            .fontWeight(.medium)
                            .textFieldStyle(.plain)
                            .disabled(isRecordingFrom)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                    .frame(height: 28)

                    // 录制按钮
                    Button(action: {
                            if isRecordingFrom {
                                stopRecordingFrom()
                            } else {
                                startRecordingFrom()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isRecordingFrom ? "stop.circle.fill" : "keyboard")
                                    .font(.body)
                                Text(isRecordingFrom ? "停止" : "录制")
                                    .font(.body)
                            }
                            .frame(height: 28)
                            .padding(.horizontal, 12)
                            .background(isRecordingFrom ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                }

                Text("按下这个快捷键时将被重映射")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 目标快捷键
            VStack(alignment: .leading, spacing: 8) {
                Text("目标快捷键")
                    .font(.body)

                HStack(spacing: 8) {
                    // 输入框
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecordingTo ? Color.gray.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        TextField(isRecordingTo ? "请按下快捷键..." : "例如: ⇧⌘T", text: $toKey)
                            .font(.body)
                            .fontWeight(.medium)
                            .textFieldStyle(.plain)
                            .disabled(isRecordingTo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                    .frame(height: 28)

                    // 录制按钮
                    Button(action: {
                            if isRecordingTo {
                                stopRecordingTo()
                            } else {
                                startRecordingTo()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isRecordingTo ? "stop.circle.fill" : "keyboard")
                                    .font(.body)
                                Text(isRecordingTo ? "停止" : "录制")
                                    .font(.body)
                            }
                            .frame(height: 28)
                            .padding(.horizontal, 12)
                            .background(isRecordingTo ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                }

                Text("将被映射为这个快捷键")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 应用范围
            VStack(alignment: .leading, spacing: 8) {
                Text("应用范围")
                    .font(.body)

                ZStack {
                    // 背景和边框
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorScheme == .dark ? Color(white: 0.25) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
                        )

                    // Picker
                    Picker("", selection: $bundleId) {
                        Text("全局应用").tag("*")
                        // 这里可以添加更多应用选项
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .buttonStyle(.plain)
                    .opacity(0.01)

                    // 显示内容
                    HStack {
                        Text(bundleId == "*" ? "全局应用" : bundleId)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 8)
                    }
                    .allowsHitTesting(false)
                }
                .frame(height: 28)

                Text("选择映射规则适用的应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 错误消息
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }

            Spacer()

            // 按钮
            HStack(spacing: 12) {
                Button(action: {
                    stopRecordingFrom()
                    stopRecordingTo()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("取消")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
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

                Button(action: {
                    addRule()
                }) {
                    Text("添加")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(fromKey.isEmpty || toKey.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                )
                .foregroundColor(.white)
                .cornerRadius(6)
                .disabled(fromKey.isEmpty || toKey.isEmpty)
            }
            }
        }
        .padding(24)
        .frame(width: 300)
    }

    private func addRule() {
        let rule = RemappingRule(fromKey: fromKey, toKey: toKey, bundleId: bundleId)

        // 验证规则
        let validation = RemappingManager.shared.validateRemapping(rule)
        if !validation.isValid {
            errorMessage = validation.errorMessage
            return
        }

        // 添加规则
        viewModel.addRemappingRule(rule)
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - 录制功能

    private func startRecordingFrom() {
        Logger.shared.info("🎙️ 开始录制源快捷键...")
        isRecordingFrom = true
        errorMessage = nil

        KeyRecorder.shared.startRecording { keyCombination in
            DispatchQueue.main.async {
                self.fromKey = keyCombination.displayString
                self.isRecordingFrom = false
                Logger.shared.info("📝 录制完成: \(keyCombination.displayString)")
            }
        }
    }

    private func stopRecordingFrom() {
        isRecordingFrom = false
        KeyRecorder.shared.stopRecording()
    }

    private func startRecordingTo() {
        Logger.shared.info("🎙️ 开始录制目标快捷键...")
        isRecordingTo = true
        errorMessage = nil

        KeyRecorder.shared.startRecording { keyCombination in
            DispatchQueue.main.async {
                self.toKey = keyCombination.displayString
                self.isRecordingTo = false
                Logger.shared.info("📝 录制完成: \(keyCombination.displayString)")
            }
        }
    }

    private func stopRecordingTo() {
        isRecordingTo = false
        KeyRecorder.shared.stopRecording()
    }
}

// MARK: - Edit Remapping Sheet

struct EditRemappingSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    let rule: RemappingRule
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @State private var fromKey: String = ""
    @State private var toKey: String = ""
    @State private var bundleId: String = "*"
    @State private var errorMessage: String? = nil
    @State private var isRecordingFrom: Bool = false
    @State private var isRecordingTo: Bool = false

    private let settings = SettingsManager.shared

    init(viewModel: SettingsViewModel, rule: RemappingRule) {
        self.viewModel = viewModel
        self.rule = rule
        _fromKey = State(initialValue: rule.fromKey)
        _toKey = State(initialValue: rule.toKey)
        _bundleId = State(initialValue: rule.bundleId)
    }

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 4) {
                Text("编辑映射规则")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("修改快捷键映射规则，调整源键或目标键")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                // 源快捷键
                VStack(alignment: .leading, spacing: 8) {
                Text("源快捷键")
                    .font(.body)

                HStack(spacing: 8) {
                    // 输入框
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecordingFrom ? Color.gray.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        TextField(isRecordingFrom ? "请按下快捷键..." : "例如: ⌘T", text: $fromKey)
                            .font(.body)
                            .fontWeight(.medium)
                            .textFieldStyle(.plain)
                            .disabled(isRecordingFrom)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                    .frame(height: 28)

                    // 录制按钮
                    Button(action: {
                            if isRecordingFrom {
                                stopRecordingFrom()
                            } else {
                                startRecordingFrom()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isRecordingFrom ? "stop.circle.fill" : "keyboard")
                                    .font(.body)
                                Text(isRecordingFrom ? "停止" : "录制")
                                    .font(.body)
                            }
                            .frame(height: 28)
                            .padding(.horizontal, 12)
                            .background(isRecordingFrom ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                }

                Text("按下这个快捷键时将被重映射")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 目标快捷键
            VStack(alignment: .leading, spacing: 8) {
                Text("目标快捷键")
                    .font(.body)

                HStack(spacing: 8) {
                    // 输入框
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecordingTo ? Color.gray.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        TextField(isRecordingTo ? "请按下快捷键..." : "例如: ⇧⌘T", text: $toKey)
                            .font(.body)
                            .fontWeight(.medium)
                            .textFieldStyle(.plain)
                            .disabled(isRecordingTo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                    .frame(height: 28)

                    // 录制按钮
                    Button(action: {
                            if isRecordingTo {
                                stopRecordingTo()
                            } else {
                                startRecordingTo()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isRecordingTo ? "stop.circle.fill" : "keyboard")
                                    .font(.body)
                                Text(isRecordingTo ? "停止" : "录制")
                                    .font(.body)
                            }
                            .frame(height: 28)
                            .padding(.horizontal, 12)
                            .background(isRecordingTo ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                }

                Text("将被映射为这个快捷键")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 应用范围（只读）
            VStack(alignment: .leading, spacing: 8) {
                Text("应用范围")
                    .font(.body)
                Text(bundleId == "*" ? "全局应用" : viewModel.getAppName(for: bundleId))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                Text("应用范围不可修改")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 错误消息
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }

            Spacer()

            // 按钮
            HStack(spacing: 12) {
                Button(action: {
                    stopRecordingFrom()
                    stopRecordingTo()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("取消")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
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

                Button(action: {
                    saveChanges()
                }) {
                    Text("保存")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(fromKey.isEmpty || toKey.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                )
                .foregroundColor(.white)
                .cornerRadius(6)
                .disabled(fromKey.isEmpty || toKey.isEmpty)
            }
            }
        }
        .padding(24)
        .frame(width: 300)
    }
    
    private func saveChanges() {
        // 先删除旧规则
        viewModel.deleteRemappingRule(rule)

        // 添加新规则
        let newRule = RemappingRule(fromKey: fromKey, toKey: toKey, bundleId: bundleId)

        // 验证规则
        let validation = RemappingManager.shared.validateRemapping(newRule)
        if !validation.isValid {
            errorMessage = validation.errorMessage
            // 恢复旧规则
            viewModel.addRemappingRule(rule)
            return
        }

        // 添加新规则
        viewModel.addRemappingRule(newRule)
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - 录制功能
    
    private func startRecordingFrom() {
        Logger.shared.info("🎙️ 开始录制源快捷键...")
        isRecordingFrom = true
        errorMessage = nil
        
        KeyRecorder.shared.startRecording { keyCombination in
            DispatchQueue.main.async {
                self.fromKey = keyCombination.displayString
                self.isRecordingFrom = false
                Logger.shared.info("📝 录制完成: \(keyCombination.displayString)")
            }
        }
    }
    
    private func stopRecordingFrom() {
        isRecordingFrom = false
        KeyRecorder.shared.stopRecording()
    }
    
    private func startRecordingTo() {
        Logger.shared.info("🎙️ 开始录制目标快捷键...")
        isRecordingTo = true
        errorMessage = nil
        
        KeyRecorder.shared.startRecording { keyCombination in
            DispatchQueue.main.async {
                self.toKey = keyCombination.displayString
                self.isRecordingTo = false
                Logger.shared.info("📝 录制完成: \(keyCombination.displayString)")
            }
        }
    }
    
    private func stopRecordingTo() {
        isRecordingTo = false
        KeyRecorder.shared.stopRecording()
    }
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
