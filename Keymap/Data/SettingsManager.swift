//
//  SettingsManager.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation
import AppKit

/// 应用设置管理器（使用UserDefaults持久化）
class SettingsManager {

    // MARK: - Singleton

    static let shared = SettingsManager()

    // MARK: - Properties

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let doubleCmdThreshold = "doubleCmdThreshold"
        static let triggerKey = "triggerKey"
        static let enableRealTimeDetection = "enableRealTimeDetection"
        static let enableUsageTracking = "enableUsageTracking"
        static let cacheDuration = "cacheDuration"
        static let maxCachedApps = "maxCachedApps"
        static let launchAtLogin = "launchAtLogin"
        static let showInDock = "showInDock"
        static let showNotifications = "showNotifications"
        static let conflictNotificationLevel = "conflictNotificationLevel"
        static let cleanupInterval = "cleanupInterval"
    }

    // MARK: - Initialization

    private init() {
        // 注册默认值
        registerDefaults()
    }

    // MARK: - General Settings

    /// 双击Cmd阈值（秒）
    var doubleCmdThreshold: TimeInterval {
        get {
            let value = defaults.double(forKey: Keys.doubleCmdThreshold)
            return value > 0 ? value : 0.3
        }
        set {
            defaults.set(newValue, forKey: Keys.doubleCmdThreshold)
            print("⚙️ 双击Cmd阈值已设置为: \(newValue)秒")
        }
    }

    /// 开机自动启动
    var launchAtLogin: Bool {
        get {
            return defaults.bool(forKey: Keys.launchAtLogin)
        }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            print("⚙️ 开机自动启动: \(newValue ? "开启" : "关闭")")
        }
    }

    /// 在Dock显示图标
    var showInDock: Bool {
        get {
            // 默认值为 true（显示在 Dock）
            return defaults.object(forKey: Keys.showInDock) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: Keys.showInDock)
            print("⚙️ Dock图标显示: \(newValue ? "开启" : "关闭")")

            // 立即应用更改
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(newValue ? .regular : .accessory)
            }
        }
    }

    /// 触发快捷键类型（doubleCmd, doubleOption, doubleControl）
    var triggerKey: String {
        get {
            return defaults.string(forKey: Keys.triggerKey) ?? "doubleCmd"
        }
        set {
            defaults.set(newValue, forKey: Keys.triggerKey)
            print("⚙️ 触发快捷键已设置为: \(newValue)")
        }
    }

    // MARK: - Detection Settings

    /// 实时冲突检测开关
    var enableRealTimeDetection: Bool {
        get {
            return defaults.bool(forKey: Keys.enableRealTimeDetection)
        }
        set {
            defaults.set(newValue, forKey: Keys.enableRealTimeDetection)
            print("⚙️ 实时冲突检测: \(newValue ? "开启" : "关闭")")

            // 发送通知（其他组件可以监听此通知）
            NotificationCenter.default.post(
                name: .settingsChanged,
                object: nil,
                userInfo: ["key": Keys.enableRealTimeDetection, "value": newValue]
            )
        }
    }

    /// 冲突通知级别（low, medium, high）
    var conflictNotificationLevel: ConflictSeverity {
        get {
            let rawValue = defaults.string(forKey: Keys.conflictNotificationLevel) ?? "medium"
            return ConflictSeverity(rawValue: rawValue) ?? .medium
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.conflictNotificationLevel)
            print("⚙️ 冲突通知级别已设置为: \(newValue.rawValue)")
        }
    }

    /// 显示通知
    var showNotifications: Bool {
        get {
            return defaults.bool(forKey: Keys.showNotifications)
        }
        set {
            defaults.set(newValue, forKey: Keys.showNotifications)
            print("⚙️ 显示通知: \(newValue ? "开启" : "关闭")")
        }
    }

    // MARK: - Usage Tracking Settings

    /// 使用统计追踪开关
    var enableUsageTracking: Bool {
        get {
            return defaults.bool(forKey: Keys.enableUsageTracking)
        }
        set {
            defaults.set(newValue, forKey: Keys.enableUsageTracking)
            print("⚙️ 使用统计追踪: \(newValue ? "开启" : "关闭")")

            NotificationCenter.default.post(
                name: .settingsChanged,
                object: nil,
                userInfo: ["key": Keys.enableUsageTracking, "value": newValue]
            )
        }
    }

    /// 数据清理间隔（天）
    var cleanupInterval: Int {
        get {
            let value = defaults.integer(forKey: Keys.cleanupInterval)
            return value > 0 ? value : 90
        }
        set {
            defaults.set(newValue, forKey: Keys.cleanupInterval)
            print("⚙️ 数据清理间隔已设置为: \(newValue)天")
        }
    }

    // MARK: - Cache Settings

    /// 缓存时长（小时）
    var cacheDuration: Int {
        get {
            let value = defaults.integer(forKey: Keys.cacheDuration)
            return value > 0 ? value : 24
        }
        set {
            defaults.set(newValue, forKey: Keys.cacheDuration)
            print("⚙️ 缓存时长已设置为: \(newValue)小时")
        }
    }

    /// 最大缓存应用数
    var maxCachedApps: Int {
        get {
            let value = defaults.integer(forKey: Keys.maxCachedApps)
            return value > 0 ? value : 50
        }
        set {
            defaults.set(newValue, forKey: Keys.maxCachedApps)
            print("⚙️ 最大缓存应用数已设置为: \(newValue)")
        }
    }

    // MARK: - Methods

    /// 注册默认值
    private func registerDefaults() {
        let defaults: [String: Any] = [
            Keys.doubleCmdThreshold: 0.3,
            Keys.triggerKey: "doubleCmd",
            Keys.enableRealTimeDetection: true,
            Keys.enableUsageTracking: true,
            Keys.cacheDuration: 24,
            Keys.maxCachedApps: 50,
            Keys.launchAtLogin: false,
            Keys.showNotifications: true,
            Keys.conflictNotificationLevel: "medium",
            Keys.cleanupInterval: 90
        ]

        self.defaults.register(defaults: defaults)
        print("⚙️ 默认设置已注册")
    }

    /// 重置所有设置为默认值
    func resetToDefaults() {
        doubleCmdThreshold = 0.3
        triggerKey = "doubleCmd"
        enableRealTimeDetection = true
        enableUsageTracking = true
        cacheDuration = 24
        maxCachedApps = 50
        launchAtLogin = false
        showNotifications = true
        conflictNotificationLevel = .medium
        cleanupInterval = 90

        print("🔄 所有设置已重置为默认值")
    }

    /// 导出设置（用于备份）
    func exportSettings() -> [String: Any] {
        return [
            Keys.doubleCmdThreshold: doubleCmdThreshold,
            Keys.triggerKey: triggerKey,
            Keys.enableRealTimeDetection: enableRealTimeDetection,
            Keys.enableUsageTracking: enableUsageTracking,
            Keys.cacheDuration: cacheDuration,
            Keys.maxCachedApps: maxCachedApps,
            Keys.launchAtLogin: launchAtLogin,
            Keys.showNotifications: showNotifications,
            Keys.conflictNotificationLevel: conflictNotificationLevel.rawValue,
            Keys.cleanupInterval: cleanupInterval
        ]
    }

    /// 导入设置（从备份恢复）
    func importSettings(_ settings: [String: Any]) {
        if let threshold = settings[Keys.doubleCmdThreshold] as? Double {
            doubleCmdThreshold = threshold
        }
        if let trigger = settings[Keys.triggerKey] as? String {
            triggerKey = trigger
        }
        if let detection = settings[Keys.enableRealTimeDetection] as? Bool {
            enableRealTimeDetection = detection
        }
        if let tracking = settings[Keys.enableUsageTracking] as? Bool {
            enableUsageTracking = tracking
        }
        if let duration = settings[Keys.cacheDuration] as? Int {
            cacheDuration = duration
        }
        if let maxApps = settings[Keys.maxCachedApps] as? Int {
            maxCachedApps = maxApps
        }
        if let launch = settings[Keys.launchAtLogin] as? Bool {
            launchAtLogin = launch
        }
        if let notifications = settings[Keys.showNotifications] as? Bool {
            showNotifications = notifications
        }
        if let levelString = settings[Keys.conflictNotificationLevel] as? String,
           let level = ConflictSeverity(rawValue: levelString) {
            conflictNotificationLevel = level
        }
        if let interval = settings[Keys.cleanupInterval] as? Int {
            cleanupInterval = interval
        }

        print("✅ 设置已导入")
    }

    /// 获取设置摘要（用于调试）
    func printSettings() {
        print("""
        📋 当前设置:
        - 双击Cmd阈值: \(doubleCmdThreshold)秒
        - 开机自动启动: \(launchAtLogin ? "是" : "否")
        - 实时冲突检测: \(enableRealTimeDetection ? "开启" : "关闭")
        - 冲突通知级别: \(conflictNotificationLevel.rawValue)
        - 显示通知: \(showNotifications ? "是" : "否")
        - 使用统计追踪: \(enableUsageTracking ? "开启" : "关闭")
        - 数据清理间隔: \(cleanupInterval)天
        - 缓存时长: \(cacheDuration)小时
        - 最大缓存应用数: \(maxCachedApps)
        """)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// 设置已更改通知
    static let settingsChanged = Notification.Name("com.keymap.settingsChanged")
}
