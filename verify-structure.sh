#!/bin/bash

echo "🔍 验证Keymap项目结构..."
echo ""

# 检查目录结构
echo "📁 检查目录结构:"
dirs=(
    "Keymap/App"
    "Keymap/Core/Monitoring"
    "Keymap/Core/ShortcutExtraction"
    "Keymap/Core/ConflictDetection"
    "Keymap/Core/Remapping"
    "Keymap/Core/Statistics"
    "Keymap/UI/Views/MenuBar"
    "Keymap/UI/Views/ShortcutPanel"
    "Keymap/UI/Views/Statistics"
    "Keymap/UI/Views/Settings"
    "Keymap/UI/ViewModels"
    "Keymap/Models"
    "Keymap/Data/CoreData"
    "Keymap/Data/Repositories"
    "Keymap/Utilities"
    "Keymap/Resources"
    "KeymapSandbox"
)

all_dirs_exist=true
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir (缺失)"
        all_dirs_exist=false
    fi
done

echo ""
echo "📄 检查关键文件:"

files=(
    "Keymap/App/KeymapApp.swift"
    "Keymap/App/AppDelegate.swift"
    "Keymap/App/Info.plist"
    "Keymap/Core/Monitoring/GlobalEventMonitor.swift"
    "Keymap/Core/Monitoring/KeyCombinationDetector.swift"
    "Keymap/Core/Monitoring/DoubleCmdDetector.swift"
    "Keymap/UI/Views/ShortcutPanel/ShortcutPanelWindow.swift"
    "Keymap/UI/Views/ShortcutPanel/ShortcutPanelView.swift"
    "Keymap/UI/ViewModels/ShortcutPanelViewModel.swift"
    "Keymap/Models/ShortcutInfo.swift"
    "Keymap/Models/ConflictInfo.swift"
    "Keymap/Models/UsageRecord.swift"
    "Keymap/Models/StatisticsSummary.swift"
    "Keymap/Utilities/PermissionManager.swift"
    "Keymap/Resources/Entitlements.plist"
    "KeymapSandbox/Entitlements-Sandbox.plist"
    "README.md"
)

all_files_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (缺失)"
        all_files_exist=false
    fi
done

echo ""
echo "📊 统计信息:"
echo "  Swift文件数: $(find Keymap -name "*.swift" | wc -l | tr -d ' ')"
echo "  配置文件数: $(find . -name "*.plist" | wc -l | tr -d ' ')"
echo "  总文件数: $(find Keymap KeymapSandbox -type f | wc -l | tr -d ' ')"

echo ""
if $all_dirs_exist && $all_files_exist; then
    echo "✅ 项目结构完整，可以在Xcode中创建项目了！"
    echo ""
    echo "下一步:"
    echo "1. 打开Xcode"
    echo "2. 创建新的macOS App项目"
    echo "3. 导入Keymap目录下的所有文件"
    echo "4. 详细步骤请参考 README.md"
else
    echo "⚠️  项目结构不完整，请检查缺失的文件和目录"
fi
