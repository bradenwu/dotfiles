# WuZhigang's Dotfiles

一个可移植的 dotfiles 配置集合，支持快速在新环境中初始化开发环境。

## 🚀 功能特点

- ✅ **跨平台支持** - 支持 Linux 和 macOS 系统
- ✅ **自动化安装** - 一键脚本安装所有配置
- ✅ **环境检测** - 自动检测系统环境和依赖
- ✅ **备份机制** - 自动备份现有配置文件
- ✅ **平台适配** - 自动加载平台特定配置
- ✅ **可配置性** - 支持注释和可选配置

## 📋 包含的配置

### Shell 配置
- **Zsh** - 主 shell 配置，包含 oh-my-zsh 集成
- **Bash** - 兼容 bash 配置，包含服务器环境支持
- **Aliases** - 常用命令别名
- **Functions** - 跨平台和平台特定函数
- **Local** - 个人本地配置文件（不提交到仓库）

### 开发工具
- **Git** - 包含丰富的别名和配置
- **Tmux** - 终端复用器配置
- **Vim** - 编辑器基础配置

### 脚本工具
- **tmux-session** - tmux 会话管理工具

## 🛠️ 安装方法

### 快速安装

```bash
# 克隆仓库
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# 运行安装脚本
./install.sh
```

### 手动安装

1. **环境检查**
   ```bash
   ./check_env.sh
   ```

2. **创建符号链接**
   ```bash
   ./build_soft_link.sh
   ```

3. **配置 Git 用户信息**
   ```bash
   # 编辑 .gitconfig 文件，修改用户信息
   ```

## 📁 文件结构

```
~/dotfiles/
├── .gitconfig                 # Git 配置（模板）
├── .gitconfig.template        # Git 配置模板
├── .aliases                   # 命令别名
├── .functions                 # 跨平台函数
├── .functions.macos           # macOS 特定函数
├── .functions.linux           # Linux 特定函数
├── .zshrc                     # Zsh 配置
├── .bashrc                    # Bash 配置
├── .local                     # 本地个人配置（不提交）
├── .local.template            # 本地配置模板
├── .tmux.conf                 # Tmux 配置
├── .path                      # 路径配置
├── .exports                   # 环境变量
├── .gitignore                 # Git 忽略文件
├── .env.example               # 环境变量模板
├── load_env.sh                # 环境变量加载脚本
├── switch_cc_to_glm.sh        # GLM 模型切换脚本
├── config_list                # 配置文件列表
├── install.sh                 # 主安装脚本
├── check_env.sh               # 环境检查脚本
├── build_soft_link.sh         # 符号链接创建脚本
└── bin/
    └── tmux-session           # tmux 会话管理工具
```

## 🔧 配置说明

### config_list 文件

`config_list` 文件控制哪些配置文件会被创建符号链接：

```bash
# 注释行会被忽略
#.path          # 禁用的配置
#.gitconfig     # Git 配置（需要手动设置）
.aliases       # 启用的配置
.functions     # 跨平台函数
.tmux.conf     # Tmux 配置
```

### 平台特定配置

系统会根据操作系统自动加载对应的配置文件：

- **macOS**: `.functions.macos`
- **Linux**: `.functions.linux`

### 环境变量配置

项目使用 `.env` 文件管理敏感信息，确保安全性和可移植性：

#### 创建环境变量文件

```bash
# 复制环境变量模板
cp ~/dotfiles/.env.example ~/dotfiles/.env

# 编辑环境变量文件
nano ~/dotfiles/.env

# 重新加载配置（会自动加载）
source ~/.bashrc
```

#### 环境变量说明

- **用途**：存放 API 密钥、代理设置、模型配置等敏感信息
- **安全性**：`.env` 文件已添加到 `.gitignore`，不会提交到版本控制
- **自动加载**：`.bashrc` 会自动加载 `~/dotfiles/.env` 文件
- **优先级**：环境变量优先于脚本中的硬编码值

#### 支持的环境变量

```bash
# 代理设置
HTTP_PROXY=http://127.0.0.1:18080
HTTPS_PROXY=http://127.0.0.1:18080

# API 密钥
API_KEY=your-secret-key
GITHUB_TOKEN=your-github-token
ANTHROPIC_AUTH_TOKEN=your-anthropic-token

# Claude Code 配置
ANTHROPIC_BASE_URL=https://api.anthropic.com
ANTHROPIC_DEFAULT_OPUS_MODEL=claude-3-opus-20240229
ANTHROPIC_DEFAULT_SONNET_MODEL=claude-3-sonnet-20240229
ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-3-haiku-20240307

# GLM 配置示例
ANTHROPIC_BASE_URL=http://open.bigmodel.cn/api/anthropic
ANTHROPIC_DEFAULT_OPUS_MODEL=GLM-4.6
ANTHROPIC_DEFAULT_SONNET_MODEL=GLM-4.6
ANTHROPIC_DEFAULT_HAIKU_MODEL=GLM-4.5-Air
```

### Claude Code 模型切换

项目提供了便捷的模型切换脚本，支持在 Claude 官方 API 和 GLM 模型之间切换：

#### GLM 模型切换

```bash
# 切换到 GLM 模型
source ~/dotfiles/switch_cc_to_glm.sh
```

**脚本功能：**
- 自动加载 `.env` 文件中的配置
- 设置 GLM API 端点：`http://open.bigmodel.cn/api/anthropic`
- 配置推荐的 GLM 模型：
  - Opus: `GLM-4.6`
  - Sonnet: `GLM-4.6`
  - Haiku: `GLM-4.5-Air`
- 清除代理设置，确保直连

**配置优先级：**
1. `.env` 文件中的设置（最高优先级）
2. 脚本中的默认配置
3. 系统环境变量

**使用示例：**

```bash
# 方法 1：直接执行脚本
source ~/dotfiles/switch_cc_to_glm.sh

# 方法 2：通过 load_env.sh 加载环境变量后执行
source ~/dotfiles/load_env.sh
source ~/dotfiles/switch_cc_to_glm.sh
```

**自定义配置：**

如需自定义模型配置，可在 `.env` 文件中设置：

```bash
# .env 文件
ANTHROPIC_AUTH_TOKEN=your-glm-token
ANTHROPIC_DEFAULT_OPUS_MODEL=GLM-4.6
ANTHROPIC_DEFAULT_SONNET_MODEL=GLM-4.6
ANTHROPIC_DEFAULT_HAIKU_MODEL=GLM-4.5-Air
# 如果需要自定义 API 端点
# ANTHROPIC_BASE_URL=http://open.bigmodel.cn/api/anthropic
```

### 本地配置

`.local` 文件用于存放个人本地配置，**不应该提交到版本控制**：

- **用途**：存放个人偏好、机器特定配置、开发环境设置
- **加载顺序**：最后加载，可以覆盖任何仓库中的设置
- **创建方法**：复制 `.local.template` 为 `~/.local` 并自定义
- **示例配置**：
  - NVM (Node Version Manager) 配置
  - 机器特定的 PATH 设置
  - 个人项目别名
  - 开发环境变量

```bash
# 复制模板文件到 home 目录
cp ~/dotfiles/.local.template ~/.local

# 编辑本地配置
nano ~/.local

# 重新加载配置
source ~/.bashrc
```

## 🚨 使用前准备

### 系统要求

**核心工具：**
- `git` - 版本控制
- `curl` - 网络下载工具
- `vim` - 文本编辑器

**可选工具：**
- `zsh` - 增强的 shell（推荐，非必需）
- `tmux` - 终端复用器
- `oh-my-zsh` - Zsh 配置框架
- `python` 或 `python3` - 脚本支持
- `node` - Node.js 开发
- `docker` - 容器化支持

### 安装依赖

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install git zsh tmux curl wget
```

#### CentOS/RHEL
```bash
sudo yum update
sudo yum install git zsh tmux curl wget
```

#### macOS
```bash
brew install git zsh tmux curl wget
```

## 📖 详细使用指南

### 1. 环境检查

```bash
# 检查系统环境和依赖
./check_env.sh
```

此脚本会检查：
- 操作系统类型
- Shell 环境
- 必需工具是否安装
- 可选工具状态
- 包管理器识别

### 2. 安装脚本选项

```bash
# 主安装
./install.sh

# 仅检查环境
./install.sh check

# 卸载配置
./install.sh uninstall

# 显示帮助
./install.sh help
```

### 3. 符号链接管理

```bash
# 创建符号链接
./build_soft_link.sh create

# 列出现有链接
./build_soft_link.sh list

# 清理失效链接
./build_soft_link.sh clean
```

### 4. 备份机制

安装过程中，现有的配置文件会被自动备份到 `~/.dotfiles_backup/` 目录：

```bash
# 查看备份文件
ls -la ~/.dotfiles_backup/

# 备份文件格式：原文件名_时间戳
# 例如：.zshrc_20240101_120000
```

## 🎯 自定义配置

### 添加新配置文件

1. **创建配置文件**
   ```bash
   # 例如添加新的配置文件
   touch .myconfig
   ```

2. **添加到 config_list**
   ```bash
   echo ".myconfig" >> config_list
   ```

3. **重新创建链接**
   ```bash
   ./build_soft_link.sh create
   ```

### 添加平台特定函数

1. **创建平台特定文件**
   ```bash
   # macOS 特定函数
   touch .functions.macos

   # Linux 特定函数
   touch .functions.linux
   ```

2. **函数会自动加载**
   系统会根据操作系统自动加载对应的函数文件。

### 修改 Git 配置

1. **编辑模板文件**
   ```bash
   nano .gitconfig.template
   ```

2. **重新生成配置**
   ```bash
   # 运行安装脚本并选择配置 Git
   ./install.sh
   ```

## 🔍 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 确保脚本有执行权限
   chmod +x install.sh check_env.sh build_soft_link.sh
   ```

2. **符号链接创建失败**
   ```bash
   # 检查源文件是否存在
   ls -la ~/dotfiles/

   # 检查目标目录权限
   ls -la ~/
   ```

3. **环境检查失败**
   ```bash
   # 核心工具缺失时才会失败，可选工具不影响安装
   # Ubuntu/Debian
   sudo apt install [缺失的包]

   # CentOS/RHEL
   sudo yum install [缺失的包]
   ```

4. **Zsh 配置不生效**
   ```bash
   # 重新加载配置
   source ~/.zshrc

   # 或重启 shell
   exec zsh
   ```

5. **本地配置 (.local) 不生效**
   ```bash
   # 检查文件是否存在
   ls -la ~/.local

   # 手动创建本地配置文件
   cp ~/dotfiles/.local.template ~/.local
   nano ~/.local

   # 重新加载 bash 配置
   source ~/.bashrc

   # 检查文件加载权限
   chmod 644 ~/.local
   ```

6. **环境变量 (.env) 不生效**
   ```bash
   # 检查文件是否存在
   ls -la ~/dotfiles/.env

   # 创建环境变量文件
   cp ~/dotfiles/.env.example ~/dotfiles/.env
   nano ~/dotfiles/.env

   # 重新加载配置
   source ~/.bashrc

   # 验证环境变量是否加载
   echo $ANTHROPIC_AUTH_TOKEN
   ```

7. **GLM 模型切换不生效**
   ```bash
   # 检查脚本是否存在且有执行权限
   ls -la ~/dotfiles/switch_cc_to_glm.sh
   chmod +x ~/dotfiles/switch_cc_to_glm.sh

   # 检查环境变量是否正确设置
   source ~/dotfiles/switch_cc_to_glm.sh
   echo $ANTHROPIC_BASE_URL
   echo $ANTHROPIC_DEFAULT_OPUS_MODEL

   # 验证认证令牌是否设置
   echo $ANTHROPIC_AUTH_TOKEN

   # 如果使用自定义配置，检查 .env 文件
   cat ~/dotfiles/.env | grep ANTHROPIC
   ```

### 调试模式

```bash
# 启用调试输出
bash -x ./install.sh
```

## 🔐 安全性说明

### 敏感信息管理

本项目采用分层配置管理敏感信息：

1. **`.env` 文件** - 存放 API 密钥、令牌等敏感信息
   - 已添加到 `.gitignore`，不会提交到版本控制
   - 需要手动创建：`cp .env.example .env`
   - 自动被 shell 配置加载

2. **`.local` 文件** - 存放个人本地配置
   - 已添加到 `.gitignore`，不会提交到版本控制
   - 存放在用户 home 目录：`~/.local`
   - 最后加载，可覆盖其他配置

3. **配置模板** - 提供配置示例
   - `.env.example` - 环境变量模板
   - `.local.template` - 本地配置模板
   - 安全提交到版本控制

## 🔄 更新和维护

### 更新 dotfiles

```bash
cd ~/dotfiles
git pull
./build_soft_link.sh create
```

### 贡献指南

1. Fork 项目
2. 创建特性分支：`git checkout -b feature/new-feature`
3. 提交更改：`git commit -am 'Add new feature'`
4. 推送分支：`git push origin feature/new-feature`
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献者

- WuZhigang - 创作者

## 📞 支持

如果遇到问题或有建议，请：

1. 查看故障排除部分
2. 检查 [Issues](https://github.com/your-username/dotfiles/issues)
3. 创建新的 Issue

---

**享受你的新环境！** 🎉