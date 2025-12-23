//
//  GlobalEventMonitor.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Carbon
import Cocoa

class GlobalEventMonitor {
    static let shared = GlobalEventMonitor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let doubleCmdDetector = DoubleCmdDetector()
    private let keyCombinationDetector = KeyCombinationDetector()

    // 冲突检测组件
    private let conflictDetector = ConflictDetector()

    // 数据持久化组件
    private let usageRepository = UsageRepository()
    private let settings = SettingsManager.shared

    // 快捷键重映射组件
    private let remappingManager = RemappingManager.shared

    // 全局快捷键数据库
    private let globalDatabase = GlobalShortcutDatabase.shared

    // 缓存所有已知快捷键（用于实时冲突检测）
    private var allShortcuts: [ShortcutInfo] = []

    private init() {
        // 监听应用启动/退出通知
        setupApplicationLifecycleObservers()
    }

    // MARK: - 监控控制

    func startMonitoring() {
        // 确保在主线程上运行，避免RunLoop问题
        guard Thread.isMainThread else {
            print("⚠️ startMonitoring 必须在主线程调用，正在切换到主线程...")
            DispatchQueue.main.async {
                self.startMonitoring()
            }
            return
        }

        print("🔍 开始启动全局监控...")
        print("🔍 检查辅助功能权限...")

        guard checkAccessibilityPermission() else {
            print("⚠️ 需要辅助功能权限才能启动全局监控")
            return
        }
        print("✅ 辅助功能权限检查通过")

        guard eventTap == nil else {
            print("ℹ️ 全局监控已经在运行")
            return
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.keyUp.rawValue) |
                       (1 << CGEventType.flagsChanged.rawValue)

        print("🔍 创建事件监听tap...")
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<GlobalEventMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("❌ 创建事件监听失败 - 可能需要重启应用或重新授予权限")
            return
        }
        print("✅ 事件监听tap创建成功")

        self.eventTap = eventTap

        // 使用主线程的 RunLoop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            print("✅ 全局监控已启动")
            
            // 启动全局快捷键数据库扫描
            Task {
                await globalDatabase.scanRunningApplications()
            }
        } else {
            print("❌ 创建RunLoop源失败")
        }
    }

    func stopMonitoring() {
        // 确保在主线程上运行
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.stopMonitoring()
            }
            return
        }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
            print("🛑 全局监控已停止")
        }
    }

    // MARK: - 事件处理

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 1. 检测双击Cmd
        if type == .flagsChanged {
            print("🎯 收到flagsChanged事件")
            if doubleCmdDetector.detectDoubleCmdPress(event: event) {
                print("⌘ 检测到双击修饰键，发送通知...")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .doubleCmdPressed, object: nil)
                    print("✅ 双击修饰键通知已发送")
                }
            }
        }

        // 2. 检测快捷键组合并处理重映射
        if type == .keyDown {
            if let keyCombination = keyCombinationDetector.detectKeyCombination(event: event) {
                // 2.1 检查是否启用了重映射功能
                if settings.enableGlobalRemapping {
                    // 检查是否有重映射规则
                    if let remappedEvent = checkAndApplyRemapping(keyCombination: keyCombination, originalEvent: event) {
                        // 已重映射，返回新事件
                        print("🔀 快捷键已重映射: \(keyCombination.displayString)")
                        return Unmanaged.passRetained(remappedEvent)
                    }
                }

                // 2.2 正常处理快捷键（记录、冲突检测等）
                handleShortcutDetected(keyCombination)
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func handleShortcutDetected(_ keyCombination: KeyCombination) {
        // 获取当前应用
        guard let currentApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = currentApp.bundleIdentifier else {
            return
        }

        let appName = currentApp.localizedName ?? bundleId
        print("⌨️ 检测到快捷键: \(keyCombination.displayString) - \(appName)")

        // 1. 发送快捷键检测通知
        NotificationCenter.default.post(
            name: .shortcutDetected,
            object: nil,
            userInfo: [
                "keyCombination": keyCombination.displayString,
                "application": appName
            ]
        )

        // 2. 实时冲突检测
        Task {
            let conflicts = await detectRealTimeConflict(
                keyCombination: keyCombination.displayString,
                currentApp: appName
            )

            if !conflicts.isEmpty {
                // 检查是否启用冲突通知
                if settings.showConflictNotifications {
                    // 发送冲突通知
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .conflictFound,
                            object: nil,
                            userInfo: [
                                "conflicts": conflicts,
                                "keyCombination": keyCombination.displayString
                            ]
                        )
                    }
                    
                    print("⚠️ 检测到 \(conflicts.count) 个冲突，已发送通知")
                } else {
                    print("ℹ️ 检测到 \(conflicts.count) 个冲突，但通知已禁用")
                }
            }
        }

        // 3. 记录使用统计
        recordUsageStatistics(keyCombination, bundleId: bundleId)
    }

    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    // MARK: - 冲突检测

    /// 实时检测冲突（使用全局数据库）
    /// - Parameters:
    ///   - keyCombination: 快捷键组合
    ///   - currentApp: 当前应用名称
    /// - Returns: 冲突信息数组
    private func detectRealTimeConflict(
        keyCombination: String,
        currentApp: String
    ) async -> [ConflictInfo] {
        // 获取当前应用的 Bundle ID
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let currentBundleId = frontApp.bundleIdentifier else {
            return []
        }
        
        // 从全局数据库查询使用该快捷键的所有应用
        let conflictingApps = globalDatabase.detectConflicts(
            for: keyCombination,
            currentApp: currentBundleId
        )
        
        if conflictingApps.isEmpty {
            return []
        }
        
        print("⚠️ 检测到 \(conflictingApps.count) 个冲突应用: \(conflictingApps.map { $0.appName }.joined(separator: ", "))")
        
        // 构建冲突信息
        var conflicts: [ConflictInfo] = []
        
        for entry in conflictingApps {
            let conflict = ConflictInfo(
                shortcutId: entry.shortcut.id,
                conflictType: entry.isBackgroundApp ? .global : .application,
                conflictingApp: entry.appName,
                severity: entry.isBackgroundApp ? .high : .medium,
                suggestions: generateConflictSuggestions(
                    keyCombination: keyCombination,
                    currentApp: currentApp,
                    conflictingApp: entry.appName,
                    isBackgroundApp: entry.isBackgroundApp
                )
            )
            conflicts.append(conflict)
        }
        
        return conflicts
    }
    
    /// 生成冲突解决建议
    private func generateConflictSuggestions(
        keyCombination: String,
        currentApp: String,
        conflictingApp: String,
        isBackgroundApp: Bool
    ) -> [String] {
        var suggestions: [String] = []
        
        if isBackgroundApp {
            suggestions.append("快捷键 \(keyCombination) 与长驻应用 \(conflictingApp) 的全局热键冲突")
            suggestions.append("建议在 \(conflictingApp) 的设置中修改其全局热键")
            suggestions.append("或在 Keymap 中将 \(currentApp) 的 \(keyCombination) 重映射为其他快捷键")
        } else {
            suggestions.append("快捷键 \(keyCombination) 同时被 \(currentApp) 和 \(conflictingApp) 使用")
            suggestions.append("仅当两个应用同时运行时可能产生冲突")
            suggestions.append("可以使用快捷键重映射功能避免冲突")
        }
        
        return suggestions
    }

    /// 更新已知快捷键列表（供实时冲突检测使用）
    /// - Parameter shortcuts: 快捷键列表
    public func updateShortcuts(_ shortcuts: [ShortcutInfo]) {
        allShortcuts = shortcuts
        print("📝 已更新快捷键列表: \(shortcuts.count) 个")
    }

    // MARK: - 使用统计

    /// 记录快捷键使用统计
    /// - Parameters:
    ///   - keyCombination: 快捷键组合
    ///   - bundleId: 应用Bundle ID
    private func recordUsageStatistics(_ keyCombination: KeyCombination, bundleId: String) {
        // 检查设置是否开启使用统计
        guard settings.enableUsageTracking else {
            return
        }

        // 创建使用记录
        let record = UsageRecord(
            shortcutKey: keyCombination.displayString,
            application: bundleId,
            context: .normal
        )

        // 异步保存到数据库
        Task {
            _ = usageRepository.recordUsage(record)
        }
    }

    // MARK: - 快捷键重映射

    /// 检查并应用快捷键重映射
    /// - Parameters:
    ///   - keyCombination: 原始快捷键组合
    ///   - originalEvent: 原始事件
    /// - Returns: 重映射后的事件，如果没有重映射则返回nil
    private func checkAndApplyRemapping(keyCombination: KeyCombination, originalEvent: CGEvent) -> CGEvent? {
        // 获取当前应用
        guard let currentApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = currentApp.bundleIdentifier else {
            return nil
        }

        // 检查是否有重映射规则
        guard let remappedKeyString = remappingManager.getRemappedKey(
            keyCombination.displayString,
            for: bundleId
        ) else {
            return nil
        }

        // 解析重映射后的快捷键
        guard let remappedKey = remappingManager.parseKeyCombination(remappedKeyString) else {
            print("⚠️ 无法解析重映射快捷键: \(remappedKeyString)")
            return nil
        }

        // 创建新的键盘事件
        guard let newEvent = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(remappedKey.keyCode),
            keyDown: true
        ) else {
            return nil
        }

        // 设置修饰键
        newEvent.flags = remappedKey.modifiers

        print("🔀 \(keyCombination.displayString) → \(remappedKeyString) (\(bundleId))")
        return newEvent
    }
    
    // MARK: - 应用生命周期监听
    
    /// 设置应用启动/退出通知监听
    private func setupApplicationLifecycleObservers() {
        let workspace = NSWorkspace.shared
        
        // 监听应用启动
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        // 监听应用退出
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
        
        print("✅ 应用生命周期监听器已设置")
    }
    
    @objc private func applicationDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else {
            return
        }
        
        print("🚀 应用启动: \(app.localizedName ?? bundleId)")
        
        // 异步加载应用快捷键
        Task {
            await globalDatabase.loadShortcuts(for: app)
        }
    }
    
    @objc private func applicationDidTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else {
            return
        }
        
        print("🛑 应用退出: \(app.localizedName ?? bundleId)")
        
        // 移除应用快捷键
        globalDatabase.removeShortcuts(for: bundleId)
    }
}
