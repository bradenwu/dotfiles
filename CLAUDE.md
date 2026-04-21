# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库性质

**个人 dotfiles 仓库**，不是应用代码。所有"代码"都是 shell 脚本。核心定位从"一键装整套"演进成了**按工具解耦的模块**——每个工具一个 `init_*.sh`，既能在本机一键全装（`./install.sh`），也能在公共服务器上通过 `curl | bash` 单装某个模块，**零个人环境泄露**。

## 核心架构

```
init/init_<tool>.sh   ──sources──►  lib/common.sh   ──installs──►  configs/<tool>...
    │
    └── 本机 (local mode):  symlink configs/X  →  ~/.X   （改仓库=改生效）
        远端 (remote mode): curl raw/configs/X →  ~/.X   （写实体文件，带时间戳备份）
```

三个要件：

1. **`lib/common.sh`**——所有 `init_*.sh` 共享的运行时库。只暴露几个函数：`print_info/ok/warn/err`、`detect_os`、`backup_if_exists`、`install_file`、`ensure_cmd`。**`install_file` 和 `backup_if_exists` 遵守 fail-closed 契约：原文件只在备份真实落盘后才被替换**（见下方"安全契约"）。

2. **`init/init_<tool>.sh`**——每个脚本 20–40 行。前 15 行是"双模式 bootstrap"：检测自身是在 clone 仓库内还是通过 `curl | bash` 运行，分别从本地 sibling 或 `$DOTFILES_RAW_BASE/lib/common.sh` 加载 common。之后几行调 `install_file` 把 `configs/<name>` 放到 `$HOME/.<name>`。

3. **`configs/`**——集中存放所有源配置（`tmux.conf`、`zshrc`、`bashrc`、`aliases`、`functions`、`functions.macos`、`functions.linux`、`path`、`exports`、`vimrc`、`gitconfig.template`、`ssh_config.template`）。这些文件没有前导 `.`——加 `.` 是落到 `$HOME` 时的事。

### Local vs. Remote 模式

| 维度 | local（clone 后运行） | remote（curl \| bash） |
|------|----------------------|------------------------|
| 检测 | `$SCRIPT_DIR/../lib/common.sh` 存在 | 不存在 → fallback 到 curl |
| 写 $HOME | symlink（便于改仓库实时生效） | 实体文件（没有仓库可链） |
| 触发 | `bash init/init_tmux.sh` 或 `./install.sh` | `curl -fsSL $RAW/init/init_tmux.sh \| bash` |
| 公共服务器 | ❌ 会暴露仓库路径 | ✅ 只落盘声明的文件 |

环境变量 `DOTFILES_RAW_BASE` 可覆盖 raw URL（测试时指向 `http://localhost:PORT`）。

### 安全契约（**不要违反**）

`lib/common.sh` 的 `backup_if_exists` 和 `install_file` 有严格的数据保护不变量：

- `backup_if_exists` 必须在**实际备份落盘成功**后才 `return 0`；任何一步失败（mkdir、cp、验证）都 `return 1`，**并且原文件保持不动**。
- `install_file` 在 local 模式覆盖目标前、remote 模式 `mv` 前，**必须** `if ! backup_if_exists ...; then return 1; fi`。
- remote 模式的顺序是 **curl→backup→atomic mv**，确保目标文件在新文件就绪前从不被触碰。
- local 模式有"已是正确 symlink 就 no-op"的早返回，保证幂等。

修改 `lib/common.sh` 时先跑 `bash tests/test_common.sh`（18 条断言，覆盖 happy path、不可写备份目录、幂等、失败清理等数据丢失风险）。

## 常用命令

```bash
# 本机全家桶（交互式，逐个模块问 y/N）
./install.sh

# 非交互式：用环境变量指定要装的模块（空格分隔）
INSTALL_MODULES="shell zsh tmux vim" ./install.sh

# 仅环境体检
./install.sh check

# 单独重装某个模块（local 模式）
bash init/init_tmux.sh
bash init/init_zsh.sh

# 公共服务器上只装 tmux（remote 模式，curl|bash）
curl -fsSL https://raw.githubusercontent.com/hnhbwzg/dotfiles/master/init/init_tmux.sh | bash

# 跑 common.sh 单元测试（修改 lib/common.sh 后必跑）
bash tests/test_common.sh

# 切换 Claude Code 后端模型（switch 脚本由 init_claude.sh 装到 ~/.claude-switch/）
source ~/.claude-switch/switch_cc_to_glm.sh
source ~/.claude-switch/switch_cc_to_kimi.sh
source ~/.claude-switch/switch_cc_to_default.sh
```

**没有构建系统 / linter**，验证靠三个手段：`bash tests/test_common.sh`、`./check_env.sh`、`./install.sh` 后肉眼检查 `ls -la ~/.tmux.conf ~/.zshrc ~/.aliases` 是否指向 `configs/`。

## 模块明细

| 模块 | 落盘文件 | 依赖 | 公共服务器安全? |
|------|---------|------|-----------------|
| `init_tmux.sh` | `~/.tmux.conf`、`~/.local/bin/tmux-session` | — | ✅ 首选分发目标 |
| `init_vim.sh` | `~/.vimrc` | — | ✅ |
| `init_shell.sh` | `~/.aliases` `~/.functions` `~/.functions.{macos,linux}` `~/.path` `~/.exports` | — | ❌ 含个人别名 |
| `init_zsh.sh` | `~/.zshrc` | 建议先装 `shell`；可选装 oh-my-zsh（`INSTALL_OH_MY_ZSH=yes\|no\|ask`） | ❌ |
| `init_bash.sh` | `~/.bashrc` | 建议先装 `shell` | ❌ |
| `init_git.sh` | `~/.gitconfig` | 询问 `GIT_NAME`/`GIT_EMAIL`（可环境变量跳过） | ⚠️ 个人身份 |
| `init_ssh.sh` | `~/.ssh/config`（实体文件非 symlink，含私有 host） | — | ❌ |
| `init_claude.sh` | `~/.claude-switch/switch_cc_*.sh` + 调 `claude/install-skills.sh` | **LOCAL-MODE-ONLY**（需要 `.env` 和 `claude/` 注册表） | ❌ 仅本机 |

顺序约束：`shell` 提供 `~/.functions` `~/.aliases` 等底座；`zsh`/`bash` 的 rc 文件 source 这些底座，所以 `INSTALL_MODULES` 习惯上把 `shell` 放前面。但单模块独立安装也能跑，只是对应 rc 可能会 warn "file not found"。

## `claude/` 子系统

独立于 dotfiles 主流程：

- `claude/skills-registry.yml`——plugins / skills / commands 的权威清单（`plugin` / `skill-git` / `skill-manual` / `command`）
- `claude/install-skills.sh`——解析 YAML 执行恢复，支持 `--dry-run` / `--only-plugins` / `--only-skills`
- `claude/SKILLS.md`——人读清单

新机器完整恢复 = `./install.sh` + `bash claude/install-skills.sh`（后者也被 `init_claude.sh` 自动调用）。

## 工作约定

- **不要** 把生成文件（`~/.gitconfig` 渲染结果、`~/.ssh/config`、`.env`）提交进仓库。新增敏感文件时同步改 `.gitignore`，并提供 `.template` 版本。
- **改加载顺序**（`.bashrc`/`.zshrc` 里的 for-loop）时两边保持一致；机器专属内容（如 conda init、私有 PATH）写到 `~/.local`，不要塞进仓库的 `configs/bashrc`。
- **新增一个模块**（例如 `init_foo.sh`）：① 在 `configs/` 放源文件；② 复制 `init/init_tmux.sh` 作模板改；③ 在 `install.sh:66` 的 `ALL_MODULES=(...)` 里加名字；④ 在 `install.sh:26` 的 `usage` 文本里更新"Valid names"。
- **改 `lib/common.sh`** 先跑 `tests/test_common.sh`。`install_file` 的实现很敏感——特别注意 fail-closed 契约，不要引入"fail-soft"的 `|| true`。
- 平台专属代码：跨平台放 `configs/functions`，macOS 专属放 `configs/functions.macos`，Linux 专属放 `configs/functions.linux`。`.aliases` 里混有 macOS 专属别名（`afk`、`flush`、`emptytrash`），Linux 上静默失效，有需要时再拆。
- 新增 Claude Code 后端切换（如 DeepSeek）时，复制 `switch_cc_to_glm.sh` 改就行，别引入新机制——`init_claude.sh` 的循环会自动把 `switch_cc_to_*.sh` 装到 `~/.claude-switch/`。

## 最近的重大重构

2026-04 把仓库从"`config_list` + `build_soft_link.sh` 全家桶"重构成了当前的"`init/*.sh` + `lib/common.sh` + `configs/`"模块化架构。已删除：`build_soft_link.sh`、`config_list`、`load_env.sh`。这些文件名如果出现在问题描述中，基本就是用旧知识在问——先指向本文件的"常用命令"章节。
