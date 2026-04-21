# WuZhigang's Dotfiles

模块化的 dotfiles 仓库。核心卖点：**按工具解耦、可独立安装**——在公共服务器上只装 tmux 或 vim，不泄露个人 alias、token、git 身份、ssh host。

## ✨ 核心特性

- **本机全家桶**：clone 后 `./install.sh` 交互式全装，配置以 symlink 形式落在 `$HOME`，改仓库即改生效。
- **公共服务器单模块**：一行 `curl | bash` 装单个工具，实体文件落盘并带时间戳备份，**零个人环境泄露**。
- **Fail-closed 备份**：目标文件只在备份真实成功后才被替换，任何中途失败都保留原文件（`lib/common.sh`，18 条单元测试覆盖）。
- **可选非交互模式**：CI / 脚本化场景用 `INSTALL_MODULES` / `GIT_NAME` / `GIT_EMAIL` 环境变量跳过提问。

## 🛠️ 安装

### 场景 A：自己的机器（全家桶）

```bash
git clone https://github.com/bradenwu/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh                              # 交互式，逐模块问 y/N
# 或非交互：
INSTALL_MODULES="shell zsh bash tmux vim git ssh claude" ./install.sh
```

全家桶会把 `configs/*` 以 symlink 形式链到 `$HOME`，之后直接改仓库就相当于改生效的配置。

### 场景 B：公共服务器（只装一个工具）

想在跳板机/共享 GPU 机器上只用仓库里的 tmux 配置，不想留下任何个人痕迹：

```bash
curl -fsSL https://raw.githubusercontent.com/bradenwu/dotfiles/master/init/init_tmux.sh | bash
```

该命令会：① 下载 `lib/common.sh` 到临时目录并 source；② 下载 `configs/tmux.conf` 到 `~/.tmux.conf`（实体文件，非 symlink）；③ 下载 `bin/tmux-session` 到 `~/.local/bin/`；④ 如果目标已存在，先备份到 `~/.dotfiles_backup/<name>_<timestamp>`。

**不会**落下：`.zshrc`、`.bashrc`、`.aliases`、`.functions`、`.gitconfig`、`.env`、`switch_cc_*.sh`、`~/.ssh/config`。

其它单模块同理：

```bash
# 仅 vim
curl -fsSL https://raw.githubusercontent.com/bradenwu/dotfiles/master/init/init_vim.sh | bash

# 仅 git（可用环境变量跳过交互）
curl -fsSL https://raw.githubusercontent.com/bradenwu/dotfiles/master/init/init_git.sh | \
  GIT_NAME="Your Name" GIT_EMAIL="you@example.com" bash
```

公共服务器**不要**跑 `init_claude.sh`、`init_shell.sh`、`init_ssh.sh`——它们会落下个人信息。

## 📁 文件结构

```
~/dotfiles/
├── install.sh                  # 本机总入口，顺序调用 init/*.sh
├── check_env.sh                # 环境体检（缺核心工具警告）
├── lib/common.sh               # 共享库：print_*、install_file、backup_if_exists
├── init/
│   ├── init_tmux.sh            # 单工具模块（20-40 行，带 curl-bash 自举）
│   ├── init_vim.sh
│   ├── init_shell.sh           # aliases/functions/path/exports
│   ├── init_zsh.sh             # .zshrc + 可选 oh-my-zsh
│   ├── init_bash.sh            # .bashrc
│   ├── init_git.sh             # 渲染 gitconfig 模板（交互或 env vars）
│   ├── init_ssh.sh             # ~/.ssh/config（实体文件）
│   └── init_claude.sh          # 仅本机：switch_cc_*.sh + claude/install-skills.sh
├── configs/                    # 源配置集中存放
│   ├── tmux.conf   vimrc       aliases      functions
│   ├── functions.macos  functions.linux     path         exports
│   ├── zshrc       bashrc      gitconfig.template        ssh_config.template
├── tests/test_common.sh        # lib/common.sh 的 18 条单元断言
├── bin/tmux-session            # tmux 会话工具
├── switch_cc_to_{default,glm,kimi}.sh   # Claude Code 后端切换
├── claude/                     # skills & plugins 注册表（YAML + 恢复脚本）
└── .env.example                # token/代理 模板，需自行复制为 .env
```

## ⚙️ 常用命令

```bash
# 全家桶
./install.sh
./install.sh check              # 只体检
./install.sh help

# 单模块重装（本机）
bash init/init_tmux.sh

# 非交互（CI/脚本）
INSTALL_MODULES="shell zsh tmux" ./install.sh
GIT_NAME="Braden" GIT_EMAIL="me@example.com" bash init/init_git.sh

# 测试 common.sh 的安全契约
bash tests/test_common.sh

# Claude Code 模型切换（init_claude.sh 已把脚本装到 ~/.claude-switch/）
source ~/.claude-switch/switch_cc_to_glm.sh
source ~/.claude-switch/switch_cc_to_kimi.sh
source ~/.claude-switch/switch_cc_to_default.sh
```

## 🔐 敏感信息管理

| 层 | 提交? | 位置 | 用途 |
|----|-------|------|------|
| `.env.example`、`configs/gitconfig.template`、`configs/ssh_config.template` | ✅ | 仓库 | 模板 |
| `.env` | ❌ | 仓库根（已 gitignore） | API token、代理等，`.bashrc` 自动 `set -a; source` |
| `~/.local` | ❌ | `$HOME` | 机器级覆盖，最后加载可覆盖前面任何设置 |
| `~/.gitconfig`、`~/.ssh/config` | ❌ | `$HOME` | 生成/渲染的个人文件 |

新增敏感配置时必须同时：① 文件加入 `.gitignore`；② 提交一个 `.template` 版本；③ 在相应的 `init_*.sh` 里加渲染逻辑。

## 🧪 验证

本机装完肉眼自检：

```bash
ls -la ~/.tmux.conf ~/.zshrc ~/.aliases    # 本机应是 symlink → ~/dotfiles/configs/
./check_env.sh                              # 核心工具都在
```

远程模式"零泄露"自动化验证（在本机模拟跳板机）：

```bash
# 起本地 HTTP server 扮演 raw.githubusercontent.com
python3 -m http.server 8765 &

# 用干净的 $HOME 跑 curl|bash
TEST_HOME="$(mktemp -d)"
HOME="$TEST_HOME" DOTFILES_RAW_BASE="http://localhost:8765" \
  bash -c 'curl -fsSL http://localhost:8765/init/init_tmux.sh | bash'

# 断言：只落 tmux，别的都不应出现
ls "$TEST_HOME"                     # 应只看到 .tmux.conf、.local/
[ ! -e "$TEST_HOME/.zshrc" ] && echo "✓ no zsh leakage"
```

## 🔄 备份与回滚

任何覆盖目标文件的操作都会先备份：

```bash
ls -la ~/.dotfiles_backup/          # 格式：<name>_<YYYYMMDD_HHMMSS>
```

备份失败时安装会中止，原文件保持不动（fail-closed 契约）。

## 📋 系统要求

核心：`git`、`curl`、`bash`。可选：`zsh`、`tmux`、`vim`、`python3`（仅用于自建本地测试 HTTP server）。

```bash
# Ubuntu/Debian
sudo apt install git zsh tmux curl

# macOS
brew install git zsh tmux
```

## 📄 许可证

MIT。详见 [LICENSE](LICENSE)。
