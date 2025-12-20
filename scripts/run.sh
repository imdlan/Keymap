#!/bin/bash

# 快速运行脚本

# 检查app是否存在
if [ ! -d "Keymap.app" ]; then
    echo "❌ Keymap.app 不存在，请先运行: ./build_and_copy.sh"
    exit 1
fi

echo "🚀 启动 Keymap..."
open Keymap.app

echo "✅ 已启动 Keymap.app"
echo "💡 查看日志: 打开 控制台.app 并过滤 'Keymap'"
