#!/bin/bash
# 一键升级所有包管理器
# 用法: bash ~/.local/bin/upgrade-all.sh [--dry-run]

set -euo pipefail
LOG="$HOME/.local/log/upgrade-all.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

DRY_RUN="${1:-}"

run() {
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        log "[DRY-RUN] $*"
    else
        log ">>> $*"
        eval "$@" 2>&1 | tee -a "$LOG" || log "[WARN] $1 退出码: $?"
    fi
}

log "========== 升级开始 =========="

# Homebrew
log "--- Homebrew ---"
run "brew update"
run "brew upgrade"
run "brew upgrade --cask"
run "brew cleanup --prune=30"

# npm 全局包 (逐个升级，避免 npm update -g 的平台依赖问题)
log "--- npm ---"
{ npm outdated -g 2>/dev/null || true; } | tail -n +2 | awk '{print $1}' | while read -r pkg; do
    run "npm install -g ${pkg}@latest" || true
done

# pnpm
log "--- pnpm ---"
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"
run "pnpm add -g pnpm@latest"

# Rust / Cargo
log "--- Cargo ---"
if command -v rustup &>/dev/null; then
    run "rustup update"
fi

# Go
log "--- Go ---"
if command -v go &>/dev/null; then
    run "go install golang.org/dl/go1.26.2@latest"  # 按需调整
fi

# macOS App Store 应用 (需要 sudo，自动脚本中跳过)
log "--- Mac App Store ---"
if [[ -t 0 ]]; then
    run "mas upgrade"
else
    log "[SKIP] mas upgrade 需要交互式终端输入密码，自动执行时跳过"
fi

log "========== 升级完成 =========="
