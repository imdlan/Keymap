# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Keymap 是一个 macOS 快捷键管理工具，使用 Swift + SwiftUI + AppKit 开发，最低支持 macOS 14.0。采用 MVVM 架构，非沙盒应用（需要辅助功能权限以监控全局键盘事件）。

**核心功能**:
- 全局快捷键监控（使用 CGEvent API）
- 从应用菜单自动提取快捷键（Accessibility API）
- 双击 Cmd 触发快捷键面板
- 快捷键冲突检测（已完成）
- 临时快捷键重映射（已完成）
- 使用统计分析（已完成）
- 可视化UI界面（基础版已完成）

## 构建和运行

### 项目生成
项目使用 **XcodeGen** 管理，源配置文件为 `project.yml`。

```bash
# 重新生成 Xcode 项目（添加新文件后必须执行）
xcodegen generate

# 或使用 brew 安装后生成
brew install xcodegen
xcodegen generate
```

### 编译
```bash
# 清理并编译
xcodebuild -project Keymap.xcodeproj -scheme Keymap clean build

# 仅编译
xcodebuild -project Keymap.xcodeproj -scheme Keymap build
```

### 运行
```bash
# 方式1: 在 Xcode 中运行（推荐，方便调试）
open Keymap.xcodeproj
# 然后按 ⌘R

# 方式2: 命令行运行编译后的应用
open ~/Library/Developer/Xcode/DerivedData/Keymap-*/Build/Products/Debug/Keymap.app
```

**首次运行**: 系统会提示授予辅助功能权限，前往 `系统设置 → 隐私与安全性 → 辅助功能` 勾选 Keymap.app。

## 代码架构

### 应用生命周期
- **KeymapApp.swift** (SwiftUI 入口): 使用 `@NSApplicationDelegateAdaptor` 桥接 AppDelegate
- **AppDelegate.swift** (AppKit 生命周期):
  - 初始化菜单栏图标（LSUIElement=true，不在 Dock 显示）
  - 启动 GlobalEventMonitor 监控全局键盘事件
  - 管理 ShortcutPanelWindow 的显示/隐藏

### 全局监控架构
**三层检测机制**:

1. **GlobalEventMonitor** (`Core/Monitoring/GlobalEventMonitor.swift`)
   - 使用 `CGEvent.tapCreate` 创建事件 tap
   - 监听 `keyDown` 和 `flagsChanged` 事件
   - 分发事件到 DoubleCmdDetector 和 KeyCombinationDetector

2. **DoubleCmdDetector** (`Core/Monitoring/DoubleCmdDetector.swift`)
   - 检测双击 Cmd 键（默认阈值 0.3 秒）
   - 通过 NotificationCenter 发送 `doubleCmdDetected` 通知
   - AppDelegate 监听此通知后显示快捷键面板

3. **KeyCombinationDetector** (`Core/Monitoring/KeyCombinationDetector.swift`)
   - 检测快捷键组合（Cmd/Shift/Option/Control + 字母/数字）
   - 返回 KeyCombination 结构体（keyCode + modifiers）
   - 用于记录使用统计和冲突检测（未来）

### 快捷键提取架构
**四个核心组件**:

1. **AppShortcutExtractor** (`Core/ShortcutExtraction/AppShortcutExtractor.swift`)
   - 从运行中的应用菜单提取快捷键
   - 使用 AXUIElement API 遍历菜单层级
   - async/await 异步提取，TaskGroup 实现 5 秒超时

2. **MenuItemParser** (`Core/ShortcutExtraction/MenuItemParser.swift`)
   - 解析单个菜单项（标题、快捷键、状态）
   - 修饰键位掩码转换: Control=0x0001, Shift=0x0002, Option=0x0004, Command=0x0008
   - **智能修饰键修正**：自动为缺失修饰键的单字符快捷键添加Command键（解决Chrome等应用的Accessibility API bug）
   - **多格式支持**：兼容Chrome的修饰键格式（0x0010 cmdKeyBit）
   - **备用解析**：从菜单标题中解析快捷键（如"New Tab\t⌘T"）
   - 字符到键码映射（支持 A-Z, 0-9, 特殊字符）

3. **SystemShortcutProvider** (`Core/ShortcutExtraction/SystemShortcutProvider.swift`)
   - 提供 30 个硬编码的系统快捷键（⌘Q, ⌘W, ⌘Space 等）
   - 单例模式，按分类组织（通用、窗口、截图、Spotlight、辅助功能）

4. **ShortcutCache** (`Core/ShortcutExtraction/ShortcutCache.swift`)
   - 两层缓存: NSCache（内存，最多 50 个应用）+ UserDefaults（持久化）
   - 缓存过期: 24 小时
   - 自动管理内存，支持缓存统计

### 冲突检测架构
**三个核心组件**:

1. **ConflictDetector** (`Core/ConflictDetection/ConflictDetector.swift`)
   - 冲突检测主引擎
   - 四种冲突类型：系统级、全局、应用级、功能级
   - 智能严重程度计算（high/medium/low）
   - 实时冲突检测（集成到 GlobalEventMonitor）
   - **标准快捷键白名单**：排除 27 个 macOS 标准快捷键（⌘Q, ⌘C, ⌘V等）的误报

2. **ConflictAnalyzer** (`Core/ConflictDetection/ConflictAnalyzer.swift`)
   - 冲突分析与建议生成
   - 寻找替代快捷键（修饰键变化 + 相邻按键）
   - 基于 QWERTY 键盘布局的智能建议
   - 最多返回 5 个替代方案

3. **ConflictResolver** (`Core/ConflictDetection/ConflictResolver.swift`)
   - 冲突解决方案执行
   - 支持策略：disable, remap（阶段5）, ignore, manual
   - 解决记录持久化（UserDefaults）
   - 提供统计功能（已解决/已忽略/待处理）

**标准快捷键白名单**（这些快捷键在多个应用中使用是正常的，不会被标记为冲突）:
- 应用管理: ⌘Q, ⌘W, ⌘H, ⌥⌘H, ⌘M, ⌥⌘M, ⌘,
- 编辑操作: ⌘C, ⌘V, ⌘X, ⌘Z, ⇧⌘Z, ⌘A
- 文件操作: ⌘S, ⇧⌘S, ⌘N, ⌘O, ⌘P
- 查找操作: ⌘F, ⌘G, ⇧⌘G, ⌥⌘F
- 其他: ⌘?, ⌘T, ⌘R, ⌘L

**冲突检测流程**:
```
1. 用户按下快捷键 → GlobalEventMonitor 捕获
2. handleShortcutDetected → 异步调用 ConflictDetector
3. detectRealTimeConflict → 检查与所有已知快捷键的冲突
4. 如果发现冲突 → 发送 .conflictFound 通知
5. UI 监听通知 → 显示冲突警告和建议
```

### 数据持久化架构
**四个核心组件**:

1. **DatabaseManager** (`Data/DatabaseManager.swift`)
   - SQLite 数据库管理器（单例）
   - 5张表：applications, shortcuts, conflicts, usage_records, statistics_summary
   - 参数化查询、事务支持、数据库索引优化
   - 自动创建数据库目录：`~/Library/Application Support/Keymap/keymap.db`

2. **ShortcutRepository** (`Data/Repositories/ShortcutRepository.swift`)
   - 快捷键数据访问层（Repository 模式）
   - CRUD 操作、搜索、批量保存
   - 自动创建应用记录、智能更新/插入判断

3. **UsageRepository** (`Data/Repositories/UsageRepository.swift`)
   - 使用记录数据访问层
   - 记录快捷键使用、统计聚合、趋势分析
   - 自动每日摘要聚合（异步 Task）
   - 支持多种统计周期（today/week/month/all）

4. **SettingsManager** (`Data/SettingsManager.swift`)
   - 用户设置管理（单例，UserDefaults 持久化）
   - 9个设置项：双击阈值、实时检测、使用追踪、缓存时长等
   - 导出/导入、默认值注册、变更通知（NotificationCenter）

**数据库表结构**:
```sql
applications       - 应用信息（bundle_id, name, icon_data）
shortcuts          - 快捷键（key_combination, description, category）
conflicts          - 冲突记录（conflict_type, severity）
usage_records      - 使用记录（shortcut_key, timestamp, context）
statistics_summary - 统计摘要（按日期聚合）
```

**自动记录流程**:
```
1. 用户按下快捷键 → GlobalEventMonitor 捕获
2. recordUsageStatistics → 检查设置是否开启追踪
3. 创建 UsageRecord → Task 异步保存到数据库
4. UsageRepository.recordUsage → 写入 usage_records 表
5. updateDailySummary → 自动更新 statistics_summary 表
```

### 快捷键重映射架构
**两个核心组件**:

1. **RemappingEngine** (`Core/Remapping/RemappingEngine.swift`)
   - 快捷键重映射引擎
   - 数据结构: `[bundleId: [fromKey: toKey]]`
   - 智能规则验证（不能自映射、循环、链式、系统保留键）
   - 字符到键码映射（A-Z, 0-9, 特殊键）

2. **RemappingManager** (`Core/Remapping/RemappingManager.swift`)
   - 重映射规则管理器（单例）
   - 持久化到 UserDefaults（JSON 格式）
   - 导出/导入功能（JSON 文件）
   - 验证和统计功能

**重映射流程**:
```
1. 用户按下快捷键（如⌘T）→ GlobalEventMonitor 捕获 keyDown 事件
2. checkAndApplyRemapping → 查找重映射规则
3. 如果有规则（⌘T → ⇧⌘T）→ 创建新 CGEvent
4. 设置新的 keyCode 和 modifiers
5. 返回新事件 → 系统接收⇧⌘T而不是⌘T
```

**验证规则**:
- ❌ 不能映射到相同的键（⌘T → ⌘T）
- ❌ 不能映射系统保留快捷键（→ ⌘Q, ⌘Space）
- ❌ 不能创建循环映射（⌘T→⇧⌘T, ⇧⌘T→⌘T）
- ❌ 不能创建链式映射（⌘T→⇧⌘T→⌃⌘T）

**系统保留快捷键**:
```swift
⌘Q         - 退出应用
⌘⌥Esc      - 强制退出
⌘Space     - Spotlight
⌃⌘Q        - 锁定屏幕
⌃⌘Power    - 关机对话框
```

**限制**:
- 仅在应用运行期间有效（临时重映射）
- 无法修改 macOS 系统级快捷键
- 需要辅助功能权限
- SIP 保护的应用可能无法重映射

### UI 架构
**SwiftUI + AppKit 混合架构**:

- **ShortcutPanelWindow** (`UI/Views/ShortcutPanel/ShortcutPanelWindow.swift`)
  - NSPanel 子类，半透明浮动窗口
  - 使用 NSHostingView 承载 SwiftUI 视图
  - 无边框、总在最前、点击外部关闭

- **ShortcutPanelView** (`UI/Views/ShortcutPanel/ShortcutPanelView.swift`)
  - SwiftUI 视图，显示快捷键列表
  - 支持搜索、分类显示、冲突高亮

- **ShortcutPanelViewModel** (`UI/ViewModels/ShortcutPanelViewModel.swift`)
  - MVVM 模式的 ViewModel
  - 集成 AppShortcutExtractor、ShortcutCache、SystemShortcutProvider
  - 提取流程: 检查缓存 → 异步提取 → 合并系统快捷键 → 缓存结果

### 数据模型
- **ShortcutInfo** (`Models/ShortcutInfo.swift`): 快捷键信息，包含 keyCombination, description, application, category, conflicts
- **ConflictInfo** (`Models/ConflictInfo.swift`): 冲突信息，包含 id, shortcutId, conflictType, severity, suggestions
- **UsageRecord** (`Models/UsageRecord.swift`): 使用记录，包含 id, shortcutKey, application, timestamp, context
- **StatisticsSummary** (`Models/StatisticsSummary.swift`): 统计摘要，包含 totalUsage, conflictCount, efficiencyScore, topShortcuts, timeRange
- **KeyCombination** (`Models/KeyCombination.swift`): 快捷键组合，包含 keyCode, modifiers, displayString
- **RemappingRule** (`Core/Remapping/RemappingEngine.swift`): 重映射规则，包含 fromKey, toKey, bundleId, createdAt

### 枚举类型
- **ShortcutCategory**: 快捷键分类（general, edit, window, navigation, search, view, help, custom）
- **ConflictType**: 冲突类型（system, global, application, functional）
- **ConflictSeverity**: 冲突严重程度（high, medium, low）
- **UsageContext**: 使用上下文（normal, conflict, remapped）
- **ResolutionStrategy**: 冲突解决策略（disable, remap, ignore, manual）
- **StatisticsPeriod**: 统计周期（today, week, month, all）

## 重要约定

### 添加新文件后
**必须重新生成项目**:
```bash
xcodegen generate
```
否则 Xcode 无法识别新文件。

### 修改 ShortcutCategory 枚举
使用 `.edit` 而不是 `.editing`（已在 ShortcutInfo.swift 中统一）。

### 权限相关
- **Entitlements.plist** 必须设置 `com.apple.security.app-sandbox = false`（非沙盒应用）
- **Info.plist** 必须设置 `LSUIElement = true`（菜单栏应用）
- 需要 `NSAppleEventsUsageDescription` 说明（Accessibility API）

### 缓存清理
```bash
# 清除 UserDefaults 缓存（重新测试提取功能时）
defaults delete com.yourcompany.Keymap
```

### 双击 Cmd 灵敏度调整
修改 `DoubleCmdDetector.swift` 中的 `doublePressThreshold`（默认 0.3 秒）。

## 开发进度

参考 `PLAN.md`。当前状态:
- ✅ 阶段1: Xcode 项目创建（100%）
- ✅ 阶段2: 快捷键提取（100%）
- ✅ 阶段3: 冲突检测（100%）
- ✅ 阶段4: 数据持久化（100%）
- ✅ 阶段5: 快捷键重映射（100%）
- ✅ 阶段6: UI 完善（100%）

**总体进度**: 100%（核心功能已完成）

### 阶段6完成内容
1. **快捷键面板优化**：
   - ✅ 冲突详情可展开/收起查看
   - ✅ 显示冲突严重程度、类型、应用、建议
   - ✅ 冲突详情面板与主行宽度一致
   - ✅ Emoji图标替换为SF Symbols
   - ✅ 快捷键显示格式优化（⌘ + C）
   - ✅ 应用图标动态显示

2. **冲突检测优化**：
   - ✅ 标准快捷键白名单（排除⌘Q、⌘C等27个标准快捷键的误报）
   - ✅ 智能修饰键修正（解决Chrome等应用的Accessibility API bug）
   - ✅ 多格式修饰键支持

3. **权限管理优化**：
   - ✅ 未授权时点击Dock图标不显示快捷键面板
   - ✅ 自动打开系统设置引导用户授权

### 阶段7完成内容（设置功能完善）
1. **设置面板所有功能实现**：
   - ✅ 开机自动启动（使用 SMAppService API）
   - ✅ 显示冲突通知开关
   - ✅ 双击Cmd阈值可调节（从 SettingsManager 读取）
   - ✅ 触发快捷键选择（支持双击Cmd/Option/Control）
   - ✅ 面板自动关闭延迟（可设置0-30秒，0为禁用）
   - ✅ 缓存时长可调节（1-72小时）
   - ✅ 最大缓存应用数可调节（10-100个）
   - ✅ 全局快捷键重映射开关
   - ✅ 所有设置实时保存到 UserDefaults 并生效

2. **双击检测器重构**：
   - ✅ 新增 ModifierKey 枚举（command/option/control）
   - ✅ 从设置读取 triggerKey（doubleCmd/doubleOption/doubleControl）
   - ✅ 动态切换监听的修饰键
   - ✅ 使用 Logger 替代 print 输出

3. **日志系统**：
   - ✅ 新增 Logger.swift 工具类
   - ✅ 五级日志：off/error/warning/info/debug
   - ✅ 日志格式：时间戳 + 级别 + Emoji + 消息
   - ✅ Debug级别包含文件名和行号
   - ✅ 从 SettingsManager 读取日志级别
   - ✅ 提供静态和实例方法调用

4. **快捷键录制功能**：
   - ✅ 新增 KeyRecorder.swift 录制器
   - ✅ 使用 NSEvent.addLocalMonitorForEvents 监听按键
   - ✅ 自动过滤单独的修饰键
   - ✅ 支持特殊键（F1-F20、方向键、Space等）
   - ✅ 检查 enableRecordingMode 设置
   - ✅ 录制完成后自动停止监听
   - ✅ 通过回调返回 KeyCombination

**技术要点**：
- SMAppService（macOS 13+）用于开机自动启动
- Timer 实现面板自动关闭
- Combine 框架实现设置双向绑定
- NSEvent 本地监听实现按键录制
- 所有 print 语句已替换为 Logger
- 模块化设计，各功能独立可测试

**修改文件**：
- Keymap/Data/SettingsManager.swift（新增5个配置项）
- Keymap/Core/Monitoring/DoubleCmdDetector.swift（完全重构）
- Keymap/Core/ShortcutExtraction/ShortcutCache.swift（从设置读取配置）
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelWindow.swift（新增自动关闭）
- Keymap/Core/Monitoring/GlobalEventMonitor.swift（新增功能开关检查）
- Keymap/UI/Views/Settings/SettingsWindow.swift（实现所有设置功能）
- Keymap/Utilities/Logger.swift（新增文件）
- Keymap/Core/Recording/KeyRecorder.swift（新增文件）


## 测试

参考 `docs/testing/TEST_GUIDE.md` 进行功能测试。

**基础验证**:
1. 应用启动后 Dock 不显示图标
2. 菜单栏显示键盘图标 ⌨️
3. 双击 Cmd 键弹出快捷键面板
4. 打开 Safari，双击 Cmd，应显示 Safari 和系统快捷键

**验证脚本**:
```bash
swift scripts/verify/verify_shortcuts.swift  # 验证系统快捷键数量
```

## 性能目标

- CPU 使用率: < 5%（后台运行）
- 内存占用: < 100MB
- 首次提取快捷键: < 5 秒
- 缓存命中响应: < 0.1 秒
- 面板响应时间: < 200ms

## 故障排除

### 应用无法监控键盘事件
1. 检查辅助功能权限是否授予
2. 在系统设置中移除并重新添加 Keymap 权限
3. 检查控制台是否有 "✅ 全局监控已启动" 输出

### 双击 Cmd 无反应
1. 查看控制台是否有 "⌘ 检测到双击Cmd" 输出
2. 确认 GlobalEventMonitor 已启动
3. 调整 DoubleCmdDetector 的阈值

### 快捷键提取失败
1. 查看控制台错误信息（"⚠️ 无法获取应用菜单栏"）
2. 确认应用有菜单栏且包含快捷键
3. 提取超时时显示演示数据（正常降级行为）

### 编译错误
1. 确认 macOS >= 14.0, Xcode >= 15.0
2. 清理构建文件夹 (⇧⌘K)
3. 检查新文件是否通过 `xcodegen generate` 添加到项目
4. 验证 Info.plist 和 Entitlements.plist 路径

## 相关文档

- **docs/development/PLAN.md**: 详细开发计划和进度跟踪
- **docs/development/BUILD_README.md**: 构建和编译指南
- **docs/testing/TEST_CHECKLIST.md**: 阶段1运行时测试清单
- **docs/testing/TEST_GUIDE.md**: 功能测试指南
- **docs/stages/STAGE1_SUMMARY.md**: 阶段1完成总结（Xcode项目创建）
- **docs/stages/STAGE2_SUMMARY.md**: 阶段2完成总结（快捷键提取）
- **docs/stages/STAGE3_SUMMARY.md**: 阶段3完成总结（冲突检测）
- **docs/stages/STAGE4_SUMMARY.md**: 阶段4完成总结（数据持久化）
- **docs/stages/STAGE5_SUMMARY.md**: 阶段5完成总结（快捷键重映射）
- **docs/stages/STAGE6_SUMMARY.md**: 阶段6完成总结（UI完善）
- **docs/design/快捷键冲突管理 2025-12-18-20-30-02.md**: 原始设计文档
- **QUICKSTART.md**: 快速启动指南
- **README.md**: 项目说明
- **scripts/README.md**: 工具脚本说明

## 更新日志

### 2025-12-24 - 修复使用统计追踪功能 Bug

**问题发现**:
- 🐛 用户报告：使用过很多次快捷键且开启使用统计追踪，但数据库显示使用记录数和快捷键数都是 0
- 🐛 问题根源：`SettingsManager` 中6个 Bool 属性使用了 `UserDefaults.bool(forKey:)` 方法

**根本原因**:
- `UserDefaults.bool(forKey:)` 在键不存在时返回 `false`，而**不是**使用 `registerDefaults()` 注册的默认值
- 即使在 `registerDefaults()` 中设置了 `Keys.enableUsageTracking: true`，第一次读取时仍然返回 `false`
- 导致 `GlobalEventMonitor` 的 `recordUsageStatistics()` 检查设置后直接 return，不记录任何数据

**修复方案**:
- 将6个 Bool 属性的 getter 从 `defaults.bool(forKey:)` 改为 `defaults.object(forKey:) as? Bool ?? defaultValue`

**修复的属性**:
1. ✅ `launchAtLogin` (默认 false)
2. ✅ `enableRealTimeDetection` (默认 true)
3. ✅ `showNotifications` (默认 true)
4. ✅ `enableUsageTracking` (默认 true) ← **最关键**
5. ✅ `enableGlobalRemapping` (默认 false)
6. ✅ `enableRecordingMode` (默认 false)

**影响**:
- 修复后，`enableUsageTracking` 将正确返回 `true`（默认值）
- `GlobalEventMonitor` 将开始记录快捷键使用数据到数据库
- 用户可以在设置面板看到正确的使用记录数和快捷键数
- 统计分析功能将正常工作

**技术细节**:
```swift
// ❌ 错误写法（会返回 false 而不是默认值）
var enableUsageTracking: Bool {
    get {
        return defaults.bool(forKey: Keys.enableUsageTracking)
    }
}

// ✅ 正确写法（会返回默认值 true）
var enableUsageTracking: Bool {
    get {
        return defaults.object(forKey: Keys.enableUsageTracking) as? Bool ?? true
    }
}
```

**修改文件**:
- Keymap/Data/SettingsManager.swift

### 2025-12-24 - 修复数据库统计查询类型转换错误

**问题发现**:
- 🐛 用户报告：数据库实际有 2918 条使用记录，但设置面板显示为 0
- 🐛 问题根源：`loadDatabaseInfo()` 中查询结果类型转换错误

**根本原因**:
- SQLite 的 `COUNT(*)` 返回 `Int64` 类型
- `DatabaseManager.executeQuery()` 正确返回了 `Int64`
- 但 `SettingsWindow` 尝试将其直接转换为 `Int` 失败
- Swift 的 `as?` 在类型不匹配时返回 `nil`，导致计数获取失败

**修复方案**:
- 将 `as? Int` 改为 `as? Int64`，然后转换为 `Int(count)`

**技术细节**:
```swift
// ❌ 错误写法（Int64 无法直接转换为 Int）
if let count = first["count"] as? Int {
    usageRecordsCount = count
}

// ✅ 正确写法（先转换为 Int64，再转为 Int）
if let count = first["count"] as? Int64 {
    usageRecordsCount = Int(count)
}
```

**修复内容**:
1. ✅ 使用记录数查询类型转换
2. ✅ 快捷键数查询类型转换

**影响**:
- 修复后，设置面板正确显示使用记录数（2919）
- 数据验证：通过 sqlite3 命令确认数据库实际包含 2918+ 条记录
- 统计功能恢复正常

**修改文件**:
- Keymap/UI/Views/Settings/SettingsWindow.swift

### 2025-12-24 - 优化数据库统计显示

**优化内容**:
- ✅ 将"快捷键数"改为"已用快捷键"（更简洁明确）
- ✅ 统计逻辑优化：从无意义的 `shortcuts` 表改为使用记录中的不同快捷键
- ✅ 查询优化：`COUNT(DISTINCT shortcut_key) FROM usage_records`

**修改前后对比**:
```
❌ 旧显示：快捷键数: 0
✅ 新显示：已用快捷键: 116
```

**统计含义**:
- **使用记录数**: 2919（使用快捷键的总次数）
- **已用快捷键**: 116（使用过的不同快捷键种类）
- **数据解读**: 平均每种快捷键使用约 25 次（2919 ÷ 116）

**用户价值**:
- 更准确反映用户实际使用的快捷键种类
- 与使用记录数配合，清晰展示使用习惯
- 文字更简洁，界面更清爽

**修改文件**:
- Keymap/UI/Views/Settings/SettingsWindow.swift

### 2025-12-24 - 设置面板布局优化

**布局调整**:
- ✅ 左侧菜单垂直外边距增加（上下各+6px，从16px增至22px）
- ✅ 右侧内容区域底部外边距统一调整为32px（从16px增至32px，+16px）
- ✅ 所有6个设置面板（通用、快捷键、全局映射、长驻应用、数据、高级）布局一致

**视觉改进**:
- 侧边栏菜单项上下空间更加舒适
- 内容区域底部留白适中，避免内容与窗口边缘过近
- 整体视觉更加平衡和谐

**技术实现**:
- 修改 `sidebarView` 的 `.padding(.top, 22)` 和 `.padding(.bottom, 22)`
- 统一修改所有设置面板 ScrollView 的 `.padding(.bottom, 32)`
- 使用正则表达式一次性更新所有6个面板

**修改文件**:
- Keymap/UI/Views/Settings/SettingsWindow.swift

### 2025-12-23 - UI美化与菜单栏优化

**UI美化**:
- ✅ 统一所有按钮高度为28px，垂直内边距2px
- ✅ 按钮背景色：浅色模式使用白色，深色模式使用灰色
- ✅ 下拉选择框优雅重构：使用Picker + overlay实现，移除遮罩层方案
- ✅ 修复双重边框问题（触发快捷键和日志级别选择器）
- ✅ 扩展按钮点击区域到整个按钮范围（.contentShape(Rectangle())）
- ✅ 统计面板时间范围选择器改为自定义分段控制样式

**菜单栏优化**:
- ✅ 菜单栏"显示快捷键面板"显示动态快捷键 (⌘⌘)
- ✅ 快捷键根据设置自动更新（双击Cmd/Option/Control）
- ✅ 添加自定义通知 `.triggerKeyChanged` 避免无限循环
- ✅ 只更新菜单项文本，不重新创建statusItem，避免资源泄漏

**Bug修复**:
- 🐛 修复无限循环导致创建100+个菜单栏窗口的严重bug
- 🐛 修复错误的⌘Q → ⌘T重映射规则（清除UserDefaults中的历史规则）
- 🐛 修复按钮只能点击文字区域的问题
- 🐛 修复下拉选择框显示两个箭头的问题

**技术细节**:
- 移除了 `UserDefaults.didChangeNotification` 全局监听（导致无限循环）
- 使用自定义 `.triggerKeyChanged` 通知实现精确更新
- 下拉选择框使用 ZStack + Picker（opacity: 0.01）+ 自定义overlay
- 保存 `showPanelMenuItem` 引用，只更新 title 不重建菜单

**修改文件**:
- Keymap/UI/Views/Settings/SettingsWindow.swift（下拉选择框重构）
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelView.swift（按钮美化）
- Keymap/UI/Views/Statistics/StatisticsWindow.swift（时间选择器和按钮美化）
- Keymap/App/AppDelegate.swift（菜单栏动态快捷键）
- Keymap/Data/SettingsManager.swift（添加 .triggerKeyChanged 通知）

### 2025-12-21 - UI优化与Bug修复
**新增功能**:
- ✅ 添加应用图标和菜单栏图标（PDF矢量格式，支持Retina显示）
- ✅ 添加 AccentColor 资源（支持亮色/暗色模式）
- ✅ 添加 "在Dock显示图标" 设置项（默认开启）
- ✅ 创建 NotificationHelper 工具类（使用现代 UserNotifications API）

**优化改进**:
- ✅ 快捷键窗口默认在屏幕水平、垂直方向居中显示
- ✅ 设置面板侧边栏整行可点击（不仅限于图标和文字）
- ✅ 菜单栏图标使用 PDF 矢量格式，支持任意分辨率
- ✅ 设置面板"关于"页面显示实际应用图标

**Bug修复**:
- 🐛 修复 NSUserNotification 弃用警告（16处）
- 🐛 修复未使用变量警告（4处）
- 🐛 修复 Cmd+, 打开空白设置窗口问题
- 🐛 修复菜单栏显示错误快捷键（Cmd+S → 双击⌘）
- 🐛 修复无限循环导致菜单栏出现100+应用图标的严重bug

**技术细节**:
- 移除了 UserDefaults.didChangeNotification 监听器（避免无限循环）
- 使用 .contentShape(Rectangle()) 扩展按钮点击区域
- 菜单栏图标设置：preserves-vector-representation: true
- Dock 图标可点击打开快捷键面板（applicationShouldHandleReopen）

**修改文件**:
- Keymap/Resources/Assets.xcassets/ (新增)
- Keymap/Utilities/NotificationHelper.swift (新增)
- Keymap/App/AppDelegate.swift
- Keymap/App/KeymapApp.swift
- Keymap/Data/SettingsManager.swift
- Keymap/UI/Views/Settings/SettingsWindow.swift
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelWindow.swift
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelView.swift
- Keymap/UI/Views/Statistics/StatisticsWindow.swift
- Keymap/Utilities/PermissionManager.swift
- Keymap/Core/ConflictDetection/ConflictDetector.swift
- Keymap/Data/DatabaseManager.swift
- Keymap/Data/Repositories/ShortcutRepository.swift

### 2025-12-22 - Keymap 自身快捷键与 UI 优化

**新增功能**:
- ✅ 创建 KeymapShortcutProvider 类，提供 Keymap 自身的 4 个快捷键
- ✅ 为"统计分析"功能添加快捷键 ⌘D
- ✅ Keymap 应用快捷键面板正确显示实际快捷键（不再显示演示数据）

**Keymap 快捷键列表**:
- ⌘⌘ - 显示快捷键面板
- ⌘D - 统计分析
- ⌘, - 设置
- ⌘Q - 退出 Keymap

**UI 优化**:
- ✅ 完全移除应用菜单栏（文件、编辑、显示等），只保留苹果菜单
- ✅ 简化菜单栏图标弹出菜单（移除"显示快捷键面板"的快捷键显示）
- ✅ 设置面板：触发快捷键从分段控制改为下拉选择
- ✅ 快捷键面板：双击⌘ 显示为 ⌘⌘
- ✅ 简化关于页面和系统关于面板的版权信息（只保留 Copyright 2025 David Lan）

**修改文件**:
- Keymap/Core/ShortcutExtraction/KeymapShortcutProvider.swift (新增)
- Keymap/UI/ViewModels/ShortcutPanelViewModel.swift
- Keymap/App/AppDelegate.swift
- Keymap/App/KeymapApp.swift
- Keymap/UI/Views/Settings/SettingsWindow.swift
- Keymap/App/Info.plist

### 2025-12-22 - 设置功能完善与日志系统

**新增功能**:
- ✅ 开机自动启动（使用 SMAppService API，macOS 13+）
- ✅ 显示冲突通知开关（可在设置中关闭系统通知）
- ✅ 触发快捷键选择（支持双击Cmd/Option/Control三种修饰键）
- ✅ 面板自动关闭延迟（0-30秒可调，0为禁用）
- ✅ 全局快捷键重映射开关（可在设置中禁用重映射功能）
- ✅ 完整日志系统（5级日志：off/error/warning/info/debug）
- ✅ 快捷键录制功能（实验性功能，支持自定义快捷键录制）

**功能优化**:
- ✅ 双击Cmd阈值可调节（从 SettingsManager 读取，不再硬编码）
- ✅ 缓存时长可调节（1-72小时，从设置读取）
- ✅ 最大缓存应用数可调节（10-100个，从设置读取）
- ✅ 双击检测器完全重构（支持多种修饰键，ModifierKey枚举）
- ✅ 所有设置实时保存并生效（使用Combine框架双向绑定）

**技术实现**:
- **Logger系统**:
  - 五级日志控制（off=0, error=1, warning=2, info=3, debug=4）
  - 格式化输出：时间戳 + 级别 + Emoji + 消息
  - Debug级别包含文件名和行号
  - 从SettingsManager动态读取日志级别

- **KeyRecorder录制器**:
  - 使用 NSEvent.addLocalMonitorForEvents 监听按键
  - 自动过滤单独修饰键
  - 支持特殊键（F1-F20、方向键、Space等）
  - 录制完成后自动停止并回调

- **DoubleCmdDetector重构**:
  - ModifierKey枚举（command/option/control）
  - 动态读取triggerKey设置
  - 使用Logger替代所有print语句

- **面板自动关闭**:
  - Timer实现定时关闭
  - 支持0秒禁用功能
  - 窗口显示/隐藏时自动管理Timer

**Bug修复**:
- 🐛 修复KeyCombination初始化错误（displayString是计算属性，不是参数）
- 🐛 修复NSEvent监听器返回类型错误（显式声明 -> NSEvent?）

**修改文件**:
- Keymap/Data/SettingsManager.swift（新增5个配置项和相关逻辑）
- Keymap/Core/Monitoring/DoubleCmdDetector.swift（完全重构）
- Keymap/Core/ShortcutExtraction/ShortcutCache.swift（从设置读取配置）
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelWindow.swift（新增自动关闭Timer）
- Keymap/Core/Monitoring/GlobalEventMonitor.swift（新增功能开关检查）
- Keymap/UI/Views/Settings/SettingsWindow.swift（实现所有设置功能和观察器）
- Keymap/Utilities/Logger.swift（新增）
- Keymap/Core/Recording/KeyRecorder.swift（新增）

**配置项新增**:
```swift
// SettingsManager 新增配置键
showConflictNotifications: Bool = true
panelAutoCloseDelay: TimeInterval = 0
logLevel: Int = 2  // warning
enableGlobalRemapping: Bool = false
enableRecordingMode: Bool = false
```

### 2025-12-23 - 全局映射面板UI优化

**长驻应用列表智能过滤**:
- ✅ 只显示有快捷键的应用（shortcutCount > 0）
- ✅ 添加系统核心进程黑名单（40+个系统组件）
- ✅ 排除Helper/Plugin/Renderer等辅助进程
- ✅ 第三方应用优先排序
- ✅ 用户手动标记的应用始终显示

**全局映射面板UI优化**:
- ✅ 添加按钮样式匹配长驻应用面板（28px高度，白色/灰色背景）
- ✅ 面板顶部间距统一为16px（.padding(.top, 16)）
- ✅ 整体布局参考长驻应用面板

**添加/编辑映射弹窗重构**:
- ✅ 弹窗宽度缩小1/3（450px → 300px）
- ✅ 高度改为自适应（移除固定500px）
- ✅ 输入框高度统一28px，样式匹配快捷键面板
- ✅ 添加快捷键录制功能（源快捷键 + 目标快捷键）
- ✅ 录制按钮受"高级设置 → 启用快捷键录制模式"控制
- ✅ 录制状态视觉反馈（录制时输入框变灰，按钮变红）
- ✅ 取消/添加/保存按钮样式统一

**快捷键显示样式统一**:
- ✅ 映射规则列表快捷键使用KeyBadge风格
- ✅ 深色背景：深色模式Color(white: 0.3)，浅色模式Color(white: 0.25)
- ✅ 白色文字 + 中等字重
- ✅ 紧凑内边距（horizontal: 4px, vertical: 1px）
- ✅ 与快捷键面板样式完全一致

**清空所有按钮优化**:
- ✅ 高度统一28px
- ✅ 红色半透明背景（Color.red.opacity(0.15)）+ 红色边框
- ✅ 字体和内边距与其他按钮统一

**技术细节**:
- **GlobalShortcutDatabase.swift**: 
  - 新增 `shouldExcludeSystemProcess()` 方法
  - 增强 `identifyBackgroundApps()` 智能过滤逻辑
  - 系统进程黑名单包含辅助功能、系统代理、核心组件等
  
- **SettingsWindow.swift**:
  - `AddRemappingSheet` 和 `EditRemappingSheet` 完全重构
  - 添加录制状态管理（@State isRecordingFrom/To）
  - 集成 KeyRecorder 实现快捷键录制
  - 快捷键显示样式从半透明色块改为KeyBadge风格
  - 清空所有按钮从简单文本改为规范按钮样式

**视觉改进**:
- 弹窗更紧凑，高度自适应避免空白
- 所有面板顶部间距统一，视觉更整洁
- 快捷键清晰醒目，深色背景 + 白色文字
- 所有按钮28px高度，样式协调统一

**修改文件**:
- Keymap/Core/Monitoring/GlobalShortcutDatabase.swift
- Keymap/UI/Views/Settings/SettingsWindow.swift

### 2025-12-23 - 添加/编辑映射弹窗优化（第二轮）

**布局优化**:
- ✅ 标题水平居中（移除 VStack alignment: .leading）
- ✅ 添加副标题说明
  - 添加映射："自定义快捷键重映射，将源键映射到目标键"
  - 编辑映射："修改快捷键映射规则，调整源键或目标键"
- ✅ 添加 Divider 分隔标题和内容区域
- ✅ 表单内容保持左对齐（嵌套 VStack）
- ✅ 减小弹窗高度32px（表单间距从 20px 减小到 12px）

**视觉改进**:
- 标题区域居中显示更专业
- 副标题提供清晰的功能说明
- Divider 明确分隔标题和表单
- 更紧凑的表单布局，减少不必要的空白

**技术实现**:
- 主 VStack 改为 `VStack(spacing: 20)` 以支持居中标题
- 标题使用独立的 `VStack(spacing: 4)` 包含标题和副标题
- 表单内容包裹在 `VStack(alignment: .leading, spacing: 12)` 中
- 完全参考了 ShortcutPanelView 中 RemappingDialogView 的布局模式

**间距优化详情**:
- 表单内容 VStack 间距：20px → 12px
- 节省高度计算：(源快捷键 + 目标快捷键 + 应用范围 + 按钮) × (20-12)px = 32px
- 底部按钮上方空白显著减少

**修改文件**:
- Keymap/UI/Views/Settings/SettingsWindow.swift
  - AddRemappingSheet: 标题居中、副标题、Divider、间距优化
  - EditRemappingSheet: 标题居中、副标题、Divider、间距优化

### 2025-12-23 - 快捷键面板失去焦点自动关闭

**功能优化**:
- ✅ 点击面板外部区域自动关闭面板
- ✅ 窗口失去焦点时自动隐藏
- ✅ 失去焦点时自动清理资源（ESC监听器、自动关闭定时器）
- ✅ 保留原有的 ESC 键关闭功能
- ✅ 保留原有的自动关闭定时器功能

**技术实现**:
- 设置 `hidesOnDeactivate = true` - NSPanel 在失去主窗口状态时自动隐藏
- 添加 `NSWindow.didResignMainNotification` 通知监听
- 在 `handleWindowResignMain()` 中清理资源（移除ESC监听器、停止定时器）
- 在 `deinit` 中移除通知观察者，避免内存泄漏

**用户体验提升**:
- 更符合 macOS 浮动面板的标准行为
- 用户现在有三种方式关闭面板：
  1. 点击面板外部任意区域（新增）
  2. 按 ESC 键（保留）
  3. 等待自动关闭定时器（保留，可在设置中配置）

**修改文件**:
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelWindow.swift
  - `hidesOnDeactivate` 从 false 改为 true
  - 添加窗口失去焦点的通知监听
  - 添加 `handleWindowResignMain()` 方法清理资源
  - 在 `deinit` 中移除通知观察者

### 2025-12-23 - App Logo 更新为 PDF 矢量格式

**图标更新**:
- ✅ 使用 1024x1024 PDF 矢量格式作为 App Logo
- ✅ 启用 `preserves-vector-representation` 保持矢量特性
- ✅ 清理旧的 PNG 图标文件（icon_512x512.png, icon_512x512@2x.png）
- ✅ 清理旧的 512x512 PDF 文件（logo-512.pdf）
- ✅ 所有显示 App Icon 的地方自动使用新 logo

**技术实现**:
```json
{
  "images": [
    {
      "filename": "logo-1024.pdf",
      "idiom": "mac",
      "scale": "1x",
      "size": "512x512"
    },
    {
      "filename": "logo-1024.pdf",
      "idiom": "mac",
      "scale": "2x",
      "size": "512x512"
    }
  ],
  "properties": {
    "preserves-vector-representation": true
  }
}
```

**矢量格式优势**:
- 📐 任意缩放都保持清晰锐利
- 💾 单一文件体积小（6KB）
- 🎯 Retina 显示完美支持
- 🔄 只需维护一个源文件

**显示位置**:
- Dock 应用图标
- 关于页面（About）
- 系统关于面板
- Finder 中的应用图标
- 启动台（Launchpad）

**注意事项**:
- Xcode 编译时会报 "PDF 文件扩展名无效" 警告，这是已知限制
- 构建成功，PDF 格式在运行时正常显示
- macOS 14.0+ 完全支持 PDF 矢量 app icon

**修改文件**:
- Keymap/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
- Keymap/Resources/Assets.xcassets/AppIcon.appiconset/logo-1024.pdf（新增）
- 删除：icon_512x512.png, icon_512x512@2x.png, logo-512.pdf

### 2025-12-25 - 安全增强：移除危险脚本与权限配置

**安全问题修复**:
- ❌ 移除 `scripts/clean_metal_cache.sh` 脚本
  - 脚本包含不安全的 `rm -rf` 命令
  - 可能导致意外删除系统文件或应用
  - 已在执行过程中导致应用被误删

**全局安全配置**:
- ✅ 创建严格的 Claude Code 权限规则（`~/.claude/settings.json`）
- ✅ 文件访问限制：仅允许 `~/Sites`, `~/Documents`, `~/Desktop`, `~/Downloads`
- ✅ 禁止访问系统目录：`/System`, `/Library`, `/Applications`, `/usr`, `/etc`
- ✅ 禁止访问敏感配置：`~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.kube`

**危险命令完全禁止**:
- ❌ `rm`, `rmdir` - 删除文件/目录
- ❌ `sudo` - 管理员权限
- ❌ `brew uninstall/remove` - 卸载软件
- ❌ `mas uninstall` - 卸载 App Store 应用
- ❌ `npm uninstall -g` - 卸载全局包
- ❌ `xcode-select --reset` - 重置 Xcode
- ❌ `killall`, `pkill` - 结束进程

**需确认的危险操作**:
- ⚠️ `git clean` - 清理未跟踪文件
- ⚠️ `git reset --hard` - 硬重置仓库
- ⚠️ `defaults delete` - 删除系统配置

**影响**:
- Claude Code 无法执行任何删除操作
- 无法访问系统关键目录
- 项目文件受到完整保护
- 不影响用户手动在终端执行命令

**修改文件**:
- /Users/David/.claude/settings.json（新增安全规则）
- scripts/clean_metal_cache.sh（已删除）

### 2025-12-25 - 代码质量提升：修复 9 个编译警告

**已修复警告** (9/12):

1. **AppDelegate.swift** - 字符串插值可选值警告（1处）
   - ❌ 旧代码：`updateMenuItemShortcutDisplay(showPanelMenuItem!)`
   - ✅ 新代码：使用局部变量 `panelMenuItem` 避免强制解包
   - 问题：Optional 强制解包会产生警告

2. **ShortcutPanelView.swift** - onChange API 弃用警告（2处）
   - ❌ 旧 API：`.onChange(of: value) { newValue in }`
   - ✅ 新 API：`.onChange(of: value) { _, newValue in }`
   - 位置：showingRemappingDialog (60行)、newKeyCombination (517行)

3. **StatisticsWindow.swift** - onChange API 弃用警告（6处）
   - ❌ 旧 API：`.onChange(of: value) { newValue in }`
   - ✅ 新 API：`.onChange(of: value) { _, newValue in }`
   - 位置：
     - AnimatedStatisticCard: targetValue (1025行)、isAnimating (1035行)
     - AnimatedProgressView: progress (1112行)、isAnimating (1121行)
     - AnimatedBarView: targetHeight (1186行)、isAnimating (1195行)

**剩余警告** (3/12):
- Assets.xcassets - PDF 图标警告（3个）
  - "PDF 文件扩展名无效"（2个）
  - "logo-1024.pdf 是 1024x1024 但应该是 512x512"（1个）
  - **已知限制**：不影响功能，PDF 矢量格式正常运行

**技术改进**:
- ✅ 遵循 macOS 14.0+ SwiftUI 最佳实践
- ✅ 使用新版 onChange API（两参数闭包）
- ✅ 避免可选值强制解包
- ✅ 消除弃用 API 警告
- ✅ 提升代码可维护性

**修改文件**:
- Keymap/App/AppDelegate.swift
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelView.swift
- Keymap/UI/Views/Statistics/StatisticsWindow.swift


### 2025-12-25 - 双语支持完整实现（阶段 1 完成）

**功能实现**:
- ✅ 创建双语本地化资源（英文 + 简体中文）
- ✅ 217 条完整本地化字符串
- ✅ 枚举类型国际化重构（4个枚举，21个枚举值）
- ✅ 数据库枚举值自动迁移（中文 → 英文）
- ✅ UI 代码完整本地化（4个主要文件）
- ✅ 编译通过，无错误

**新增文件**:
- `Keymap/Utilities/LocalizationManager.swift` - 本地化管理器
- `Keymap/Data/Migrations/EnumMigration.swift` - 数据库迁移脚本
- `Keymap/Resources/Localizations/en.lproj/Localizable.strings` - 英文本地化（217条）
- `Keymap/Resources/Localizations/zh-Hans.lproj/Localizable.strings` - 简体中文本地化（217条）

**枚举重构**:
1. **ShortcutCategory** (7个值): 文件/编辑/视图/窗口/系统/导航/其他
   - rawValue: 中文 → 英文（如 "文件" → "file"）
   - 新增 `displayName` 属性返回本地化字符串
2. **ConflictType** (4个值): 系统级/应用级/全局/功能
3. **ConflictSeverity** (3个值): 低/中/高
4. **UsageContext** (3个值): 正常/冲突/重映射

**数据库迁移**:
- 自动检测中文枚举值并迁移到英文
- 支持三张表迁移：shortcuts、conflicts、usage_records
- 安全机制：事务保护、自动备份、失败回滚
- 统计功能：显示迁移前后的记录数

**本地化覆盖**:
- 设置窗口（80+ 字符串）
- 快捷键面板（40+ 字符串）
- 菜单栏（20+ 字符串）
- 统计窗口（30+ 字符串）
- 通知消息（20+ 字符串）
- 冲突详情（15+ 字符串）
- 通用操作（12+ 字符串）

**本地化键命名规范**:
- `settings.*` - 设置相关
- `panel.*` - 面板相关
- `menu.*` - 菜单栏
- `conflict.*` - 冲突相关
- `notification.*` - 通知相关
- `statistics.*` - 统计相关
- `action.*` - 操作按钮
- `category.*` - 快捷键分类
- `common.*` - 通用短语

**技术要点**:
- 使用 String Extension `.localized()` 方法
- 支持 `String(format:)` 进行字符串插值
- `LocalizationManager` 提供便捷方法 `.localized(with:)`
- 所有硬编码字符串替换为本地化键
- 应用启动时自动执行数据库迁移

**文件修改统计**:
- 新增文件：4个
- 修改文件：8个
  - `ShortcutInfo.swift` - 枚举重构
  - `ConflictInfo.swift` - 枚举重构
  - `UsageRecord.swift` - 枚举重构
  - `ConflictResolver.swift` - 枚举重构
  - `SettingsWindow.swift` - 100+ 处本地化
  - `ShortcutPanelView.swift` - 40+ 处本地化
  - `AppDelegate.swift` - 20+ 处本地化 + 迁移集成
  - `StatisticsWindow.swift` - 15+ 处本地化

**编译结果**:
- ✅ 编译成功（BUILD SUCCEEDED）
- ⚠️ 3个PDF图标警告（已知限制，不影响功能）
- ❌ 0个编译错误

**下一步**:
- 在设置面板添加语言切换功能（系统/英文/简体中文）
- 实现应用重启后语言切换生效
- 测试所有UI界面的本地化显示
- 添加语言切换后的UI刷新逻辑

### 2025-12-26 - 双语支持完善：修复所有残留中文文本 📝

**问题发现**:
- 🐛 用户测试发现多处界面仍显示中文硬编码文本
- 🐛 系统快捷键（30个）未本地化
- 🐛 设置面板多个板块存在中文文本

**修复内容**:

**1. 设置面板本地化修复**（SettingsWindow.swift）：
- ✅ 修复"检测设置"板块标题（settings.section.detection）
- ✅ 修复"缓存设置"板块标题（settings.section.cache）
- ✅ 修复"清理旧数据"板块标题（settings.section.cleanup）
- ✅ 修复"导出/导入"板块标题（settings.section.export_import）
- ✅ 修复"数据库信息"板块标题（settings.section.database_info）
- ✅ 修复数据库信息标签：database.size、database.usage_records、database.shortcuts_used
- ✅ 修复关于页面标签：about.version、about.system_requirements
- ✅ 修复录制按钮文本：recording.stop、recording.record
- ✅ 修复输入框占位符：recording.placeholder_recording、recording.placeholder_example、recording.placeholder_example_shift
- ✅ 修复"全局应用"显示：scope.global_app

**2. 统计面板优化**（StatisticsWindow.swift）：
- ✅ 修复时间周期标签宽度自适应（移除固定80px宽度）
- ✅ 修复3个优化建议本地化（statistics.suggestion.*）

**3. 长驻应用激活策略**（GlobalShortcutDatabase.swift）：
- ✅ 修复激活策略描述：activation_policy.regular/accessory/prohibited/unknown

**4. 快捷键面板优化**（ShortcutPanelView.swift）：
- ✅ 修复搜索占位符：panel.search_shortcuts_placeholder
- ✅ 修复列表标题：panel.common_shortcuts_title
- ✅ 修复重映射对话框录制UI本地化

**5. Keymap 快捷键本地化**（KeymapShortcutProvider.swift）：
- ✅ 修复4个 Keymap 快捷键描述：
  - keymap.shortcut.show_panel（显示快捷键面板）
  - keymap.shortcut.statistics（统计分析）
  - keymap.shortcut.settings（设置）
  - keymap.shortcut.quit（退出 Keymap）

**6. 系统快捷键完整本地化**（SystemShortcutProvider.swift）⭐：
- ✅ 修复30个系统快捷键的硬编码中文描述
- ✅ 分类覆盖：
  - **通用操作**（15个）：退出、关闭、保存、撤销、剪切、复制、粘贴等
  - **窗口管理**（5个）：切换应用、Mission Control、显示桌面等
  - **截图工具**（4个）：全屏、区域、窗口、截图菜单
  - **Spotlight**（2个）：Spotlight搜索、Finder搜索
  - **辅助功能**（4个）：VoiceOver、缩放、反转颜色、Emoji

**本地化键新增**（共50+条）：
```
// 设置板块标题
settings.section.detection
settings.section.cache
settings.section.cleanup
settings.section.export_import
settings.section.database_info

// 数据库信息
database.size
database.usage_records
database.shortcuts_used

// 录制UI
recording.stop
recording.record
recording.placeholder_recording
recording.placeholder_example
recording.placeholder_example_shift

// 应用范围
scope.global_app

// 激活策略
activation_policy.regular
activation_policy.accessory
activation_policy.prohibited
activation_policy.unknown

// 快捷键面板
panel.search_shortcuts_placeholder
panel.common_shortcuts_title

// Keymap快捷键
keymap.shortcut.show_panel
keymap.shortcut.statistics
keymap.shortcut.settings
keymap.shortcut.quit

// 系统快捷键（30个）
system.quit_app
system.close_window
system.app_switcher
system.screenshot_full
system.zoom
// ... 等30个系统快捷键
```

**技术说明**：

**快捷键来源机制** 🔍：
1. **系统快捷键**（Keymap 硬编码提供）：
   - 由 `SystemShortcutProvider` 和 `KeymapShortcutProvider` 提供
   - 描述**根据 Keymap 语言设置**显示
   - 完全支持本地化（中/英）

2. **应用快捷键**（从应用菜单提取）：
   - 通过 macOS Accessibility API 从应用菜单动态读取
   - 描述**来自应用本身的菜单文本**
   - 语言取决于应用的语言设置（如 VS Code 的界面语言）
   - Keymap 只能"读取"而非"翻译"这些文本

**示例**：
- 用户设置 Keymap 为中文，VS Code 为英文时：
  - ✅ 系统快捷键显示中文："⌘Q 退出应用"
  - ℹ️ VS Code快捷键显示英文："⌘W Close Editor"（来自VS Code菜单）

**修改文件**（9个）：
- Keymap/UI/Views/Settings/SettingsWindow.swift
- Keymap/UI/Views/Statistics/StatisticsWindow.swift
- Keymap/Core/Monitoring/GlobalShortcutDatabase.swift
- Keymap/UI/Views/ShortcutPanel/ShortcutPanelView.swift
- Keymap/Core/ShortcutExtraction/KeymapShortcutProvider.swift
- Keymap/Core/ShortcutExtraction/SystemShortcutProvider.swift
- Keymap/Resources/Localizations/zh-Hans.lproj/Localizable.strings
- Keymap/Resources/Localizations/en.lproj/Localizable.strings
- Keymap/App/AppDelegate.swift（添加 LocalizationManager 初始化）

**本地化覆盖率**：
- ✅ 设置窗口：100%（所有板块、标签、按钮）
- ✅ 快捷键面板：100%（搜索、列表、对话框）
- ✅ 统计窗口：100%（图表、建议、标签）
- ✅ 系统快捷键：100%（30个系统快捷键）
- ✅ Keymap快捷键：100%（4个应用快捷键）
- ℹ️ 第三方应用快捷键：取决于应用自身语言设置

**编译结果**：
- ✅ 编译成功（BUILD SUCCEEDED）
- ⚠️ 3个PDF图标警告（已知限制，不影响功能）

**测试验证**：
- ✅ 英文界面下所有 Keymap 提供的文本显示英文
- ✅ 中文界面下所有 Keymap 提供的文本显示中文
- ✅ 第三方应用快捷键正确反映应用菜单语言

**下一步计划**：
- 🌍 支持其他8种语言（日文、韩文、德文、法文、西班牙文、意大利文、俄文、葡萄牙文）
- 📱 测试所有语言的UI显示效果
- 🔄 完善语言切换后的实时UI刷新
- 📦 合并到主分支并发布多语言版本

### 2025-12-26 下午 - 新增"显示系统快捷键"设置功能

**新增功能**：
- ✅ 在设置面板添加"显示系统快捷键"开关
- ✅ 用户可选择是否在快捷键面板中显示 macOS 系统快捷键
- ✅ 完整的中英双语支持
- ✅ 设置持久化和导入/导出支持

**实现细节**：
- 配置键：`showSystemShortcuts`（默认值：`true`）
- UI 位置：设置面板 → 快捷键 → 显示系统快捷键
- 逻辑优化：关闭时直接跳过系统快捷键合并，提升性能
- 设置实时生效，无需重启应用

**本地化键**：
```
// 英文
"settings.show_system_shortcuts" = "Show System Shortcuts";
"settings.show_system_shortcuts.description" = "Display macOS system shortcuts (⌘Q, ⌘Space, etc.) in shortcut panel";

// 中文
"settings.show_system_shortcuts" = "显示系统快捷键";
"settings.show_system_shortcuts.description" = "在快捷键面板中显示 macOS 系统快捷键（⌘Q、⌘Space 等）";
```

**使用场景**：
- **开启状态**（默认）：快捷键面板显示应用快捷键 + 系统快捷键（30个），提供完整视图
- **关闭状态**：快捷键面板仅显示应用自身快捷键，隐藏所有系统快捷键

**技术实现**：
- `SettingsManager` 添加配置项和持久化逻辑
- `ShortcutPanelViewModel.mergeWithSystemShortcuts()` 根据设置动态显示/隐藏
- `SettingsWindow` 添加 Toggle UI 和双向绑定
- 支持设置导入/导出功能

**修改文件**：
- Keymap/Data/SettingsManager.swift
- Keymap/Resources/Localizations/en.lproj/Localizable.strings
- Keymap/Resources/Localizations/zh-Hans.lproj/Localizable.strings
- Keymap/UI/Views/Settings/SettingsWindow.swift
- Keymap/UI/ViewModels/ShortcutPanelViewModel.swift

**编译结果**：
- ✅ 编译成功（BUILD SUCCEEDED）
- ✅ 无错误无警告
- ✅ 功能测试验证成功

