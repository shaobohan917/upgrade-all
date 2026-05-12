# upgrade-all

macOS 一键升级工具，自动升级系统中所有包管理器及全局包，并通过 launchd 定时任务实现每日自动更新。

## 功能

- **Homebrew** — 更新源、升级 formula 和 cask、自动清理
- **npm** — 逐个升级全局包（避免 `npm update -g` 的平台依赖问题）
- **pnpm** — 升级至最新版本
- **Rust / Cargo** — 通过 `rustup` 更新工具链
- **Go** — 升级 Go 版本
- **Mac App Store** — 升级已安装的应用（交互式终端下）

## 安装

```bash
git clone git@github.com:shaobohan917/upgrade-all.git
cd upgrade-all
bash install.sh
```

安装后会将脚本部署到 `~/.local/bin/`，并配置 launchd 定时任务（默认每天 12:32）。

## 使用方法

### 手动执行

```bash
# 立即执行升级
bash ~/.local/bin/upgrade-all.sh

# 预览模式（只打印命令，不实际执行）
bash ~/.local/bin/upgrade-all.sh --dry-run
```

### 查看日志

```bash
tail -f ~/.local/log/upgrade-all.log
```

### 修改执行时间

编辑 `~/Library/LaunchAgents/com.luka.upgrade-all.plist`，修改 `StartCalendarInterval` 中的 `Hour` 和 `Minute` 值，然后重新加载：

```bash
launchctl unload ~/Library/LaunchAgents/com.luka.upgrade-all.plist
launchctl load ~/Library/LaunchAgents/com.luka.upgrade-all.plist
```

### 卸载

```bash
launchctl unload ~/Library/LaunchAgents/com.luka.upgrade-all.plist
rm ~/Library/LaunchAgents/com.luka.upgrade-all.plist
rm ~/.local/bin/upgrade-all.sh
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `upgrade-all.sh` | 主升级脚本 |
| `install.sh` | 安装脚本（部署 + 配置定时任务） |
| `com.luka.upgrade-all.plist` | launchd 定时任务配置 |

## 依赖

确保系统中已安装以下工具：

- [Homebrew](https://brew.sh/)
- Node.js (npm / pnpm)
- Rust（可选，通过 rustup 安装）
- Go（可选）
- [mas](https://github.com/mas-cli/mas)（Mac App Store CLI，可选）
