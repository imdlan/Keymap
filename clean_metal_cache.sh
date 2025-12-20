#!/bin/bash

# 清理 Metal 着色器缓存脚本
# 用于解决 Metal flock/fopen 错误

echo "🧹 开始清理 Metal 着色器缓存..."

# 1. 清理应用的 Metal 缓存
METAL_CACHE_DIR="/var/folders/${USER}/C/com.yourcompany.Keymap/com.apple.metal"
if [ -d "$METAL_CACHE_DIR" ]; then
    echo "📁 清理应用 Metal 缓存: $METAL_CACHE_DIR"
    rm -rf "$METAL_CACHE_DIR"
    echo "✅ 应用 Metal 缓存已清理"
else
    echo "ℹ️  未找到应用 Metal 缓存目录"
fi

# 2. 清理系统临时目录中的 Metal 缓存
TEMP_METAL_CACHE=$(find /var/folders -name "com.apple.metal" -type d 2>/dev/null | grep "com.yourcompany.Keymap")
if [ -n "$TEMP_METAL_CACHE" ]; then
    echo "📁 清理临时 Metal 缓存..."
    echo "$TEMP_METAL_CACHE" | while read -r dir; do
        echo "  - $dir"
        rm -rf "$dir"
    done
    echo "✅ 临时 Metal 缓存已清理"
else
    echo "ℹ️  未找到临时 Metal 缓存"
fi

# 3. 清理 DerivedData 中的 Metal 缓存
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA/Keymap-"* ]; then
    echo "📁 清理 DerivedData Metal 缓存..."
    rm -rf "$DERIVED_DATA"/Keymap-*/Build/Intermediates.noindex/*/Metal
    echo "✅ DerivedData Metal 缓存已清理"
fi

echo ""
echo "✨ 清理完成！"
echo "💡 提示: 重启应用后，Metal 缓存将自动重建"
echo "💡 如果问题持续，可以尝试重启 Mac"
