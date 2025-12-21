//
//  ShortcutPanelController.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import AppKit
import SwiftUI

// 自定义Panel，支持键盘事件
class KeyboardPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

class ShortcutPanelController: NSWindowController, NSWindowDelegate {
    private var panelWindow: KeyboardPanel?
    private var hostingView: NSHostingView<ShortcutPanelView>?
    private var escapeMonitor: Any?

    init() {
        super.init(window: nil)
        setupPanel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 面板设置

    private func setupPanel() {
        // 创建SwiftUI视图
        let viewModel = ShortcutPanelViewModel()
        let contentView = ShortcutPanelView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: contentView)

        // 创建半透明窗口（无标题栏）
        panelWindow = KeyboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.borderless],  // 移除标题栏
            backing: .buffered,
            defer: false
        )

        panelWindow?.isFloatingPanel = true
        panelWindow?.level = .floating  // 改用 floating 层级，确保窗口在其他窗口之上
        panelWindow?.backgroundColor = .clear
        panelWindow?.isOpaque = false
        panelWindow?.hasShadow = true
        panelWindow?.contentView = hostingView

        // 启用窗口拖动
        panelWindow?.isMovableByWindowBackground = true

        // 设置窗口代理
        panelWindow?.delegate = self

        self.window = panelWindow
    }

    // MARK: - 面板显示

    func showPanel() {
        print("🎯 ShortcutPanelController.showPanel 被调用")
        guard let window = panelWindow else {
            print("❌ panelWindow 为 nil")
            return
        }

        // 获取屏幕可见区域
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        // 计算窗口在屏幕中心的位置
        var origin = NSPoint.zero
        origin.x = screenFrame.midX - window.frame.width / 2
        origin.y = screenFrame.midY - window.frame.height / 2

        window.setFrameOrigin(origin)
        print("📍 窗口位置已设置（屏幕居中）: \(origin)")
        print("🪟 窗口大小: \(window.frame.size)")
        print("🎚️ 窗口层级: \(window.level.rawValue)")

        // 更新视图数据
        if let viewModel = hostingView?.rootView.viewModel {
            viewModel.loadCurrentAppShortcuts()
            print("📋 开始加载快捷键数据")
        }

        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // 检查窗口是否真的可见
        print("👁️ 窗口是否可见: \(window.isVisible)")
        print("🔑 窗口是否为主窗口: \(window.isKeyWindow)")
        print("✅ 窗口已显示")

        // 设置ESC监听器
        setupEscapeMonitor()
    }

    func hidePanel() {
        panelWindow?.orderOut(nil)
        removeEscapeMonitor()
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 允许窗口关闭，但只是隐藏而不是销毁
        hidePanel()
        return false  // 返回 false 防止窗口被销毁
    }

    // MARK: - ESC键监听

    private func setupEscapeMonitor() {
        // 移除旧的监听器
        removeEscapeMonitor()

        // 添加新的监听器
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // 检查是否是ESC键并且当前窗口是快捷键面板
            if event.keyCode == 53 && self.panelWindow?.isKeyWindow == true {
                print("⌨️ 检测到ESC键，关闭快捷键面板")
                self.hidePanel()
                return nil // 拦截事件
            }
            return event
        }
    }

    private func removeEscapeMonitor() {
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }

    deinit {
        removeEscapeMonitor()
    }
}
