# Claude Code Skills 清单

我的 Claude Code skill/plugin 完整清单及说明。
机器可读注册表见 [skills-registry.yml](./skills-registry.yml)，一键安装见 [install-skills.sh](./install-skills.sh)。

---

## Plugins（通过 `claude plugin install` 安装）

| 名称 | Marketplace | 状态 | 描述 |
|------|-------------|------|------|
| `code-simplifier` | claude-plugins-official | ✅ 启用 | 代码简化器。完成代码修改后自动审查并精简，提升可读性和可维护性 |
| `explanatory-output-style` | claude-plugins-official | ✅ 启用 | 解释性输出风格。让 Claude 在写代码前后用 `★ Insight` 格式输出关键学习点 |
| `skill-creator` | claude-plugins-official | ✅ 启用 | Skill 创作工具。创建/优化 skill、运行 eval 测试性能 |
| `planning-with-files` | planning-with-files | ✅ 启用 | Manus 风格文件式任务规划。复杂任务创建 plan/findings/progress 文件追踪进度 |
| `ljg-xray-book` | ljg-xray-book | ✅ 启用 | X-Ray 书籍深度结构提取。基于 Epiplexity 原则提取书籍知识框架 |
| `claude-hud` | claude-hud | ⏸️ 禁用 | Claude HUD 状态显示。在终端中显示会话实时状态 |

**安装命令：**
```bash
bash ~/dotfiles/claude/install-skills.sh --only-plugins
```

---

## Skills（`~/.claude/skills/` 目录）

### Git 安装类

| 名称 | 来源 | 描述 |
|------|------|------|
| `agent-reach` | [Panniantong/Agent-Reach](https://github.com/Panniantong/Agent-Reach) | 全平台搜索工具（7500+ stars）。支持 Twitter、YouTube、小红书、B站、微信公众号等 14 个平台 |
| `anything-to-notebooklm` | [joeseesun/anything-to-notebooklm](https://github.com/joeseesun/anything-to-notebooklm) | 多源内容→NotebookLM。将公众号/网页/YouTube/PDF 自动上传并生成播客/PPT/思维导图 |
| `daily-standup` | GitHub | 每日站会报告生成器。读取 git 提交历史，生成「昨天/今天/阻塞」格式的站会汇报 |

### 手动安装类

| 名称 | 描述 |
|------|------|
| `think` | 10大心智模型思维教练。第一性原理、逆向思维、二阶思维等框架帮助深度思考和决策 |

### Symlink 类（由 openclaw/.agents 系统管理）

| 名称 | 链接目标 | 描述 |
|------|----------|------|
| `defuddle` | `~/.agents/skills/defuddle` | 网页内容提取。清理广告/导航/侧边栏，返回干净的文章内容 |
| `file-organizer` | `~/.agents/skills/file-organizer` | 文件整理工具。基于内容分析自动对文件进行重命名和归类 |
| `find-skills` | `~/.agents/skills/find-skills` | Skill 发现工具。帮助找到并安装能完成特定任务的 skill |
| `ljg-paper` | `~/.agents/skills/ljg-paper` | 论文阅读器（面向非学术用户）。提取核心思想，聚焦理解而非学术评价 |
| `markdown-proxy` | `~/.agents/skills/markdown-proxy` | URL→Markdown 代理。支持登录墙页面（微信公众号、飞书、Twitter 等） |
| `recall` | `~/.agents/skills/recall` | 历史会话搜索。BM25 全文检索所有历史 Claude 会话 |
| `skill-creator` | `~/.agents/skills/skill-creator` | Skill 创建工具（symlink 版） |

---

## Commands（`~/.claude/commands/` 下的 Slash 命令）

| 命令 | 描述 |
|------|------|
| `/code-review` | 代码审查。对变更进行质量、安全性、可维护性全面审查 |
| `/commit` | 智能提交。审查代码变动，生成规范 commit message 并提交 |
| `/create-docs` | 文档生成。为当前项目生成或重新生成技术文档 |
| `/full-context` | 全上下文收集。用子代理策略在回答前智能收集项目上下文 |
| `/gemini-consult` | Gemini 咨询。将问题转给 Gemini 模型获取多模型视角 |
| `/handoff` | 任务交接文档生成。结束工作时创建全面的交接文档 |
| `/implement-feature` | 功能实现向导。引导在代码库中实现新功能 |
| `/mcp-status` | MCP 状态检查。检查所有 MCP 服务器连接状态 |
| `/refactor` | 代码重构。对指定文件进行结构优化 |
| `/run-all-tests-and-fix` | 运行全部测试并自动修复失败 |
| `/think` | 心智模型分析（Command 版） |
| `/update-docs` | 完成代码工作后更新相关文档 |

---

## 新机器安装步骤

```bash
# 1. 克隆 dotfiles
git clone <your-dotfiles-repo> ~/dotfiles

# 2. 一键安装所有 skills 和 plugins
bash ~/dotfiles/claude/install-skills.sh

# 3. 检查 symlink skills（需要 openclaw/.agents 系统）
#    按照各 skill 的文档手动安装

# 4. Dry run 预览（不实际执行）
bash ~/dotfiles/claude/install-skills.sh --dry-run
```

---

## 添加新 Skill 的流程

1. 安装 skill
2. 在 `skills-registry.yml` 中添加条目
3. 更新本文件（`SKILLS.md`）的对应表格
4. 提交到 dotfiles repo

```bash
cd ~/dotfiles && git add claude/ && git commit -m "feat: add <skill-name> skill"
```
