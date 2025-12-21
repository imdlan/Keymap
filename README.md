# Keymap - macOS 快捷键管理工具

一个macOS平台的快捷键冲突检测与管理工具，提供实时冲突检测、可视化快捷键展示、临时修改功能以及详细的统计分析。

## 项目概述

- **开发语言**: Swift
- **UI框架**: SwiftUI + AppKit桥接
- **最低支持**: macOS 14.0
- **架构模式**: MVVM + Repository + 事件驱动

## 核心功能

1. **全局快捷键监控** - 实时监控系统级快捷键使用
2. **快捷键可视化面板** - 双击Cmd触发半透明浮动窗口
3. **冲突检测与分析** - 自动检测并分析快捷键冲突
4. **临时快捷键重映射** - 允许临时修改快捷键映射
5. **统计分析** - 提供使用统计和优化建议

## 项目结构

```
Keymap/
├── docs/                            # 📁 文档目录
│   ├── development/                 # 开发文档
│   ├── stages/                      # 阶段总结
│   ├── testing/                     # 测试文档
│   └── design/                      # 设计文档
├── scripts/                         # 🔧 工具脚本
│   ├── build_and_copy.sh           # 构建脚本
│   ├── run.sh, run_in_xcode.sh     # 运行脚本
│   └── verify/                      # 验证工具
├── Keymap/                          # 主应用（非沙盒版）
│   ├── App/                         # 应用入口
│   │   ├── KeymapApp.swift         # SwiftUI应用入口
│   │   ├── AppDelegate.swift       # AppKit生命周期管理
│   │   └── Info.plist
│   ├── Core/                        # 核心功能模块
│   │   ├── Monitoring/             # 监控模块
│   │   ├── ShortcutExtraction/     # 快捷键提取
│   │   ├── ConflictDetection/      # 冲突检测
│   │   ├── Remapping/              # 快捷键重映射
│   │   └── Statistics/             # 统计分析
│   ├── UI/                          # 用户界面
│   │   ├── Views/                  # SwiftUI视图
│   │   ├── ViewModels/             # 视图模型
│   │   └── Components/             # UI组件
│   ├── Models/                      # 数据模型
│   ├── Data/                        # 数据持久化
│   ├── Utilities/                   # 工具类
│   └── Resources/                   # 资源文件
└── KeymapSandbox/                   # 沙盒版本（App Store）
```

## 如何创建Xcode项目

由于代码结构已经创建，您需要在Xcode中创建项目并导入这些文件：

### 步骤1: 创建新项目

1. 打开Xcode
2. 选择 **File → New → Project**
3. 选择 **macOS → App**
4. 配置项目:
   - Product Name: `Keymap`
   - Team: 选择您的开发团队
   - Organization Identifier: `com.yourcompany`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ❌ 不勾选 **Use Core Data**
   - ❌ 不勾选 **Include Tests**（我们稍后手动添加）
5. 选择保存位置为 `/Users/David/Sites/Keymap`
6. **重要**: 不要让Xcode创建默认的ContentView.swift，我们已经有了自定义文件

### 步骤2: 删除默认文件并导入我们的文件

1. 删除Xcode自动创建的 `ContentView.swift`
2. 在Xcode的Project Navigator中，右键点击项目根目录
3. 选择 **Add Files to "Keymap"**
4. 导航到 `/Users/David/Sites/Keymap/Keymap` 目录
5. 选择所有文件夹（App, Core, UI, Models, Data, Utilities, Resources）
6. 确保勾选:
   - ✅ Copy items if needed (如果需要)
   - ✅ Create groups
   - ✅ Add to targets: Keymap

### 步骤3: 配置项目设置

#### 3.1 General 设置

1. 选择项目 → Keymap Target
2. 在 **General** 标签页:
   - Deployment Target: `macOS 14.0`
   - Bundle Identifier: `com.yourcompany.Keymap`

#### 3.2 Signing & Capabilities

1. 在 **Signing & Capabilities** 标签页:
   - ✅ Automatically manage signing
   - 选择您的开发团队

2. 点击 **+ Capability** 添加权限:
   - 由于是非沙盒应用，不需要添加App Sandbox
   - 确保Entitlements文件路径正确

#### 3.3 Build Settings

1. 在 **Build Settings** 标签页:
   - 搜索 "Code Signing Entitlements"
   - 设置为: `Keymap/Resources/Entitlements.plist`

2. 搜索 "Info.plist File"
   - 设置为: `Keymap/App/Info.plist`

### 步骤4: 添加必要的框架

在 **Frameworks, Libraries, and Embedded Content** 中，确保包含:
- SwiftUI.framework
- AppKit.framework
- Carbon.framework

### 步骤5: 创建第二个目标（沙盒版本）- 可选

如果需要App Store版本:

1. 右键点击Keymap Target → Duplicate
2. 重命名为 `KeymapSandbox`
3. 修改其Entitlements文件路径为: `KeymapSandbox/Entitlements-Sandbox.plist`
4. 修改Bundle Identifier为: `com.yourcompany.Keymap.Sandbox`

## 运行项目

1. 选择 **Keymap** target
2. 点击 **Run** (⌘R)
3. 首次运行时，系统会提示需要辅助功能权限
4. 前往 **系统设置 → 隐私与安全性 → 辅助功能**
5. 授予Keymap权限
6. 重启应用

## 开发进度

```
阶段1: 创建Xcode项目     [██████████] 100% ✅ 已完成
阶段2: 快捷键自动提取     [██████████] 100% ✅ 已完成
阶段3: 冲突检测引擎       [██████████] 100% ✅ 已完成
阶段4: 数据持久化         [██████████] 100% ✅ 已完成
阶段5: 快捷键重映射       [██████████] 100% ✅ 已完成
阶段6: UI和体验完善       [██████████] 100% ✅ 已完成（基础版）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
总体进度: ███████████████████░ 95%
```

### ✅ 已完成的核心功能

- **全局快捷键监控** - 实时监控系统级快捷键使用
  - 双击Cmd触发快捷键面板（浮动窗口）
  - 快捷键组合检测（⌘⇧⌥⌃）
  - 使用统计自动记录
  - ESC关闭快捷键面板

- **快捷键自动提取** - 从应用菜单提取快捷键
  - 使用Accessibility API访问应用菜单
  - 30个系统快捷键硬编码列表
  - 两层缓存机制（NSCache + UserDefaults）

- **冲突检测引擎** - 智能冲突检测与解决建议
  - 四种冲突类型（系统级、全局、应用级、功能级）
  - 实时冲突检测集成
  - 智能替代快捷键建议

- **数据持久化** - SQLite数据库存储
  - 5张表：应用、快捷键、冲突、使用记录、统计摘要
  - Repository模式数据访问层
  - 使用统计自动聚合

- **快捷键重映射** - 临时修改快捷键映射
  - CGEvent拦截和修改
  - 智能规则验证（防循环、防链式）
  - 重映射规则持久化

- **UI界面（基础版）** - 可视化界面已完成
  - 快捷键面板（双击Cmd触发）
  - 统计分析窗口（使用频率、趋势图）
  - 设置窗口（配置管理）
  - 重映射UI（快捷键面板集成）

### 🚧 待完善功能

- 性能优化（目标：CPU<5%，内存<100MB）
- 完整的冲突解决UI流程
- 配置导入/导出功能
- App Store版本准备

详见项目计划文档: `docs/development/PLAN.md`

## 关键文件说明

### 应用入口
- `App/KeymapApp.swift` - SwiftUI应用入口
- `App/AppDelegate.swift` - AppKit生命周期管理，菜单栏、全局监控初始化

### 核心监控
- `Core/Monitoring/GlobalEventMonitor.swift` - 全局事件监控核心（CGEvent API）
- `Core/Monitoring/KeyCombinationDetector.swift` - 快捷键组合检测
- `Core/Monitoring/DoubleCmdDetector.swift` - 双击Cmd检测

### 快捷键提取
- `Core/ShortcutExtraction/AppShortcutExtractor.swift` - 应用快捷键提取器（Accessibility API）
- `Core/ShortcutExtraction/MenuItemParser.swift` - 菜单项解析工具
- `Core/ShortcutExtraction/SystemShortcutProvider.swift` - 系统快捷键提供者（30个）
- `Core/ShortcutExtraction/ShortcutCache.swift` - 两层缓存管理

### 冲突检测
- `Core/ConflictDetection/ConflictDetector.swift` - 冲突检测引擎
- `Core/ConflictDetection/ConflictAnalyzer.swift` - 冲突分析与建议生成
- `Core/ConflictDetection/ConflictResolver.swift` - 冲突解决方案执行

### 数据持久化
- `Data/DatabaseManager.swift` - SQLite数据库管理器（单例）
- `Data/Repositories/ShortcutRepository.swift` - 快捷键数据访问层
- `Data/Repositories/UsageRepository.swift` - 使用记录数据访问层
- `Data/SettingsManager.swift` - 用户设置管理（UserDefaults）

### 快捷键重映射
- `Core/Remapping/RemappingEngine.swift` - 重映射引擎（CGEvent拦截）
- `Core/Remapping/RemappingManager.swift` - 重映射规则管理（单例）

### 用户界面
- `UI/Views/ShortcutPanel/ShortcutPanelWindow.swift` - 快捷键面板窗口控制器
- `UI/Views/ShortcutPanel/ShortcutPanelView.swift` - SwiftUI面板视图
- `UI/ViewModels/ShortcutPanelViewModel.swift` - 面板视图模型（MVVM）

### 数据模型
- `Models/ShortcutInfo.swift` - 快捷键信息
- `Models/ConflictInfo.swift` - 冲突信息
- `Models/UsageRecord.swift` - 使用记录
- `Models/StatisticsSummary.swift` - 统计摘要
- `Models/KeyCombination.swift` - 快捷键组合

### 工具类
- `Utilities/PermissionManager.swift` - 权限管理
- `Utilities/NotificationNames.swift` - 通知名称定义

## 技术要点

### 权限要求

应用需要以下权限:

1. **辅助功能权限** (必需)
   - 用于全局键盘事件监控
   - 用于提取应用菜单快捷键

2. **Apple Events权限** (可选)
   - 用于与其他应用交互

### SwiftUI + AppKit桥接

由于需要使用CGEvent API和全局事件监控，必须使用AppKit:
- 使用`NSApplicationDelegateAdaptor`集成AppDelegate
- 使用`NSPanel`承载SwiftUI视图
- 使用`NSHostingView`将SwiftUI嵌入AppKit

### 菜单栏应用配置

在Info.plist中设置:
```xml
<key>LSUIElement</key>
<true/>
```
这使应用成为菜单栏应用，不在Dock中显示。

## 故障排除

### 问题: 应用无法监控键盘事件
**解决**:
1. 检查是否授予了辅助功能权限
2. 在系统设置中移除并重新添加Keymap权限
3. 重启应用

### 问题: 双击Cmd无反应
**解决**:
1. 检查控制台日志是否有错误
2. 确认GlobalEventMonitor已启动
3. 调整`DoubleCmdDetector`的`doublePressThreshold`阈值

### 问题: 编译错误
**解决**:
1. 确认macOS版本 >= 14.0
2. 确认Xcode版本 >= 15.0
3. 清理构建文件夹 (⇧⌘K)
4. 检查所有文件是否正确添加到target

## 性能目标

- **CPU使用率**: < 5%（后台运行）
- **内存占用**: < 100MB
- **启动时间**: < 2秒
- **面板响应时间**: < 200ms
- **数据库查询**: < 100ms

## 项目文档

- **docs/development/PLAN.md** - 详细开发计划和进度跟踪
- **docs/development/BUILD_README.md** - 构建和编译指南
- **CLAUDE.md** - Claude Code 开发指南
- **QUICKSTART.md** - 快速开始指南
- **docs/testing/TEST_CHECKLIST.md** - 运行时测试清单
- **docs/testing/TEST_GUIDE.md** - 功能测试指南
- **docs/stages/** - 各阶段完成总结（STAGE1-6）
- **docs/design/** - 原始设计文档
- **scripts/README.md** - 工具脚本使用说明

## 贡献指南

待完善

## 许可证

本项目采用 Apache License 2.0 开源许可证。详见 [LICENSE](LICENSE) 文件。

Copyright 2025 David Lan. Licensed under Apache-2.0.

## 联系方式

待完善

---

**项目状态**: 🚀 基本完成 - 核心功能已完成95%，基础UI已实现

**最后更新**: 2025-12-21
