//
//  GlobalShortcutDatabase.swift
//  Keymap
//
//  Created on 2025-12-23.
//

import Foundation
import AppKit
import Combine

/// 长驻应用信息
struct BackgroundAppInfo: Identifiable, Hashable {
    let id: String  // bundleId
    let bundleId: String
    let name: String
    let icon: NSImage?
    let activationPolicy: NSApplication.ActivationPolicy
    let isUserMarked: Bool  // 用户手动标记
    let shortcutCount: Int  // 快捷键数量
    
    var policyDescription: String {
        switch activationPolicy {
        case .regular:
            return "普通应用"
        case .accessory:
            return "长驻后台"
        case .prohibited:
            return "辅助进程"
        @unknown default:
            return "未知"
        }
    }
}

/// 全局快捷键数据库 - 维护所有运行中应用的快捷键
class GlobalShortcutDatabase: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = GlobalShortcutDatabase()
    
    // MARK: - Properties
    
    /// 快捷键索引：keyCombination -> [应用信息]
    private var shortcutIndex: [String: [AppShortcutEntry]] = [:]
    
    /// 应用快捷键缓存：bundleId -> [ShortcutInfo]
    private var appShortcutsCache: [String: [ShortcutInfo]] = [:]
    
    /// 检测到的长驻应用列表
    @Published private(set) var backgroundApps: [BackgroundAppInfo] = []
    
    /// 用户手动标记的长驻应用（存储在 UserDefaults）
    private var userMarkedBackgroundApps: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: "userMarkedBackgroundApps") ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "userMarkedBackgroundApps")
        }
    }
    
    private let extractor = AppShortcutExtractor()
    private let cache = ShortcutCache()
    
    // MARK: - Initialization
    
    private init() {
        print("📚 初始化全局快捷键数据库...")
    }
    
    // MARK: - Public Methods
    
    /// 扫描所有运行中的应用并加载快捷键
    func scanRunningApplications() async {
        print("🔍 开始扫描运行中的应用...")
        
        let runningApps = NSWorkspace.shared.runningApplications.filter { app in
            // 过滤：有 Bundle ID
            app.bundleIdentifier != nil
        }
        
        print("📱 发现 \(runningApps.count) 个运行中的应用")
        
        // 1. 识别长驻应用
        await identifyBackgroundApps(runningApps)
        
        // 2. 并发提取快捷键（限制并发数避免过载）
        await withTaskGroup(of: (String, [ShortcutInfo]).self) { group in
            for app in runningApps.prefix(30) {  // 扫描前30个应用
                group.addTask {
                    await self.loadShortcutsForApp(app)
                }
            }
            
            for await (bundleId, shortcuts) in group {
                if !shortcuts.isEmpty {
                    self.addShortcuts(shortcuts, for: bundleId)
                }
            }
        }
        
        print("✅ 扫描完成，已加载 \(appShortcutsCache.count) 个应用的快捷键")
        printStatistics()
    }
    
    /// 快速扫描长驻应用（识别长驻应用并异步提取快捷键）
    func quickScanBackgroundApps() async {
        print("⚡️ 快速扫描长驻应用...")
        
        let runningApps = NSWorkspace.shared.runningApplications.filter { app in
            app.bundleIdentifier != nil
        }
        
        // 1. 先识别长驻应用（从缓存获取快捷键数量）
        await identifyBackgroundApps(runningApps)
        
        // 2. 异步为没有缓存的长驻应用提取快捷键
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            for app in runningApps {
                guard let bundleId = app.bundleIdentifier else { continue }
                
                // 检查是否是长驻应用且没有缓存
                let isBackgroundApp = app.activationPolicy == .accessory || 
                                     app.activationPolicy == .prohibited
                let hasCache = self.cache.getCachedShortcuts(for: bundleId) != nil ||
                              self.appShortcutsCache[bundleId] != nil
                
                if isBackgroundApp && !hasCache {
                    print("📥 提取快捷键: \(app.localizedName ?? bundleId)")
                    await self.loadShortcuts(for: app)
                }
            }
            
            // 3. 提取完成后更新长驻应用列表
            await self.identifyBackgroundApps(runningApps)
        }
        
        print("✅ 快速扫描完成，正在后台提取快捷键...")
    }
    
    /// 识别长驻应用
    private func identifyBackgroundApps(_ apps: [NSRunningApplication]) async {
        // ✅ 使用 Dictionary 按 bundleId 去重
        var bgAppsDict: [String: BackgroundAppInfo] = [:]
        let userMarked = userMarkedBackgroundApps

        for app in apps {
            guard let bundleId = app.bundleIdentifier else { continue }

            // 如果已经添加过该 bundleId，跳过
            if bgAppsDict[bundleId] != nil {
                continue
            }

            // ✅ 排除系统核心进程（用户不会直接使用的后台服务）
            if shouldExcludeSystemProcess(bundleId: bundleId, appName: app.localizedName) {
                continue
            }

            // 判定为长驻应用的条件：
            // 1. activationPolicy == .accessory（菜单栏应用）
            // 2. activationPolicy == .prohibited（系统辅助进程）
            // 3. 用户手动标记
            let isBackgroundApp = app.activationPolicy == .accessory ||
                                 app.activationPolicy == .prohibited ||
                                 userMarked.contains(bundleId)

            if isBackgroundApp {
                // ✅ 先从缓存快速获取快捷键数量
                var shortcutCount = 0
                if let cachedShortcuts = cache.getCachedShortcuts(for: bundleId) {
                    shortcutCount = cachedShortcuts.count
                } else if let loadedShortcuts = appShortcutsCache[bundleId] {
                    shortcutCount = loadedShortcuts.count
                }

                // ✅ 智能过滤：
                // - 只显示有快捷键的应用（无论第三方还是系统）
                // - 除非用户手动标记（显示以便后续提取快捷键）
                let isUserMarked = userMarked.contains(bundleId)
                let hasShortcuts = shortcutCount > 0
                let shouldInclude = hasShortcuts || isUserMarked

                if shouldInclude {
                    let info = BackgroundAppInfo(
                        id: bundleId,
                        bundleId: bundleId,
                        name: app.localizedName ?? bundleId,
                        icon: app.icon,
                        activationPolicy: app.activationPolicy,
                        isUserMarked: isUserMarked,
                        shortcutCount: shortcutCount
                    )
                    bgAppsDict[bundleId] = info
                }
            }
        }

        // 转换为数组并排序（第三方应用优先，按名称排序）
        let bgApps = Array(bgAppsDict.values).sorted { app1, app2 in
            let isApp1Apple = app1.bundleId.hasPrefix("com.apple.")
            let isApp2Apple = app2.bundleId.hasPrefix("com.apple.")

            // 第三方应用排在前面
            if isApp1Apple != isApp2Apple {
                return !isApp1Apple
            }

            // 同类型应用按名称排序
            return app1.name < app2.name
        }

        await MainActor.run {
            self.backgroundApps = bgApps
        }

        let thirdPartyCount = bgApps.filter { !$0.bundleId.hasPrefix("com.apple.") }.count
        let appleCount = bgApps.count - thirdPartyCount
        print("🎯 识别到 \(bgApps.count) 个长驻应用（第三方:\(thirdPartyCount), 系统:\(appleCount)）")
    }
    
    /// 排除系统核心进程（用户不会直接使用的后台服务）
    private func shouldExcludeSystemProcess(bundleId: String, appName: String?) -> Bool {
        // ✅ 系统核心进程黑名单（用户不会直接交互的后台服务）
        let systemProcessPrefixes = [
            // 辅助功能和系统代理
            "com.apple.accessibility.",
            "com.apple.AmbientDisplayAgent",
            "com.apple.CoreLocationAgent",
            "com.apple.CoreServicesUIAgent",
            "com.apple.notificationcenterui",
            "com.apple.loginwindow",
            "com.apple.systemuiserver",
            "com.apple.SecurityAgent",
            "com.apple.BluetoothAgent",
            "com.apple.AirPlayUIAgent",
            "com.apple.AirPortBaseStationAgent",

            // 核心系统组件
            "com.apple.dock",
            "com.apple.finder",
            "com.apple.ControlCenter",
            "com.apple.Spotlight",

            // WebKit和云服务
            "com.apple.WebKit.",
            "com.apple.CloudKit.",
            "com.apple.icloud.",

            // 通信和媒体
            "com.apple.FaceTime.",
            "com.apple.imservice.",
            "com.apple.Messages.",

            // 网络和系统设置
            "com.apple.wifi.",
            "com.apple.preferences.",
            "com.apple.ScreenContinuity",

            // 后台服务
            "com.apple.quicklook.",
            "com.apple.sharingd",
            "com.apple.bird",
            "com.apple.Dock.extra",
            "com.apple.ViewBridgeAuxiliary",

            // 输入法和键盘
            "com.apple.inputmethod.",
            "com.apple.PressAndHold",

            // 音频和屏幕
            "com.apple.audio.",
            "com.apple.screencaptureui",

            // 系统更新和诊断
            "com.apple.SoftwareUpdate",
            "com.apple.DiagnosticExtensions",
            "com.apple.ReportCrash"
        ]

        // 检查是否匹配黑名单前缀
        for prefix in systemProcessPrefixes {
            if bundleId.hasPrefix(prefix) {
                return true
            }
        }

        // ✅ 排除名称中包含"Agent"但不是用户应用的系统进程
        let lowerBundleId = bundleId.lowercased()
        if lowerBundleId.contains("agent") && bundleId.hasPrefix("com.apple.") {
            // 但保留一些有意义的Apple应用
            let allowedAppleApps = [
                "com.apple.shortcuts",
                "com.apple.reminders",
                "com.apple.MobileSMS",
                "com.apple.Maps",
                "com.apple.Music"
            ]

            if !allowedAppleApps.contains(where: { bundleId.hasPrefix($0) }) {
                return true
            }
        }

        // ✅ 排除明确的后台辅助进程（通过名称和bundleId匹配）

        // 检查 bundleId 中的关键词（适用于所有应用）
        let lowerBundleId2 = bundleId.lowercased()
        let excludedBundleIdKeywords = [
            "helper",
            "plugin",
            "extension",
            "renderer",
            "daemon",
            "service",
            "bridge",
            "auxiliary",
            "widget"
        ]

        for keyword in excludedBundleIdKeywords {
            if lowerBundleId2.contains(keyword) {
                return true
            }
        }

        // 检查应用名称中的关键词（适用于所有应用）
        if let name = appName {
            let lowerName = name.lowercased()
            let excludedNameKeywords = [
                "helper",
                "plugin",
                "extension",
                "renderer",
                "(plugin)",
                "(renderer)",
                "(gpu)",
                "daemon",
                "service",
                "bridge",
                "auxiliary",
                "widget"
            ]

            for keyword in excludedNameKeywords {
                if lowerName.contains(keyword) {
                    return true
                }
            }
        }

        return false
    }
    
    /// 更新长驻应用的快捷键数量
    private func updateBackgroundAppShortcutCounts() {
        var updated: [BackgroundAppInfo] = []
        
        for app in backgroundApps {
            let count = appShortcutsCache[app.bundleId]?.count ?? 0
            let updatedApp = BackgroundAppInfo(
                id: app.bundleId,
                bundleId: app.bundleId,
                name: app.name,
                icon: app.icon,
                activationPolicy: app.activationPolicy,
                isUserMarked: app.isUserMarked,
                shortcutCount: count
            )
            updated.append(updatedApp)
        }
        
        backgroundApps = updated
    }
    
    /// 为特定应用加载快捷键
    func loadShortcuts(for app: NSRunningApplication) async {
        guard let bundleId = app.bundleIdentifier else { return }
        
        let (_, shortcuts) = await loadShortcutsForApp(app)
        if !shortcuts.isEmpty {
            addShortcuts(shortcuts, for: bundleId)
        }
    }
    
    /// 移除应用的快捷键（应用退出时调用）
    func removeShortcuts(for bundleId: String) {
        guard let shortcuts = appShortcutsCache[bundleId] else { return }
        
        // 从索引中移除
        for shortcut in shortcuts {
            shortcutIndex[shortcut.keyCombination]?.removeAll { $0.bundleId == bundleId }
            if shortcutIndex[shortcut.keyCombination]?.isEmpty == true {
                shortcutIndex.removeValue(forKey: shortcut.keyCombination)
            }
        }
        
        // 从缓存中移除
        appShortcutsCache.removeValue(forKey: bundleId)
        
        print("🗑 移除应用快捷键: \(bundleId)")
    }
    
    /// 查询使用指定快捷键的所有应用
    /// - Parameter keyCombination: 快捷键组合
    /// - Returns: 使用该快捷键的应用列表
    func findAppsUsingShortcut(_ keyCombination: String) -> [AppShortcutEntry] {
        return shortcutIndex[keyCombination] ?? []
    }
    
    /// 检测快捷键冲突（针对当前激活应用）
    /// - Parameters:
    ///   - keyCombination: 快捷键组合
    ///   - currentApp: 当前激活应用的 Bundle ID
    /// - Returns: 冲突的应用列表
    func detectConflicts(for keyCombination: String, currentApp: String) -> [AppShortcutEntry] {
        let allApps = findAppsUsingShortcut(keyCombination)
        
        // 过滤出除当前应用外的其他应用
        var conflicts = allApps.filter { $0.bundleId != currentApp }
        
        // 进一步过滤：只保留可能造成冲突的应用（长驻应用）
        let backgroundBundleIds = Set(backgroundApps.map { $0.bundleId })
        conflicts = conflicts.filter { entry in
            // 是否在长驻应用列表中
            backgroundBundleIds.contains(entry.bundleId)
        }
        
        return conflicts
    }
    
    /// 手动标记/取消标记长驻应用
    func toggleUserMarked(bundleId: String) {
        var marked = userMarkedBackgroundApps
        if marked.contains(bundleId) {
            marked.remove(bundleId)
            print("🏷 取消标记长驻应用: \(bundleId)")
        } else {
            marked.insert(bundleId)
            print("🏷 标记为长驻应用: \(bundleId)")
        }
        userMarkedBackgroundApps = marked
        
        // 重新扫描
        Task {
            await scanRunningApplications()
        }
    }
    
    /// 获取所有长驻应用（用于设置界面）
    func getBackgroundApps() -> [BackgroundAppInfo] {
        return backgroundApps
    }
    
    // MARK: - Private Methods
    
    /// 加载应用的快捷键
    private func loadShortcutsForApp(_ app: NSRunningApplication) async -> (String, [ShortcutInfo]) {
        guard let bundleId = app.bundleIdentifier else {
            return ("", [])
        }
        
        // 1. 尝试从缓存获取
        if let cached = cache.getCachedShortcuts(for: bundleId) {
            print("📦 从缓存加载: \(app.localizedName ?? bundleId)")
            return (bundleId, cached)
        }
        
        // 2. 提取快捷键
        let shortcuts = await extractor.extractShortcuts(from: app)
        
        if !shortcuts.isEmpty {
            // 3. 缓存结果
            cache.cacheShortcuts(shortcuts, for: bundleId)
            print("✅ 提取快捷键: \(app.localizedName ?? bundleId) (\(shortcuts.count) 个)")
        }
        
        return (bundleId, shortcuts)
    }
    
    /// 添加快捷键到数据库
    private func addShortcuts(_ shortcuts: [ShortcutInfo], for bundleId: String) {
        // 保存到缓存
        appShortcutsCache[bundleId] = shortcuts
        
        // 构建索引
        for shortcut in shortcuts {
            let entry = AppShortcutEntry(
                bundleId: bundleId,
                appName: shortcut.application,
                shortcut: shortcut,
                activationPolicy: getActivationPolicy(for: bundleId)
            )
            
            if shortcutIndex[shortcut.keyCombination] == nil {
                shortcutIndex[shortcut.keyCombination] = []
            }
            shortcutIndex[shortcut.keyCombination]?.append(entry)
        }
        
        // 更新长驻应用的快捷键数量
        updateBackgroundAppShortcutCounts()
    }
    
    /// 获取应用的激活策略
    private func getActivationPolicy(for bundleId: String) -> NSApplication.ActivationPolicy {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            return app.activationPolicy
        }
        return .regular
    }
    
    /// 打印统计信息
    private func printStatistics() {
        let totalShortcuts = shortcutIndex.values.flatMap { $0 }.count
        let uniqueShortcuts = shortcutIndex.count
        
        print("""
        📊 全局快捷键数据库统计:
        - 已加载应用: \(appShortcutsCache.count)
        - 唯一快捷键: \(uniqueShortcuts)
        - 总快捷键数: \(totalShortcuts)
        - 长驻应用: \(backgroundApps.count)
        """)
    }
}

// MARK: - Supporting Types

/// 应用快捷键条目
struct AppShortcutEntry {
    let bundleId: String
    let appName: String
    let shortcut: ShortcutInfo
    let activationPolicy: NSApplication.ActivationPolicy
    
    var isBackgroundApp: Bool {
        return activationPolicy == .accessory
    }
}
