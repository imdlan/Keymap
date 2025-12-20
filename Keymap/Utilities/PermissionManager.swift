//
//  PermissionManager.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Cocoa
import ApplicationServices

extension Notification.Name {
    static let permissionStatusChanged = Notification.Name("permissionStatusChanged")
    static let doubleCmdPressed = Notification.Name("doubleCmdPressed")
    static let shortcutDetected = Notification.Name("shortcutDetected")
    static let conflictFound = Notification.Name("conflictFound")
    static let usageRecorded = Notification.Name("usageRecorded")
    static let statisticsUpdated = Notification.Name("statisticsUpdated")
    static let showStatisticsWindow = Notification.Name("showStatisticsWindow")
    static let showSettingsWindow = Notification.Name("showSettingsWindow")
}

enum PermissionStatus {
    case granted
    case denied
    case notDetermined
}

class PermissionManager {
    static let shared = PermissionManager()

    private var permissionCheckTimer: Timer?

    private init() {}

    // MARK: - 权限检查

    func checkAndRequestPermissions() {
        checkAccessibilityPermission()
    }

    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    func getPermissionStatus() -> PermissionStatus {
        if AXIsProcessTrusted() {
            return .granted
        } else {
            return .denied
        }
    }

    // MARK: - 辅助功能权限

    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()

        if !trusted {
            // 只显示系统原生弹窗，不显示自定义弹窗
            requestAccessibilityPermission()
            startPermissionMonitoring()
        } else {
            print("✅ 辅助功能权限已授予")
        }
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        AXIsProcessTrustedWithOptions(options)
    }

    private func startPermissionMonitoring() {
        // 每2秒检查一次权限状态
        print("🔄 开始监控权限状态变化...")
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let hasPermission = self.hasAccessibilityPermission()
            print("🔍 权限检查: \(hasPermission ? "✅ 已授予" : "❌ 未授予")")

            if hasPermission {
                print("🎉 检测到权限已授予！停止监控并发送通知")
                self.permissionCheckTimer?.invalidate()
                self.permissionCheckTimer = nil

                // 通知权限状态变化
                NotificationCenter.default.post(name: .permissionStatusChanged, object: nil)

                DispatchQueue.main.async {
                    self.showPermissionGrantedNotification()
                }
            }
        }
    }

    // MARK: - UI提示

    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = """
            Keymap需要辅助功能权限来实现以下功能：
            • 监控全局快捷键
            • 检测快捷键冲突
            • 提取应用菜单快捷键

            请在系统设置中授予Keymap辅助功能权限。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "稍后")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.openSystemPreferences()
            }
        }
    }

    private func showPermissionGrantedNotification() {
        let notification = NSUserNotification()
        notification.title = "权限已授予"
        notification.informativeText = "Keymap现在可以正常工作了"
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }

    func openSystemPreferences() {
        // macOS 13+使用新的系统设置URL scheme
        if #available(macOS 13, *) {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // macOS 12及以下
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    deinit {
        permissionCheckTimer?.invalidate()
    }
}
