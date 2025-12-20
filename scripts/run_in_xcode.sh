#!/bin/bash

# 在Xcode中运行应用并查看实时日志

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔨 开始编译并在Xcode中运行...${NC}"
echo ""

# 1. 清理并编译
echo "1️⃣  清理并编译项目..."
xcodebuild -project Keymap.xcodeproj -scheme Keymap clean build > /tmp/keymap_build.log 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 编译失败${NC}"
    echo -e "${YELLOW}查看详细日志: cat /tmp/keymap_build.log${NC}"
    tail -20 /tmp/keymap_build.log
    exit 1
fi

echo -e "${GREEN}✅ 编译成功${NC}"
echo ""

# 2. 查找编译后的app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Keymap-*/Build/Products/Debug -name "Keymap.app" -type d 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ 找不到编译后的 Keymap.app${NC}"
    exit 1
fi

# 3. 删除根目录旧版本
if [ -d "Keymap.app" ]; then
    echo "2️⃣  删除旧版本..."
    rm -rf Keymap.app
fi

# 4. 复制到根目录
echo "3️⃣  复制 Keymap.app 到项目根目录..."
cp -R "$APP_PATH" .
echo -e "${GREEN}✅ 复制成功${NC}"
echo ""

# 5. 在新终端窗口中显示日志
echo "4️⃣  准备查看实时日志..."
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}即将执行以下操作：${NC}"
echo -e "${YELLOW}1. 打开新终端窗口显示实时日志${NC}"
echo -e "${YELLOW}2. 启动 Keymap.app${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}关键日志标识：${NC}"
echo -e "  🚀 = 启动流程"
echo -e "  ✅ = 成功"
echo -e "  ⌘ = 双击Cmd检测"
echo -e "  📊 = 统计数据"
echo -e "  ❌ = 错误"
echo ""

# 6. 打开新终端显示日志
osascript << APPLESCRIPT
tell application "Terminal"
    activate
    do script "echo '🔍 Keymap 实时日志监控'; echo ''; echo '等待应用启动...'; echo ''; log stream --predicate 'process == \"Keymap\"' --level debug"
end tell
APPLESCRIPT

sleep 2

# 7. 启动应用
echo "5️⃣  启动 Keymap.app..."
open "$APP_PATH"

echo ""
echo -e "${GREEN}✅ 应用已启动！${NC}"
echo ""
echo -e "${YELLOW}提示：${NC}"
echo -e "  • 查看新打开的终端窗口以监控实时日志"
echo -e "  • 双击 Cmd 键测试功能"
echo -e "  • 关键日志应该包含: 🚀 ✅ ⌘ 📊"
echo ""
