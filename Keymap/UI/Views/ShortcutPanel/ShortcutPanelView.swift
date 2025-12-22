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
                Text("快捷键面板")
                    .font(.headline)
                Text(viewModel.currentApp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("按ESC键关闭")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索快捷键...", text: $viewModel.searchText)
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
                        title: "常用快捷键",
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
                // 使用 KeyBadgeView 显示快捷键
                KeyBadgeView(keyCombination: shortcut.keyCombination)
                    .frame(width: 100, alignment: .leading)

                Text(shortcut.description)
                    .font(.body)

                Spacer()

                // 重映射按钮
                Button(action: {
                    selectedShortcut = shortcut
                    showingRemappingDialog = true
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("重映射此快捷键")

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
        .sheet(isPresented: $showingRemappingDialog) {
            if let shortcut = selectedShortcut {
                RemappingDialogView(shortcut: shortcut, isPresented: $showingRemappingDialog)
            }
        }
    }

    /// 冲突详情视图
    private func conflictDetails(for shortcut: ShortcutInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(shortcut.conflicts) { conflict in
                VStack(alignment: .leading, spacing: 6) {
                    // 严重程度
                    VStack(alignment: .leading, spacing: 2) {
                        Text("严重程度")
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
                        Text("冲突类型")
                            .font(.caption)
                            .fontWeight(.bold)

                        Text(conflict.conflictType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 冲突应用
                    if let app = conflict.conflictingApp {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("冲突应用")
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
                            Text("建议")
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
                .padding(.vertical, 4)

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

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerView: some View {
        HStack {
            Text("\(viewModel.shortcuts.count) 个快捷键")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                openStatisticsWindow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar")
                    Text("统计")
                }
            }
            .buttonStyle(.borderless)
            .foregroundColor(.primary)

            Button(action: {
                openSettingsWindow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                    Text("设置")
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

    @State private var newKeyCombination: String = ""
    @State private var errorMessage: String?
    @State private var isRecording: Bool = false
    @State private var conflictWarning: String?

    private let remappingManager = RemappingManager.shared
    private let settings = SettingsManager.shared
    private let conflictDetector = ConflictDetector()

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 4) {
                Text("重映射快捷键")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("将快捷键映射到其他组合，仅在当前应用中生效")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 当前快捷键
            VStack(alignment: .leading, spacing: 8) {
                Text("当前快捷键")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text(shortcut.keyCombination)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    Text(shortcut.description)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }

            // 新快捷键输入
            VStack(alignment: .leading, spacing: 8) {
                Text("新快捷键")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    TextField(isRecording ? "请按下快捷键..." : "例如: ⇧⌘T", text: $newKeyCombination)
                        .font(.system(.title3, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)
                        .disabled(isRecording)

                    // 录制按钮（仅当启用录制模式时显示）
                    if settings.enableRecordingMode {
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "keyboard")
                                    .imageScale(.medium)
                                Text(isRecording ? "停止" : "录制")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("提示: 使用 ⌘(Command) ⇧(Shift) ⌥(Option) ⌃(Control) + 字母/数字")
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
            HStack {
                Button("取消") {
                    stopRecording()
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("重置") {
                    removeRemapping()
                }
                .foregroundColor(.orange)

                Button("确定") {
                    applyRemapping()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newKeyCombination.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    private func applyRemapping() {
        // 停止录制（如果正在录制）
        stopRecording()

        // 验证新快捷键
        guard !newKeyCombination.isEmpty else {
            errorMessage = "请输入新的快捷键"
            return
        }

        // 创建重映射规则
        let rule = RemappingRule(
            fromKey: shortcut.keyCombination,
            toKey: newKeyCombination,
            bundleId: shortcut.application
        )

        // 验证规则
        let (isValid, validationError) = remappingManager.validateRemapping(rule)
        if !isValid {
            errorMessage = validationError
            return
        }

        // 冲突检测
        checkConflicts(for: newKeyCombination)

        // 添加重映射
        if remappingManager.addRemapping(rule) {
            Logger.info("✅ 重映射成功: \(rule.fromKey) → \(rule.toKey)")
            isPresented = false

            // 显示通知
            showNotification(
                title: "重映射成功",
                message: "\(rule.fromKey) 已重映射为 \(rule.toKey)"
            )
        } else {
            errorMessage = "重映射失败，请检查输入"
        }
    }

    private func removeRemapping() {
        // 停止录制
        stopRecording()

        // 移除现有的重映射
        if remappingManager.isRemapped(shortcut.keyCombination, in: shortcut.application) {
            let rule = RemappingRule(
                fromKey: shortcut.keyCombination,
                toKey: "",
                bundleId: shortcut.application
            )
            remappingManager.removeRemapping(rule)

            Logger.info("🗑 已移除重映射: \(shortcut.keyCombination)")
            isPresented = false

            showNotification(
                title: "已重置",
                message: "\(shortcut.keyCombination) 已恢复默认映射"
            )
        } else {
            newKeyCombination = ""
            errorMessage = nil
        }
    }

    private func showNotification(title: String, message: String) {
        NotificationHelper.shared.send(title: title, message: message)
    }

    // MARK: - 录制功能

    private func startRecording() {
        guard settings.enableRecordingMode else {
            errorMessage = "录制功能未启用，请在设置中开启"
            return
        }

        Logger.info("🎙️ 开始录制快捷键...")
        isRecording = true
        errorMessage = nil
        conflictWarning = nil

        KeyRecorder.shared.startRecording { [self] keyCombination in
            DispatchQueue.main.async {
                self.newKeyCombination = keyCombination.displayString
                self.isRecording = false
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
        if colorScheme == .dark {
            // 深色模式：浅灰色
            return Color(white: 0.3)
        } else {
            // 浅色模式：浅灰色（与半透明面板协调）
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
