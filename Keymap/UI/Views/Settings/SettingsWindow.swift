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
        case .globalRemapping:
            globalRemappingView
        case .backgroundApps:
            backgroundAppsView
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

                    ZStack {
                        // 背景和边框
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorScheme == .dark ? Color(white: 0.25) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
                            )
                        
                        // Picker（无可见样式）
                        Picker("", selection: $viewModel.triggerKey) {
                            Text("双击Cmd").tag("doubleCmd")
                            Text("双击Option").tag("doubleOption")
                            Text("双击Control").tag("doubleControl")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .buttonStyle(.plain)
                        .opacity(0.01)  // 几乎透明，但仍可点击
                        
                        // 显示内容
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

    // MARK: - Global Remapping

    private var globalRemappingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("全局映射")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("自定义全局快捷键重映射规则")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 添加按钮（参考长驻应用刷新按钮样式）
                    Button(action: {
                        viewModel.showAddRemappingSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.body)
                            Text("添加")
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
                }
                .padding(.top, 16)

                Divider()

                // 启用全局重映射开关
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("启用全局快捷键重映射")
                            .font(.body)
                        Text("使用下方自定义的快捷键映射规则")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.enableGlobalRemapping)
                        .toggleStyle(.switch)
                }

                Divider()

                // 映射规则列表
                if viewModel.remappingRules.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("暂无映射规则")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("点击右上角「添加」按钮创建新的映射规则")
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
                }

                // 统计信息
                if !viewModel.remappingRules.isEmpty {
                    Divider()

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
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 16)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.98))
        .cornerRadius(8)
    }

    // MARK: - Background Apps

    private var backgroundAppsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("长驻应用")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("自动检测可能注册全局热键的后台应用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 刷新按钮
                    Button(action: {
                        viewModel.refreshBackgroundApps()
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
                }
                .padding(.top, 16)
                
                Divider()
                
                // 应用列表
                if viewModel.isLoadingBackgroundApps {
                    // 加载指示器
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
                            .font(.headline)
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
                
                Divider()
                
                // 说明信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("说明")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("长驻应用是指常驻系统后台的应用（如菜单栏应用、系统辅助进程）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("只显示已缓存快捷键的长驻应用，点击刷新可重新扫描")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("点击应用右侧的键盘图标可查看该应用的快捷键列表")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("这些应用可能注册了全局快捷键，与当前应用冲突时会触发通知")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 16)
        .onAppear {
            // ✅ 首次打开标签页时，快速加载长驻应用
            if viewModel.backgroundApps.isEmpty {
                viewModel.quickLoadBackgroundApps()
            }
        }
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

                Divider()

                // 导出/导入
                VStack(alignment: .leading, spacing: 8) {
                    Text("导出/导入")

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

                    ZStack {
                        // 背景和边框
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorScheme == .dark ? Color(white: 0.25) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
                            )
                        
                        // Picker（无可见样式）
                        Picker("", selection: $viewModel.logLevel) {
                            Text("关闭").tag(0)
                            Text("错误").tag(1)
                            Text("警告").tag(2)
                            Text("信息").tag(3)
                            Text("调试").tag(4)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .buttonStyle(.plain)
                        .opacity(0.01)  // 几乎透明，但仍可点击
                        
                        // 显示内容
                        HStack {
                            Text(["关闭", "错误", "警告", "信息", "调试"][viewModel.logLevel])
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
                    .frame(width: 100, height: 28)
                }

                Divider()

                // 高级功能
                VStack(alignment: .leading, spacing: 12) {
                    Text("高级功能")
                        .font(.headline)

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("启用全局快捷键重映射")
                                .font(.body)
                            Text("开启后，已配置的重映射规则将立即生效")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.enableGlobalRemapping)
                            .toggleStyle(.switch)
                    }

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("启用快捷键录制模式")
                                .font(.body)
                            Text("允许在配置重映射时通过按键录制快捷键")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

                    Button(action: {
                        viewModel.resetAllSettings()
                    }) {
                        Text("重置所有设置")
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
    case globalRemapping
    case backgroundApps
    case data
    case advanced
    case about

    var title: String {
        switch self {
        case .general: return "通用"
        case .shortcuts: return "快捷键"
        case .globalRemapping: return "全局映射"
        case .backgroundApps: return "长驻应用"
        case .data: return "数据"
        case .advanced: return "高级"
        case .about: return "关于"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "keyboard"
        case .globalRemapping: return "arrow.left.arrow.right"
        case .backgroundApps: return "app.badge"
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
    @Published var enableGlobalRemapping: Bool = false
    @Published var enableRecordingMode: Bool = false

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
        logLevel = settings.logLevel
        enableGlobalRemapping = settings.enableGlobalRemapping
        enableRecordingMode = settings.enableRecordingMode

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
        $logLevel.sink { newValue in
            self.settings.logLevel = newValue
        }.store(in: &cancellables)

        $enableGlobalRemapping.sink { newValue in
            self.settings.enableGlobalRemapping = newValue
        }.store(in: &cancellables)

        $enableRecordingMode.sink { newValue in
            self.settings.enableRecordingMode = newValue
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

                    // 录制按钮（仅当启用录制模式时显示）
                    if settings.enableRecordingMode {
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

                    // 录制按钮（仅当启用录制模式时显示）
                    if settings.enableRecordingMode {
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
        guard settings.enableRecordingMode else {
            errorMessage = "录制功能未启用，请在设置中开启"
            return
        }

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
        guard settings.enableRecordingMode else {
            errorMessage = "录制功能未启用，请在设置中开启"
            return
        }

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

                    // 录制按钮（仅当启用录制模式时显示）
                    if settings.enableRecordingMode {
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

                    // 录制按钮（仅当启用录制模式时显示）
                    if settings.enableRecordingMode {
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
        guard settings.enableRecordingMode else {
            errorMessage = "录制功能未启用，请在设置中开启"
            return
        }
        
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
        guard settings.enableRecordingMode else {
            errorMessage = "录制功能未启用，请在设置中开启"
            return
        }
        
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
