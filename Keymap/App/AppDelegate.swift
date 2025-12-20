//
//  AppDelegate.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var shortcutPanelController: ShortcutPanelController?
    private var globalMonitor: GlobalEventMonitor?

    // 窗口管理
    private var statisticsWindow: StatisticsWindow?
    private var settingsWindow: SettingsWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏Dock图标，使应用成为菜单栏应用
        NSApp.setActivationPolicy(.accessory)

        print("🚀 应用启动中...")

        // 1. 检查并申请权限
        PermissionManager.shared.checkAndRequestPermissions()

        // 2. 创建菜单栏图标
        setupMenuBar()

        // 3. 初始化快捷键面板控制器
        shortcutPanelController = ShortcutPanelController()

        // 4. 初始化全局监控（无论是否有权限都尝试启动，会自动请求权限）
        print("🔍 检查辅助功能权限状态...")
        let hasPermission = PermissionManager.shared.hasAccessibilityPermission()
        print("📋 辅助功能权限: \(hasPermission ? "✅ 已授予" : "❌ 未授予")")

        if !hasPermission {
            print("⚠️ 警告: 应用需要辅助功能权限才能监控键盘事件")
            print("⚠️ 请前往: 系统设置 → 隐私与安全性 → 辅助功能")
            print("⚠️ 勾选 Keymap.app")

            // 显示提示通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let notification = NSUserNotification()
                notification.title = "需要辅助功能权限"
                notification.informativeText = "请在系统设置中授予Keymap辅助功能权限"
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.default.deliver(notification)
            }
        }

        // 无论权限状态如何都尝试启动，这样可以触发权限请求
        setupGlobalMonitoring()

        // 5. 监听权限变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(permissionStatusChanged),
            name: .permissionStatusChanged,
            object: nil
        )

        // 6. 监听窗口打开请求
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showStatistics),
            name: .showStatisticsWindow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSettings),
            name: .showSettingsWindow,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalMonitor?.stopMonitoring()
    }

    // MARK: - 菜单栏设置

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keymap")
            button.image?.isTemplate = true
        }

        // 创建菜单
        let menu = NSMenu()

        // 权限状态提示（如果没有权限）
        let hasPermission = PermissionManager.shared.hasAccessibilityPermission()
        print("📊 setupMenuBar - 权限状态: \(hasPermission ? "✅ 已授予" : "❌ 未授予")")

        if !hasPermission {
            let permissionItem = NSMenuItem(
                title: "⚠️ 需要辅助功能权限",
                action: #selector(openSystemPreferences),
                keyEquivalent: ""
            )
            permissionItem.toolTip = "点击打开系统设置授予权限"
            menu.addItem(permissionItem)
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(NSMenuItem(
            title: "显示快捷键面板",
            action: #selector(showShortcutPanel),
            keyEquivalent: "s"
        ))

        menu.addItem(NSMenuItem(
            title: "统计分析",
            action: #selector(showStatistics),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "设置...",
            action: #selector(showSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(
            title: "关于 Keymap",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "退出 Keymap",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    // MARK: - 全局监控设置

    private func setupGlobalMonitoring() {
        print("🚀 开始设置全局监控...")
        globalMonitor = GlobalEventMonitor.shared
        globalMonitor?.startMonitoring()

        // 监听双击Cmd事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDoubleCmdPressed),
            name: .doubleCmdPressed,
            object: nil
        )
        print("✅ 全局监控设置完成")
    }

    // MARK: - 事件处理

    @objc private func handleDoubleCmdPressed() {
        print("📢 AppDelegate收到双击Cmd通知，准备显示面板...")
        shortcutPanelController?.showPanel()
        print("✅ showPanel方法已调用")
    }

    @objc private func permissionStatusChanged() {
        print("📢 权限状态变化通知收到")
        if PermissionManager.shared.hasAccessibilityPermission() {
            print("✅ 权限已授予，准备启动全局监控")
            // 确保监控对象存在
            if globalMonitor == nil {
                globalMonitor = GlobalEventMonitor.shared
            }
            // 无论监控对象是否已存在，都尝试启动（startMonitoring内部会检查是否已运行）
            globalMonitor?.startMonitoring()
            print("✅ 全局监控启动完成")
        } else {
            print("⚠️ 权限未授予，停止全局监控")
            globalMonitor?.stopMonitoring()
            globalMonitor = nil
        }

        // 重新构建菜单以更新权限状态提示
        setupMenuBar()
    }

    // MARK: - 菜单操作

    @objc private func showShortcutPanel() {
        shortcutPanelController?.showPanel()
    }

    @objc private func showStatistics() {
        // 隐藏快捷键面板
        shortcutPanelController?.hidePanel()

        // 如果窗口已存在，直接显示
        if let window = statisticsWindow {
            window.showWindow()
            return
        }

        // 创建新窗口
        statisticsWindow = StatisticsWindow()
        statisticsWindow?.showWindow()
    }

    @objc private func showSettings() {
        // 隐藏快捷键面板
        shortcutPanelController?.hidePanel()

        // 如果窗口已存在，直接显示
        if let window = settingsWindow {
            window.showWindow()
            return
        }

        // 创建新窗口
        settingsWindow = SettingsWindow()
        settingsWindow?.showWindow()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func openSystemPreferences() {
        PermissionManager.shared.openSystemPreferences()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
