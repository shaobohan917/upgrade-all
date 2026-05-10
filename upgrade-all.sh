#!/bin/bash
# 一键升级所有包管理器
# 用法: bash ~/.local/bin/upgrade-all.sh [--dry-run]

set -euo pipefail

# LaunchAgent 环境缺少 PATH，手动补充
export PATH="/opt/homebrew/bin:/Users/luka/Library/pnpm/bin:/Users/luka/.cargo/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
LOG="$HOME/.local/log/upgrade-all.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

notify() {
    local title="$1"
    local content="$2"
    curl -s -X POST "https://www.pushplus.plus/send" \
        -H "Content-Type: application/json" \
        -d "{\"token\":\"7a58d68caa254b17a6fba0acd412b391\",\"title\":\"$title\",\"content\":\"$content\",\"template\":\"txt\"}" > /dev/null || true
}

DRY_RUN="${1:-}"
RESULT=""

run() {
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        log "[DRY-RUN] $*"
    else
        log ">>> $*"
        eval "$@" 2>&1 | tee -a "$LOG" || log "[WARN] $1 退出码: $?"
    fi
}

# 收集待升级信息
PENDING=""

# Homebrew 待升级
brew update 2>/dev/null || true
BREW_OUTDATED=$(brew outdated 2>/dev/null | head -10 || true)
if [[ -n "$BREW_OUTDATED" ]]; then
    PENDING+="Homebrew:\n$BREW_OUTDATED\n\n"
fi

# npm 待升级
NPM_OUTDATED=$(npm outdated -g 2>/dev/null | tail -n +2 | awk '{print $1 " (" $2 " -> " $3 ")"}' | head -10 || true)
if [[ -n "$NPM_OUTDATED" ]]; then
    PENDING+="npm:\n$NPM_OUTDATED\n\n"
fi

# 发送开始通知
if [[ -n "$PENDING" ]]; then
    notify "升级开始" "需要升级的包:
$PENDING"
else
    notify "升级开始" "没有需要升级的包"
fi

log "========== 升级开始 =========="

# Homebrew
log "--- Homebrew ---"
brew update 2>&1 | tee -a "$LOG" || true
BREW_UPGRADE=$(brew upgrade 2>&1 | tee -a "$LOG" || true)
if [[ -n "$BREW_UPGRADE" ]] && echo "$BREW_UPGRADE" | grep -q "Upgraded\|Installing\|Pouring"; then
    RESULT+="Homebrew 已升级\n"
fi
brew upgrade --cask 2>&1 | tee -a "$LOG" || true
brew cleanup --prune=30 2>&1 | tee -a "$LOG" || true

# npm 全局包 (逐个升级，避免 npm update -g 的平台依赖问题)
log "--- npm ---"
NPM_RESULT=""
SKIP_PKGS="happy-coder"
while read -r pkg; do
    if echo "$SKIP_PKGS" | grep -qw "$pkg"; then
        log "[SKIP] $pkg (workspace 协议不支持全局安装)"
        continue
    fi
    NPM_OUT=$(npm install -g "${pkg}@latest" 2>&1 | tee -a "$LOG" || true)
    if echo "$NPM_OUT" | grep -q "added\|changed\|removed"; then
        NPM_RESULT+="$pkg "
    fi
done < <({ npm outdated -g 2>/dev/null || true; } | tail -n +2 | awk '{print $1}')
if [[ -n "$NPM_RESULT" ]]; then
    RESULT+="npm 已升级: $NPM_RESULT\n"
fi

# pnpm
log "--- pnpm ---"
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"
PNPM_OUT=$(pnpm add -g pnpm@latest 2>&1 | tee -a "$LOG" || true)
if echo "$PNPM_OUT" | grep -q "Done\|updated"; then
    RESULT+="pnpm 已升级\n"
fi

# Rust / Cargo
log "--- Cargo ---"
if command -v rustup &>/dev/null; then
    CARGO_OUT=$(rustup update 2>&1 | tee -a "$LOG" || true)
    if echo "$CARGO_OUT" | grep -q "updated\|installed"; then
        RESULT+="Rust 已升级\n"
    fi
fi

# Go
log "--- Go ---"
if command -v go &>/dev/null; then
    go install golang.org/dl/go1.26.2@latest 2>&1 | tee -a "$LOG" || true
fi

# macOS App Store 应用 (需要 sudo，自动脚本中跳过)
log "--- Mac App Store ---"
if [[ -t 0 ]]; then
    run "mas upgrade"
else
    log "[SKIP] mas upgrade 需要交互式终端输入密码，自动执行时跳过"
fi

log "========== 升级完成 =========="

# 发送完成通知
if [[ -n "$RESULT" ]]; then
    notify "升级完成" "升级结果:
$RESULT"
else
    notify "升级完成" "没有需要升级的包"
fi
