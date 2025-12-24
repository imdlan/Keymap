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

