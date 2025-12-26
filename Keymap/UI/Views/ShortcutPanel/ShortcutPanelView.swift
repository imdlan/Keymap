//
//  ShortcutPanelView.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import SwiftUI
import AppKit

struct ShortcutPanelView: View {
    @ObservedObject var viewModel: ShortcutPanelViewModel
    @State private var showingRemappingDialog: Bool = false
    @State private var selectedShortcut: ShortcutInfo? = nil
    @State private var expandedConflicts: Set<String> = []  // 展开的冲突快捷键ID集合

    var body: some View {
        ZStack {
            // 主面板
            VStack(spacing: 0) {
                // 头部
                headerView

                Divider()

                // 搜索栏
                searchBar

                Divider()

                // 快捷键列表
                if viewModel.isLoading {
                    loadingView
                } else {
                    shortcutListView
                }

                Divider()

                // 底部操作栏
                footerView
            }
            .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
            .cornerRadius(12)
            .frame(width: 500, height: 600)
            .disabled(showingRemappingDialog)  // ✅ 弹窗显示时禁用背景交互
            
            // ✅ 自定义遮罩层和弹窗（替代.sheet）
            if showingRemappingDialog, let shortcut = selectedShortcut {
                // 遮罩层
                Color.black.opacity(0.3)
                    .cornerRadius(12)
                    .allowsHitTesting(false)  // ✅ 遮罩不拦截点击事件
                
                // 弹窗
                RemappingDialogView(shortcut: shortcut, isPresented: $showingRemappingDialog)
            }
        }
        .frame(width: 500, height: 600)
        .onChange(of: showingRemappingDialog) { _, isShowing in
            if !isShowing {
                // ✅ 对话框关闭后刷新快捷键列表
                viewModel.loadCurrentAppShortcuts()
            }
        }
    }

    // MARK: - 子视图

    private var headerView: some View {
        HStack {
            // 显示当前app的图标，如果没有则显示键盘图标
            if let appIcon = viewModel.currentAppIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
            } else {
                Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("panel.title".localized())
                    .font(.headline)
                Text(viewModel.currentApp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("panel.close_hint".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("panel.search_shortcuts_placeholder".localized(), text: $viewModel.searchText)
                .textFieldStyle(.plain)
        }
        .padding()
    }

    private var shortcutListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 冲突快捷键
                if !viewModel.conflictShortcuts.isEmpty {
                    shortcutSection(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: "冲突快捷键",
                        count: viewModel.conflictShortcuts.count,
                        shortcuts: viewModel.conflictShortcuts,
                        isConflict: true
                    )
                }

                // 常用快捷键
                if !viewModel.normalShortcuts.isEmpty {
                    shortcutSection(
                        icon: "command",
                        iconColor: .blue,
                        title: "panel.common_shortcuts_title".localized(),
                        count: viewModel.normalShortcuts.count,
                        shortcuts: viewModel.normalShortcuts,
                        isConflict: false
                    )
                }
            }
            .padding()
        }
    }

    private func shortcutSection(icon: String, iconColor: Color, title: String, count: Int, shortcuts: [ShortcutInfo], isConflict: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text("\(title) (\(count))")
            }
            .font(.subheadline)
            .fontWeight(.semibold)

            VStack(spacing: 4) {
                ForEach(shortcuts) { shortcut in
                    shortcutRow(shortcut: shortcut, isConflict: isConflict)
                }
            }
        }
    }

    private func shortcutRow(shortcut: ShortcutInfo, isConflict: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主行
            HStack {
                // ✅ 使用 KeyBadgeView 显示快捷键（同一行显示重映射）
                HStack(spacing: 4) {
                    // 如果有重映射，原快捷键显示为灰色
                    let hasRemap = getRemappedKey(for: shortcut) != nil
                    KeyBadgeView(keyCombination: shortcut.keyCombination, isOriginal: hasRemap)
                    
                    // ✅ 如果快捷键被重映射，显示 › 和重映射目标
                    if let remappedKey = getRemappedKey(for: shortcut) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        KeyBadgeView(keyCombination: remappedKey, isRemapped: true)
                    }
                }
                .frame(width: 180, alignment: .leading)

                Text(shortcut.description)
                    .font(.body)

                Spacer()

                // 重映射按钮
                Button(action: {
                    selectedShortcut = shortcut
                    showingRemappingDialog = true
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(canRemap(shortcut) ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!canRemap(shortcut))
                .help(canRemap(shortcut) ? "重映射此快捷键" : "此快捷键无法重映射")

                // 冲突图标和展开按钮
                if isConflict {
                    Button(action: {
                        toggleConflictExpansion(for: shortcut.id)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Image(systemName: expandedConflicts.contains(shortcut.id) ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("查看冲突详情")
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)

            // 展开的冲突详情
            if isConflict && expandedConflicts.contains(shortcut.id) {
                Divider()
                    .padding(.horizontal, 12)

                conflictDetails(for: shortcut)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .background(isConflict ? Color.orange.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }

    /// 冲突详情视图
    private func conflictDetails(for shortcut: ShortcutInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(shortcut.conflicts) { conflict in
                VStack(alignment: .leading, spacing: 6) {
                    // 严重程度
                    VStack(alignment: .leading, spacing: 2) {
                        Text("conflict.severity".localized())
                            .font(.caption)
                            .fontWeight(.bold)

                        Text(conflict.severity.rawValue)
                            .font(.caption)
                            .foregroundColor(severityColor(conflict.severity))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(severityColor(conflict.severity).opacity(0.2))
                            .cornerRadius(4)
                    }

                    // 冲突类型
                    VStack(alignment: .leading, spacing: 2) {
                        Text("conflict.type".localized())
                            .font(.caption)
                            .fontWeight(.bold)

                        Text(conflict.conflictType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 冲突应用
                    if let app = conflict.conflictingApp {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("conflict.conflicting_app".localized())
                                .font(.caption)
                                .fontWeight(.bold)

                            Text(app)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 修改建议
                    if !conflict.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("conflict.suggestions".localized())
                                .font(.caption)
                                .fontWeight(.bold)

                            ForEach(conflict.suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)

                if conflict.id != shortcut.conflicts.last?.id {
                    Divider()
                }
            }
        }
    }

    /// 切换冲突展开状态
    private func toggleConflictExpansion(for shortcutId: String) {
        if expandedConflicts.contains(shortcutId) {
            expandedConflicts.remove(shortcutId)
        } else {
            expandedConflicts.insert(shortcutId)
        }
    }

    /// 根据严重程度返回颜色
    private func severityColor(_ severity: ConflictSeverity) -> Color {
        switch severity {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .yellow
        }
    }

    /// 判断快捷键是否可以重映射
    private func canRemap(_ shortcut: ShortcutInfo) -> Bool {
        let key = shortcut.keyCombination
        
        // 系统保留快捷键
        let systemReservedKeys: Set<String> = [
            "⌘Q",       // 退出应用
            "⌘⌥Esc",    // 强制退出
            "⌘Space",   // Spotlight
            "⌃⌘Q",      // 锁定屏幕
            "⌃⌘Power"   // 关机对话框
        ]
        
        // 特殊触发器（不是标准快捷键）
        let specialTriggers: Set<String> = [
            "⌘⌘",       // 双击 Cmd
            "⌥⌥",       // 双击 Option
            "⌃⌃"        // 双击 Control
        ]
        
        // 如果是系统保留快捷键或特殊触发器，不允许重映射
        return !systemReservedKeys.contains(key) && !specialTriggers.contains(key)
    }

    /// 获取快捷键的重映射目标
    private func getRemappedKey(for shortcut: ShortcutInfo) -> String? {
        return RemappingManager.shared.getRemappedKey(
            shortcut.keyCombination,
            for: shortcut.application
        )
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("panel.loading".localized())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerView: some View {
        HStack {
            Text("common.shortcuts_count".localized(with: viewModel.shortcuts.count))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                openStatisticsWindow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar")
                    Text("panel.statistics".localized())
                }
            }
            .buttonStyle(.borderless)
            .foregroundColor(.primary)

            Button(action: {
                openSettingsWindow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                    Text("panel.settings".localized())
                }
            }
            .buttonStyle(.borderless)
            .foregroundColor(.primary)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func openStatisticsWindow() {
        NotificationCenter.default.post(name: .showStatisticsWindow, object: nil)
    }

    private func openSettingsWindow() {
        NotificationCenter.default.post(name: .showSettingsWindow, object: nil)
    }
}

// MARK: - 视觉效果视图

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - 重映射对话框

struct RemappingDialogView: View {
    let shortcut: ShortcutInfo
    @Binding var isPresented: Bool
    
    @Environment(\.colorScheme) var colorScheme  // 检测深色/浅色模式
    
    @State private var newKeyCombination: String = ""
    @State private var errorMessage: String?
    @State private var isRecording: Bool = false
    @State private var conflictWarning: String?
    @State private var currentRemappedKey: String?  // 追踪当前重映射状态
    @State private var isPendingReset: Bool = false  // ✅ 标记用户是否点击了重置

    private let remappingManager = RemappingManager.shared
    private let settings = SettingsManager.shared
    private let conflictDetector = ConflictDetector()

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 4) {
                Text("remapping.title".localized())
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("remapping.description".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 当前快捷键
            VStack(alignment: .leading, spacing: 8) {
                Text("remapping.current_shortcut".localized())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack {
                    // ✅ 显示原始快捷键和重映射目标（和主面板保持一致）
                    HStack(spacing: 4) {
                        // 如果有重映射，原快捷键显示为灰色
                        KeyBadgeView(keyCombination: shortcut.keyCombination, isOriginal: currentRemappedKey != nil)
                        
                        // 如果快捷键已重映射，显示 › 和重映射目标
                        if let remappedKey = currentRemappedKey {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            KeyBadgeView(keyCombination: remappedKey, isRemapped: true)
                        }
                    }

                    Text(shortcut.description)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }

            // 新快捷键输入
            VStack(alignment: .leading, spacing: 8) {
                Text("remapping.new_shortcut".localized())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // 输入框 - 调整为32px高度，4px内边距
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecording ? Color.gray.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        TextField(isRecording ? "recording.placeholder_recording".localized() : "recording.placeholder_example_shift".localized(), text: $newKeyCombination)
                            .onChange(of: newKeyCombination) { _, _ in
                                // ✅ 用户输入新内容时，清除重置标记
                                if isPendingReset && !newKeyCombination.isEmpty {
                                    isPendingReset = false
                                    // 恢复当前实际的重映射状态
                                    currentRemappedKey = getRemappedKey(for: shortcut)
                                }
                            }
                            .font(.body)  // ✅ 使用和KeyBadgeView相同的字体
                            .fontWeight(.medium)  // ✅ 中等粗细
                            .textFieldStyle(.plain)
                            .disabled(isRecording)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)  // ✅ 调整为4px
                    }
                    .frame(height: 28)  // ✅ 调整为28px高度

                    // 录制按钮
                    Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "keyboard")
                                    .font(.body)
                                Text(isRecording ? "recording.stop".localized() : "recording.record".localized())
                                    .font(.body)
                            }
                            .frame(height: 28)  // ✅ 调整为28px高度
                            .padding(.horizontal, 12)
                            .background(isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                }

                Text("remapping.hint".localized())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // 冲突警告
            if let warning = conflictWarning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }

            // 错误信息
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }

            Divider()

            // 按钮
            HStack(spacing: 12) {
                // 取消按钮
                Button(action: {
                    stopRecording()
                    isPendingReset = false
                    isPresented = false
                }) {
                    Text("action.cancel".localized())
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
                .keyboardShortcut(.cancelAction)

                // 重置按钮
                let canReset = currentRemappedKey != nil
                Button(action: {
                    removeRemapping()
                }) {
                    Text("action.reset".localized())
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(canReset ? 
                            (colorScheme == .dark ? Color.orange.opacity(0.3) : Color.orange.opacity(0.15)) : 
                            (colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.9))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(canReset ? Color.orange.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: 1)
                )
                .foregroundColor(canReset ? .orange : .gray)
                .disabled(!canReset)

                // 确定按钮
                let isEnabled = isPendingReset || !newKeyCombination.isEmpty
                Button(action: {
                    applyRemapping()
                }) {
                    Text("action.confirm".localized())
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isEnabled ? Color.blue : 
                            (colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.9))
                        )
                )
                .foregroundColor(isEnabled ? .white : .gray)
                .keyboardShortcut(.defaultAction)
                .disabled(!isEnabled)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 450)  // 稍微窄一点，留出边距
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            // 初始化当前重映射状态
            currentRemappedKey = getRemappedKey(for: shortcut)
        }
    }

    private func applyRemapping() {
        // 停止录制（如果正在录制）
        stopRecording()
        
        // ✅ 检查是否是重置状态
        if isPendingReset {
            // 用户点击了重置，现在要确认移除重映射
            if remappingManager.isRemapped(shortcut.keyCombination, in: shortcut.application) {
                let rule = RemappingRule(
                    fromKey: shortcut.keyCombination,
                    toKey: "",
                    bundleId: shortcut.application
                )
                remappingManager.removeRemapping(rule)
                Logger.info("🗑 已移除重映射: \(shortcut.keyCombination)")
                
                showNotification(
                    title: "已重置",
                    message: "\(shortcut.keyCombination) 已恢复默认映射"
                )
            }
            
            isPresented = false
            return
        }
        
        // ✅ 验证新快捷键
        guard !newKeyCombination.isEmpty else {
            errorMessage = "请输入新的快捷键"
            Logger.warning("⚠️ 快捷键为空")
            return
        }

        
        Logger.info("🔄 准备重映射: \(shortcut.keyCombination) → \(newKeyCombination)")
        
        // 创建重映射规则
        let rule = RemappingRule(
            fromKey: shortcut.keyCombination,
            toKey: newKeyCombination,
            bundleId: shortcut.application
        )
        
        // 验证规则
        Logger.info("🔍 开始验证规则...")
        let (isValid, validationError) = remappingManager.validateRemapping(rule)
        if !isValid {
            Logger.error("❌ 验证失败: \(validationError ?? "未知错误")")
            errorMessage = validationError
            return
        }
        Logger.info("✅ 验证通过")
        
        // 冲突检测
        checkConflicts(for: newKeyCombination)
        
        // 添加重映射
        Logger.info("💾 开始添加重映射...")
        let addResult = remappingManager.addRemapping(rule)
        if addResult {
            Logger.info("✅ 重映射成功: \(rule.fromKey) → \(rule.toKey)")
            
            // ✅ 更新当前重映射状态，触发视图刷新
            currentRemappedKey = newKeyCombination
            
            // ✅ 自动启用全局重映射（如果未开启）
            if !settings.enableGlobalRemapping {
                settings.enableGlobalRemapping = true
                Logger.info("🔓 已自动启用全局快捷键重映射")
                showNotification(
                    title: "重映射已生效",
                    message: "\(rule.fromKey) → \(rule.toKey)，全局重映射已自动开启"
                )
            } else {
                showNotification(
                    title: "重映射成功",
                    message: "\(rule.fromKey) → \(rule.toKey)"
                )
            }
            
            isPresented = false
        } else {
            Logger.error("❌ 添加重映射失败")
            errorMessage = "重映射失败，请检查输入"
        }
    }

    private func removeRemapping() {
        // 停止录制
        stopRecording()

        // ✅ 清空输入框和消息
        newKeyCombination = ""
        errorMessage = nil
        conflictWarning = nil
        
        // ✅ 标记为待重置状态（仅在弹窗内临时显示，不立即生效）
        isPendingReset = true
        
        // ✅ 临时更新视图状态（仅在弹窗内显示为已重置）
        currentRemappedKey = nil
        
        Logger.info("📝 已标记为重置状态（点击确定后生效）")
    }

    private func showNotification(title: String, message: String) {
        NotificationHelper.shared.send(title: title, message: message)
    }

    // MARK: - 录制功能

    private func startRecording() {
        Logger.info("🎙️ 开始录制快捷键...")
        isRecording = true
        errorMessage = nil
        conflictWarning = nil

        KeyRecorder.shared.startRecording { [self] keyCombination in
            DispatchQueue.main.async {
                self.newKeyCombination = keyCombination.displayString
                self.isRecording = false
                
                // ✅ 录制完成后，清除重置标记
                if self.isPendingReset {
                    self.isPendingReset = false
                    // 恢复当前实际的重映射状态
                    self.currentRemappedKey = self.getRemappedKey(for: self.shortcut)
                }
                
                Logger.info("📝 录制完成: \(keyCombination.displayString)")
                
                // 自动检测冲突
                self.checkConflicts(for: keyCombination.displayString)
            }
        }
    }

    private func stopRecording() {
        if isRecording {
            KeyRecorder.shared.stopRecording()
            isRecording = false
            Logger.info("🛑 停止录制")
        }
    }

    // MARK: - Helper Methods
    
    /// 获取快捷键的重映射目标
    private func getRemappedKey(for shortcut: ShortcutInfo) -> String? {
        return RemappingManager.shared.getRemappedKey(
            shortcut.keyCombination,
            for: shortcut.application
        )
    }

    // MARK: - 冲突检测

    private func checkConflicts(for newKey: String) {
        // 清除之前的警告
        conflictWarning = nil

        // 创建临时快捷键信息用于冲突检测
        let tempShortcut = ShortcutInfo(
            id: UUID().uuidString,
            keyCombination: newKey,
            description: "临时快捷键",
            application: shortcut.application,
            category: .other,
            isCustom: true
        )

        // 检测冲突（传入数组）
        let conflicts = conflictDetector.detectConflicts(shortcuts: [tempShortcut])

        if !conflicts.isEmpty {
            // 构建冲突警告消息
            let conflictCount = conflicts.count
            let firstConflict = conflicts[0]

            var warningMessage = "检测到 \(conflictCount) 个冲突"

            // 显示第一个冲突的详细信息
            switch firstConflict.conflictType {
            case .system:
                warningMessage += "：与系统快捷键冲突"
            case .global:
                warningMessage += "：与全局快捷键冲突"
            case .application:
                if let conflictApp = firstConflict.conflictingApp {
                    warningMessage += "：与 \(conflictApp) 的快捷键冲突"
                }
            case .functional:
                warningMessage += "：功能性冲突"
            }

            // 如果有多个冲突，提示用户
            if conflictCount > 1 {
                warningMessage += "等"
            }

            conflictWarning = warningMessage
            Logger.warning("⚠️ \(warningMessage)")
        }
    }
}

// MARK: - KeyBadgeView 快捷键徽章视图

struct KeyBadgeView: View {
    let keyCombination: String
    var isRemapped: Bool = false  // 是否是重映射后的快捷键（新键）
    var isOriginal: Bool = false  // 是否是原始快捷键但有重映射（应显示灰色）
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(formattedKeyString)
            .font(.body)  // 使用系统默认字体，确保符号和字母大小一致
            .fontWeight(.medium)
            .foregroundColor(colorScheme == .dark ? .primary : .white)
            .padding(.horizontal, 4)  // 水平间距增加到4px
            .padding(.vertical, 1)
            .background(backgroundColor)
            .cornerRadius(4)
    }

    /// 根据色彩模式返回合适的背景色
    private var backgroundColor: Color {
        // 如果是原始快捷键但有重映射（被替换的键），显示灰色
        if isOriginal {
            return Color.gray.opacity(0.5)
        }
        
        // 其他情况（重映射后的新键或普通快捷键）使用深色背景
        if colorScheme == .dark {
            return Color(white: 0.3)
        } else {
            return Color(white: 0.25)
        }
    }

    /// 将快捷键转换为格式化的字符串，如 "⌘C" → "⌘ + C"
    private var formattedKeyString: String {
        let input = keyCombination.trimmingCharacters(in: .whitespaces)
        var modifiers = ""
        var mainKey = ""

        // 分离修饰键和主键
        for char in input {
            let charStr = String(char)
            if isModifierKey(charStr) {
                modifiers += charStr
            } else {
                mainKey += charStr
            }
        }

        // 构建格式化字符串
        var parts: [String] = []

        // 添加修饰键（每个修饰键单独显示）
        for modifier in modifiers {
            parts.append(String(modifier))
        }

        // 添加主键（转为大写）
        if !mainKey.isEmpty {
            parts.append(mainKey.uppercased())
        }

        // 用 " + " 连接所有部分
        return parts.joined(separator: " + ")
    }

    /// 判断是否是修饰键
    private func isModifierKey(_ key: String) -> Bool {
        let modifierKeys = ["⌘", "⇧", "⌥", "⌃", "^", "⎋"]
        return modifierKeys.contains(key)
    }
}
