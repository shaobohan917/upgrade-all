#!/bin/bash
# 安装升级脚本和定时任务
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.luka.upgrade-all.plist"

mkdir -p "$BIN_DIR" "$PLIST_DIR"

# 复制脚本
cp "$SCRIPT_DIR/upgrade-all.sh" "$BIN_DIR/upgrade-all.sh"
chmod +x "$BIN_DIR/upgrade-all.sh"

# 生成 plist，自动替换用户名路径
sed "s|/Users/luka|$HOME|g" "$SCRIPT_DIR/$PLIST_NAME" > "$PLIST_DIR/$PLIST_NAME"

# 先卸载旧任务（忽略错误）
launchctl unload "$PLIST_DIR/$PLIST_NAME" 2>/dev/null || true

# 加载定时任务
launchctl bootstrap gui/$(id -u) "$PLIST_DIR/$PLIST_NAME" 2>/dev/null \
    || launchctl load "$PLIST_DIR/$PLIST_NAME" 2>/dev/null || true

echo "安装完成！"
echo "  脚本: $BIN_DIR/upgrade-all.sh"
echo "  定时: $PLIST_DIR/$PLIST_NAME (每天 12:32)"
echo ""
echo "手动执行: bash $BIN_DIR/upgrade-all.sh"
echo "查看日志: tail -f ~/.local/log/upgrade-all.log"
