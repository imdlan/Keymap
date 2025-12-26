//
//  AppDelegate.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import AppKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var shortcutPanelController: ShortcutPanelController?
    private var globalMonitor: GlobalEventMonitor?

    // 窗口管理
    private var statisticsWindow: StatisticsWindow?
    private var settingsWindow: SettingsWindow?
    
    // 菜单项引用（用于动态更新）
    private var showPanelMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 0. 初始化本地化管理器（必须最先执行，确保所有UI使用正确语言）
        _ = LocalizationManager.shared

        // ✅ 完全移除主菜单栏（只保留苹果菜单）
        setupEmptyMenuBar()

        // 根据设置决定是否在Dock显示图标
        let showInDock = SettingsManager.shared.showInDock
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        print("🚀 应用启动中...")

        // 1. 执行数据库迁移（如果需要）
        if EnumMigration.needsMigration() {
            print("🔄 检测到需要迁移数据库枚举值...")
            
            // 显示迁移统计
            let stats = EnumMigration.getMigrationStatistics()
            print(stats.description)
            
            do {
                try EnumMigration.migrate()
                print("✅ 数据库迁移完成")
            } catch {
                print("❌ 数据库迁移失败: \(error.localizedDescription)")
                print("⚠️ 应用可能无法正常工作，请检查日志")
            }
        } else {
            print("✅ 数据库无需迁移（已经是最新版本）")
        }

        // 2. 检查并申请权限
        PermissionManager.shared.checkAndRequestPermissions()

        // 3. 创建菜单栏图标
        setupMenuBar()

        // 4. 初始化快捷键面板控制器
        shortcutPanelController = ShortcutPanelController()

        // 5. 初始化全局监控（无论是否有权限都尝试启动，会自动请求权限）
        print("🔍 检查辅助功能权限状态...")
        let hasPermission = PermissionManager.shared.hasAccessibilityPermission()
        print("📋 辅助功能权限: \(hasPermission ? "✅ 已授予" : "❌ 未授予")")

        if !hasPermission {
            print("⚠️ 警告: 应用需要辅助功能权限才能监控键盘事件")
            print("⚠️ 请前往: 系统设置 → 隐私与安全性 → 辅助功能")
            print("⚠️ 勾选 Keymap.app")

            // 延迟2秒发送通知，确保通知权限已授予
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // 检查通知权限状态
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .authorized {
                        print("✅ 通知权限已授予，发送提示通知")
                        NotificationHelper.shared.send(
                            title: "notification.permission.title".localized(),
                            message: "notification.permission.message".localized()
                        )
                    } else {
                        print("❌ 通知权限未授予: \(settings.authorizationStatus.rawValue)")
                    }
                }
            }
        }

        // 无论权限状态如何都尝试启动，这样可以触发权限请求
        setupGlobalMonitoring()

        // 6. 监听权限变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(permissionStatusChanged),
            name: .permissionStatusChanged,
            object: nil
        )

        // 7. 监听窗口打开请求
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
        
        // 8. 监听快捷键冲突通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConflictFound),
            name: .conflictFound,
            object: nil
        )
        
        // 9. 添加全局快捷键监听器
        setupGlobalShortcuts()
        
        // 10. 监听触发快捷键设置变化以更新菜单
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenuBarShortcut),
            name: .triggerKeyChanged,
            object: nil
        )
        
        // 11. 监听语言切换以更新菜单
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenusForLanguageChange),
            name: .languageChanged,
            object: nil
        )
        
        // 12. 监听显示指定应用快捷键的请求
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowShortcutsForApp),
            name: Notification.Name("ShowShortcutsForApp"),
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalMonitor?.stopMonitoring()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当用户点击 Dock 图标时，检查权限后再显示快捷键面板
        print("📱 用户点击了 Dock 图标")

        // 检查是否有辅助功能权限
        if PermissionManager.shared.hasAccessibilityPermission() {
            // ✅ 强制激活应用到前台
            NSApp.activate(ignoringOtherApps: true)
            
            // ✅ 稍微延迟后显示面板，确保应用已激活
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.shortcutPanelController?.showPanel()
            }
        } else {
            print("⚠️ 没有辅助功能权限，提示用户授权")
            // 显示权限提示通知
            NotificationHelper.shared.send(
                title: "notification.permission.title".localized(),
                message: "notification.permission.message.dock".localized()
            )
            // 打开系统设置
            PermissionManager.shared.openSystemPreferences()
        }

        return true
    }

    // MARK: - 菜单栏设置
    
    /// 设置空的主菜单栏（移除所有菜单项）
    private func setupEmptyMenuBar() {
        // 创建一个空的主菜单
        let mainMenu = NSMenu()
        
        // 添加苹果菜单（系统要求）
        let appleMenuItem = NSMenuItem()
        let appleMenu = NSMenu()
        appleMenuItem.submenu = appleMenu
        mainMenu.addItem(appleMenuItem)
        
        // 只添加"关于"和"退出"
        appleMenu.addItem(NSMenuItem(title: "menu.about".localized(), action: #selector(showAbout), keyEquivalent: ""))
        appleMenu.addItem(NSMenuItem.separator())
        appleMenu.addItem(NSMenuItem(title: "menu.quit".localized(), action: #selector(quitApp), keyEquivalent: "q"))
        
        NSApp.mainMenu = mainMenu
        print("✅ 主菜单栏已移除")
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
        }

        // 创建菜单
        let menu = NSMenu()
        menu.autoenablesItems = true
        
        // 权限状态提示（如果没有权限）
        let hasPermission = PermissionManager.shared.hasAccessibilityPermission()
        print("📊 setupMenuBar - 权限状态: \(hasPermission ? "✅ 已授予" : "❌ 未授予")")

        if !hasPermission {
            let permissionItem = NSMenuItem(
                title: "menu.permission_warning".localized(),
                action: #selector(openSystemPreferences),
                keyEquivalent: ""
            )
            permissionItem.toolTip = "menu.permission_tooltip".localized()
            menu.addItem(permissionItem)
            menu.addItem(NSMenuItem.separator())
        }

        // 创建"显示快捷键面板"菜单项，添加动态快捷键显示
        let panelMenuItem = NSMenuItem(
            title: "menu.show_panel".localized(),
            action: #selector(showShortcutPanel),
            keyEquivalent: ""
        )
        updateMenuItemShortcutDisplay(panelMenuItem)
        menu.addItem(panelMenuItem)
        showPanelMenuItem = panelMenuItem

        menu.addItem(NSMenuItem(
            title: "menu.statistics".localized(),
            action: #selector(showStatistics),
            keyEquivalent: "d"
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "menu.settings".localized(),
            action: #selector(showSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(
            title: "menu.about_keymap".localized(),
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "menu.quit_keymap".localized(),
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    // MARK: - 全局快捷键设置
    
    private func setupGlobalShortcuts() {
        // 监听本地按键事件（在应用内有效）
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd+, 打开设置
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                self?.showSettings()
                return nil  // 阻止事件继续传播
            }
            
            // Cmd+D 打开统计
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "d" {
                self?.showStatistics()
                return nil  // 阻止事件继续传播
            }
            
            return event  // 其他按键正常传播
        }
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
    
    @objc private func handleShowShortcutsForApp(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let bundleId = userInfo["bundleId"] as? String else {
            print("⚠️ 无法获取应用Bundle ID")
            return
        }
        
        print("📋 准备显示应用快捷键: \(bundleId)")
        
        // 关闭设置窗口
        settingsWindow?.close()
        
        // 显示指定应用的快捷键面板
        shortcutPanelController?.showPanel(for: bundleId)
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

    /// 更新菜单栏快捷键显示
    @objc private func updateMenuBarShortcut() {
        guard let menuItem = showPanelMenuItem else { return }
        updateMenuItemShortcutDisplay(menuItem)
    }
    
    /// 更新菜单以响应语言切换
    @objc private func updateMenusForLanguageChange() {
        // 重新创建应用菜单
        setupEmptyMenuBar()
        
        // 重新创建状态栏菜单
        setupMenuBar()
    }
    
    /// 更新菜单项的快捷键显示
    private func updateMenuItemShortcutDisplay(_ menuItem: NSMenuItem) {
        let shortcutText = getTriggerKeyDisplay()
        menuItem.title = String(format: "menu.show_panel_with_key".localized(), shortcutText)
    }
    
    /// 获取触发快捷键的显示文字
    private func getTriggerKeyDisplay() -> String {
        let triggerKey = SettingsManager.shared.triggerKey
        switch triggerKey {
        case "doubleCmd":
            return "⌘⌘"
        case "doubleOption":
            return "⌥⌥"
        case "doubleControl":
            return "⌃⌃"
        default:
            return "⌘⌘"
        }
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

    @objc func showSettings() {
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
    
    @objc private func handleConflictFound(_ notification: Notification) {
        // 从通知中获取冲突信息
        guard let userInfo = notification.userInfo,
              let conflicts = userInfo["conflicts"] as? [ConflictInfo],
              let keyCombination = userInfo["keyCombination"] as? String else {
            return
        }
        
        print("⚠️ 收到冲突通知: \(keyCombination), \(conflicts.count) 个冲突")
        
        // 检查是否启用冲突通知
        guard SettingsManager.shared.showConflictNotifications else {
            print("ℹ️ 冲突通知已禁用，跳过显示")
            return
        }
        
        // 构建通知内容
        let firstConflict = conflicts.first!
        let title = "notification.conflict.title".localized()
        var message = "\(keyCombination) "
        
        switch firstConflict.conflictType {
        case .system:
            message += "notification.conflict.system".localized()
        case .global:
            message += String(format: "notification.conflict.global".localized(), firstConflict.conflictingApp ?? "Unknown")
        case .application:
            message += "notification.conflict.application".localized()
        case .functional:
            message += "notification.conflict.functional".localized()
        }
        
        if conflicts.count > 1 {
            message += String(format: "notification.conflict.multiple".localized(), conflicts.count)
        }
        
        // 显示系统通知（点击打开快捷键面板）
        NotificationHelper.shared.sendWithAction(
            title: title,
            message: message,
            actionTitle: "notification.conflict.view_details".localized(),
            userInfo: ["keyCombination": keyCombination]
        ) { [weak self] in
            // 用户点击通知 - 打开快捷键面板并聚焦到冲突
            DispatchQueue.main.async {
                self?.showShortcutPanelAndFocusConflict(keyCombination)
            }
        }
    }
    
    private func showShortcutPanelAndFocusConflict(_ keyCombination: String) {
        // 显示快捷键面板
        shortcutPanelController?.showPanel()
        
        // TODO: 通知 ViewModel 展开特定冲突（需要在 ViewModel 中添加方法）
        print("📋 打开快捷键面板并聚焦到冲突: \(keyCombination)")
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
