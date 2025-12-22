//
//  ShortcutCache.swift
//  Keymap
//
//  Created on 2025-12-19.
//

import Foundation

/// 快捷键缓存管理器
class ShortcutCache {

    // MARK: - Properties

    /// 内存缓存（使用NSCache自动管理内存）
    private let memoryCache = NSCache<NSString, CachedShortcuts>()

    /// UserDefaults键前缀
    private let cacheKeyPrefix = "shortcut_cache_"
    private let timestampKeyPrefix = "shortcut_timestamp_"

    /// 设置管理器
    private let settings = SettingsManager.shared

    /// 缓存过期时间（从设置读取，小时转秒）
    private var cacheDuration: TimeInterval {
        return TimeInterval(settings.cacheDuration) * 60 * 60
    }

    /// 最大缓存应用数（从设置读取）
    private var maxCachedApps: Int {
        return settings.maxCachedApps
    }

    // MARK: - Initialization

    init() {
        setupMemoryCache()
    }

    // MARK: - Public Methods

    /// 缓存应用的快捷键
    /// - Parameters:
    ///   - shortcuts: 快捷键数组
    ///   - bundleId: 应用Bundle ID
    func cacheShortcuts(_ shortcuts: [ShortcutInfo], for bundleId: String) {
        let cached = CachedShortcuts(shortcuts: shortcuts, timestamp: Date())

        // 1. 保存到内存缓存
        memoryCache.setObject(cached, forKey: bundleId as NSString)

        // 2. 保存到UserDefaults（持久化）
        saveToUserDefaults(shortcuts, bundleId: bundleId)

        print("💾 缓存快捷键: \(bundleId) - \(shortcuts.count)个")
    }

    /// 获取缓存的快捷键
    /// - Parameter bundleId: 应用Bundle ID
    /// - Returns: 快捷键数组，如果缓存不存在或已过期返回nil
    func getCachedShortcuts(for bundleId: String) -> [ShortcutInfo]? {
        // 1. 先从内存缓存获取
        if let cached = memoryCache.object(forKey: bundleId as NSString) {
            if !isExpired(cached.timestamp) {
                print("📦 内存缓存命中: \(bundleId)")
                return cached.shortcuts
            } else {
                print("⏱ 内存缓存过期: \(bundleId)")
                memoryCache.removeObject(forKey: bundleId as NSString)
            }
        }

        // 2. 从UserDefaults获取
        if let shortcuts = loadFromUserDefaults(bundleId: bundleId) {
            // 检查是否过期
            if !shouldRefreshCache(for: bundleId) {
                // 重新加载到内存缓存
                let cached = CachedShortcuts(shortcuts: shortcuts, timestamp: Date())
                memoryCache.setObject(cached, forKey: bundleId as NSString)

                print("📦 磁盘缓存命中: \(bundleId)")
                return shortcuts
            } else {
                print("⏱ 磁盘缓存过期: \(bundleId)")
                invalidateCache(for: bundleId)
            }
        }

        return nil
    }

    /// 检查缓存是否过期（需要刷新）
    /// - Parameter bundleId: 应用Bundle ID
    /// - Returns: 是否需要刷新
    func shouldRefreshCache(for bundleId: String) -> Bool {
        let timestampKey = timestampKeyPrefix + bundleId

        guard let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date else {
            return true  // 没有时间戳，需要刷新
        }

        return isExpired(timestamp)
    }

    /// 清除指定应用的缓存
    /// - Parameter bundleId: 应用Bundle ID
    func invalidateCache(for bundleId: String) {
        // 1. 清除内存缓存
        memoryCache.removeObject(forKey: bundleId as NSString)

        // 2. 清除持久化缓存
        let cacheKey = cacheKeyPrefix + bundleId
        let timestampKey = timestampKeyPrefix + bundleId

        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: timestampKey)

        print("🗑 清除缓存: \(bundleId)")
    }

    /// 清除所有缓存
    func clearAllCaches() {
        // 1. 清除内存缓存
        memoryCache.removeAllObjects()

        // 2. 清除所有UserDefaults缓存
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        for key in allKeys where key.hasPrefix(cacheKeyPrefix) || key.hasPrefix(timestampKeyPrefix) {
            defaults.removeObject(forKey: key)
        }

        print("🗑 清除所有缓存")
    }

    /// 获取缓存统计信息
    /// - Returns: (缓存应用数, 总快捷键数)
    func getCacheStatistics() -> (apps: Int, shortcuts: Int) {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        var appCount = 0
        var shortcutCount = 0

        for key in allKeys where key.hasPrefix(cacheKeyPrefix) {
            if let data = defaults.data(forKey: key),
               let shortcuts = try? JSONDecoder().decode([ShortcutInfo].self, from: data) {
                appCount += 1
                shortcutCount += shortcuts.count
            }
        }

        return (appCount, shortcutCount)
    }

    // MARK: - Private Methods

    /// 配置内存缓存
    private func setupMemoryCache() {
        memoryCache.countLimit = maxCachedApps
        memoryCache.name = "ShortcutCache"
    }

    /// 保存到UserDefaults
    private func saveToUserDefaults(_ shortcuts: [ShortcutInfo], bundleId: String) {
        let cacheKey = cacheKeyPrefix + bundleId
        let timestampKey = timestampKeyPrefix + bundleId

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(shortcuts)

            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: timestampKey)
        } catch {
            print("❌ 保存缓存失败: \(error.localizedDescription)")
        }
    }

    /// 从UserDefaults加载
    private func loadFromUserDefaults(bundleId: String) -> [ShortcutInfo]? {
        let cacheKey = cacheKeyPrefix + bundleId

        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let shortcuts = try decoder.decode([ShortcutInfo].self, from: data)
            return shortcuts
        } catch {
            print("❌ 加载缓存失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 检查时间戳是否过期
    private func isExpired(_ timestamp: Date) -> Bool {
        let elapsed = Date().timeIntervalSince(timestamp)
        return elapsed > cacheDuration
    }
}

// MARK: - CachedShortcuts Class

/// 缓存的快捷键对象（用于NSCache）
private class CachedShortcuts {
    let shortcuts: [ShortcutInfo]
    let timestamp: Date

    init(shortcuts: [ShortcutInfo], timestamp: Date) {
        self.shortcuts = shortcuts
        self.timestamp = timestamp
    }
}
