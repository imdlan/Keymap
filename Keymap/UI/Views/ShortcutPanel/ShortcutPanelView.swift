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
            Image(systemName: "keyboard")
                .font(.title2)
                .foregroundColor(.accentColor)

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
                        title: "⚠️ 冲突快捷键",
                        count: viewModel.conflictShortcuts.count,
                        shortcuts: viewModel.conflictShortcuts,
                        isConflict: true
                    )
                }

                // 常用快捷键
                if !viewModel.normalShortcuts.isEmpty {
                    shortcutSection(
                        title: "📝 常用快捷键",
                        count: viewModel.normalShortcuts.count,
                        shortcuts: viewModel.normalShortcuts,
                        isConflict: false
                    )
                }
            }
            .padding()
        }
    }

    private func shortcutSection(title: String, count: Int, shortcuts: [ShortcutInfo], isConflict: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title) (\(count))")
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
        HStack {
            Text(shortcut.keyCombination)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 80, alignment: .leading)

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

            if isConflict {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isConflict ? Color.orange.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .sheet(isPresented: $showingRemappingDialog) {
            if let shortcut = selectedShortcut {
                RemappingDialogView(shortcut: shortcut, isPresented: $showingRemappingDialog)
            }
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

    private let remappingManager = RemappingManager.shared

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("重映射快捷键")
                .font(.title2)
                .fontWeight(.semibold)

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

                TextField("例如: ⇧⌘T", text: $newKeyCombination)
                    .font(.system(.title3, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 4)

                Text("提示: 使用 ⌘(Command) ⇧(Shift) ⌥(Option) ⌃(Control) + 字母/数字")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
        .frame(width: 450)
    }

    private func applyRemapping() {
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

        // 添加重映射
        if remappingManager.addRemapping(rule) {
            print("✅ 重映射成功: \(rule.fromKey) → \(rule.toKey)")
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
        // 移除现有的重映射
        if remappingManager.isRemapped(shortcut.keyCombination, in: shortcut.application) {
            let rule = RemappingRule(
                fromKey: shortcut.keyCombination,
                toKey: "",
                bundleId: shortcut.application
            )
            remappingManager.removeRemapping(rule)

            print("🗑 已移除重映射: \(shortcut.keyCombination)")
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
}
