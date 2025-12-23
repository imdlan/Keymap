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
    private var autoCloseTimer: Timer?
    
    // 设置管理器
    private let settings = SettingsManager.shared

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
            styleMask: [.borderless, .nonactivatingPanel],  // ✅ 添加 nonactivatingPanel
            backing: .buffered,
            defer: false
        )

        panelWindow?.isFloatingPanel = true
        panelWindow?.level = .floating
        panelWindow?.backgroundColor = .clear
        panelWindow?.isOpaque = false
        panelWindow?.hasShadow = true
        panelWindow?.contentView = hostingView
        
        // ✅ 关键：确保窗口可以成为主窗口并接收事件
        panelWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panelWindow?.hidesOnDeactivate = true  // ✅ 失去焦点时自动隐藏
        panelWindow?.becomesKeyOnlyIfNeeded = false  // 强制成为 key window

        // 启用窗口拖动
        panelWindow?.isMovableByWindowBackground = true

        // 设置窗口代理
        panelWindow?.delegate = self

        self.window = panelWindow
        
        // ✅ 监听窗口失去主窗口状态（点击外部区域时）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowResignMain),
            name: NSWindow.didResignMainNotification,
            object: panelWindow
        )
    }
    
    // MARK: - 窗口状态监听
    
    @objc private func handleWindowResignMain(_ notification: Notification) {
        // 窗口失去主窗口状态时，清理资源
        print("📤 快捷键面板失去焦点，清理资源")
        removeEscapeMonitor()
        stopAutoCloseTimer()
    }

    // MARK: - 面板显示

    func showPanel() {
        print("🎯 ShortcutPanelController.showPanel 被调用")
        guard let window = panelWindow else {
            print("❌ panelWindow 为 nil")
            return
        }

        // ✅ 在激活 Keymap 之前先获取前台应用（避免获取到 Keymap 自己）
        let previousFrontmostApp = NSWorkspace.shared.frontmostApplication
        print("📱 打开面板前的前台应用: \(previousFrontmostApp?.localizedName ?? "nil")")

        // ✅ 激活应用（确保应用在前台）
        NSApp.activate(ignoringOtherApps: true)

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

        // ✅ 显示窗口并立即成为主窗口
        window.makeKeyAndOrderFront(nil)
        
        // ✅ 再次确保窗口成为 key window
        window.makeKey()
        
        print("✅ 窗口已显示")

        // 检查窗口状态
        print("👁️ 窗口是否可见: \(window.isVisible)")
        print("🔑 窗口是否为主窗口: \(window.isKeyWindow)")
        
        // ✅ 立即在后台加载数据，传入激活前的前台应用
        if let viewModel = hostingView?.rootView.viewModel {
            viewModel.loadCurrentAppShortcuts(targetApp: previousFrontmostApp)
            print("📋 开始加载快捷键数据（后台线程）")
        }

        // 设置ESC监听器
        setupEscapeMonitor()
        
        // 设置自动关闭定时器
        setupAutoCloseTimer()
    }

    /// 显示指定应用的快捷键面板
    func showPanel(for bundleId: String) {
        print("📱 准备显示应用快捷键: \(bundleId)")
        
        guard let window = panelWindow else {
            print("⚠️ 面板窗口未初始化")
            return
        }
        
        // 获取应用名称
        let runningApps = NSWorkspace.shared.runningApplications
        let appName = runningApps.first(where: { $0.bundleIdentifier == bundleId })?.localizedName ?? bundleId
        
        print("📱 应用名称: \(appName)")
        
        // 创建新的 ViewModel 并设置目标应用
        let viewModel = ShortcutPanelViewModel()
        viewModel.loadShortcuts(for: bundleId, appName: appName)
        
        // 创建新的面板视图
        let panelView = ShortcutPanelView(viewModel: viewModel)
        let newHostingView = NSHostingView(rootView: panelView)
        
        // 替换内容视图
        window.contentView = newHostingView
        hostingView = newHostingView
        
        // 激活应用并显示面板
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        // 设置ESC键监听
        setupEscapeMonitor()
        
        // 设置自动关闭定时器
        setupAutoCloseTimer()
        
        print("✅ 面板已显示，内容为应用: \(appName)")
    }

    func hidePanel() {
        panelWindow?.orderOut(nil)
        removeEscapeMonitor()
        stopAutoCloseTimer()
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
    
    // MARK: - 自动关闭定时器
    
    private func setupAutoCloseTimer() {
        // 先停止已有的定时器
        stopAutoCloseTimer()
        
        // 获取延迟时间
        let delay = settings.panelAutoCloseDelay
        
        // 如果延迟为0，不启动定时器
        guard delay > 0 else {
            print("ℹ️ 面板自动关闭功能已禁用")
            return
        }
        
        print("⏰ 面板将在 \(Int(delay)) 秒后自动关闭")
        
        // 创建定时器
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.autoClose()
        }
    }
    
    private func stopAutoCloseTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }
    
    private func autoClose() {
        print("⏰ 面板自动关闭")
        hidePanel()
    }

    deinit {
        removeEscapeMonitor()
        stopAutoCloseTimer()
        NotificationCenter.default.removeObserver(self)
    }
}
