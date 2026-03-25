#!/usr/bin/env bash
# Claude Code Skills 一键安装脚本
# 基于 skills-registry.yml 恢复所有 skill/plugin/command
# 用法: bash install-skills.sh [--dry-run] [--only-plugins] [--only-skills]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="$SCRIPT_DIR/skills-registry.yml"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

# ── 颜色输出 ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()     { echo -e "${RED}[ERR]${NC}   $*"; }
header()  { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }
dry()     { echo -e "${YELLOW}[DRY]${NC}   $*"; }

# ── 参数解析 ──────────────────────────────────────────────
DRY_RUN=false
ONLY_PLUGINS=false
ONLY_SKILLS=false

for arg in "$@"; do
  case $arg in
    --dry-run)       DRY_RUN=true ;;
    --only-plugins)  ONLY_PLUGINS=true ;;
    --only-skills)   ONLY_SKILLS=true ;;
    --help|-h)
      echo "用法: $0 [选项]"
      echo "  --dry-run       仅显示将执行的操作，不实际执行"
      echo "  --only-plugins  只安装 claude plugins"
      echo "  --only-skills   只安装 ~/.claude/skills/ 下的 git skills"
      exit 0 ;;
  esac
done

# ── 前置检查 ──────────────────────────────────────────────
check_deps() {
  local missing=()
  command -v claude &>/dev/null || missing+=("claude")
  command -v git    &>/dev/null || missing+=("git")
  command -v python3 &>/dev/null || missing+=("python3")
  if [[ ${#missing[@]} -gt 0 ]]; then
    err "缺少依赖: ${missing[*]}"
    err "请先安装缺少的工具后重试"
    exit 1
  fi
}

# ── Python 辅助：解析 YAML registry ──────────────────────
# 用 Python 读 YAML，输出 TSV 格式供 bash 消费
parse_plugins() {
  python3 - "$REGISTRY" <<'PYEOF'
import sys, re

registry = open(sys.argv[1]).read()

# 找到 plugins: 区块
plugin_block = re.search(r'^plugins:\n(.*?)(?=^\w|\Z)', registry, re.MULTILINE | re.DOTALL)
if not plugin_block:
    sys.exit(0)

text = plugin_block.group(1)
entries = re.split(r'\n  - name:', text)

for entry in entries[1:]:
    lines = entry.strip().split('\n')
    name = lines[0].strip()

    marketplace = ''
    marketplace_source = ''
    enabled = 'true'

    for line in lines[1:]:
        line = line.strip()
        if line.startswith('marketplace:') and 'source' not in line:
            marketplace = line.split(':', 1)[1].strip()
        elif line.startswith('marketplace_source:'):
            marketplace_source = line.split(':', 1)[1].strip().strip('#').split('#')[0].strip()
        elif line.startswith('enabled:'):
            enabled = line.split(':', 1)[1].strip()

    # 跳过注释里的 source 信息
    if marketplace_source and '#' in marketplace_source:
        marketplace_source = marketplace_source.split('#')[0].strip()

    print(f"{name}\t{marketplace}\t{marketplace_source}\t{enabled}")
PYEOF
}

parse_git_skills() {
  python3 - "$REGISTRY" <<'PYEOF'
import sys, re

registry = open(sys.argv[1]).read()

skill_block = re.search(r'^skills:\n(.*?)(?=^commands:|\Z)', registry, re.MULTILINE | re.DOTALL)
if not skill_block:
    sys.exit(0)

text = skill_block.group(1)
entries = re.split(r'\n  - name:', text)

for entry in entries[1:]:
    lines = entry.strip().split('\n')
    name = lines[0].strip()

    skill_type = ''
    source = ''

    for line in lines[1:]:
        line = line.strip()
        if line.startswith('type:'):
            skill_type = line.split(':', 1)[1].strip()
        elif line.startswith('source:'):
            source = line.split(':', 1)[1].strip()

    if skill_type == 'skill-git':
        print(f"{name}\t{source}")
PYEOF
}

# ── Plugins 安装 ──────────────────────────────────────────
install_plugins() {
  header "安装 Claude Plugins"

  local installed_plugins
  installed_plugins=$(claude plugin list 2>/dev/null || echo "")

  while IFS=$'\t' read -r name marketplace marketplace_source enabled; do
    [[ -z "$name" ]] && continue

    local display="${name}@${marketplace}"

    if [[ "$enabled" == "false" ]]; then
      info "跳过 $display（已标记为禁用）"
      continue
    fi

    # 检查是否已安装
    if echo "$installed_plugins" | grep -q "${name}@${marketplace}"; then
      ok "$display 已安装"
      continue
    fi

    # 如果有自定义 marketplace，先添加
    if [[ -n "$marketplace_source" ]]; then
      local existing_marketplaces
      existing_marketplaces=$(claude plugin marketplace list 2>/dev/null || echo "")

      if ! echo "$existing_marketplaces" | grep -q "$marketplace_source"; then
        info "添加 marketplace: $marketplace (源: $marketplace_source)"
        if $DRY_RUN; then
          dry "claude plugin marketplace add $marketplace github:$marketplace_source"
        else
          if claude plugin marketplace add "$marketplace" "github:$marketplace_source" 2>/dev/null; then
            ok "marketplace $marketplace 添加成功"
          else
            warn "marketplace $marketplace 添加失败，尝试直接安装..."
          fi
        fi
      else
        info "marketplace $marketplace 已存在"
      fi
    fi

    # 安装 plugin
    info "安装 $display ..."
    if $DRY_RUN; then
      dry "claude plugin install ${name}@${marketplace}"
    else
      if claude plugin install "${name}@${marketplace}" 2>/dev/null; then
        ok "$display 安装成功"
      else
        err "$display 安装失败"
      fi
    fi

  done < <(parse_plugins)
}

# ── Git Skills 安装 ────────────────────────────────────────
install_git_skills() {
  header "安装 Git Skills"

  mkdir -p "$CLAUDE_SKILLS_DIR"

  while IFS=$'\t' read -r name source; do
    [[ -z "$name" || -z "$source" ]] && continue

    local target="$CLAUDE_SKILLS_DIR/$name"

    if [[ -d "$target" ]]; then
      ok "skill/$name 已存在，跳过（如需更新请手动 git pull）"
      continue
    fi

    info "克隆 skill/$name 从 $source ..."
    if $DRY_RUN; then
      dry "git clone $source $target"
    else
      if git clone --depth=1 "$source" "$target" 2>/dev/null; then
        ok "skill/$name 克隆成功"
        # 如果有 install.sh，自动执行
        if [[ -f "$target/install.sh" ]]; then
          info "  运行 $name/install.sh ..."
          if (cd "$target" && bash install.sh 2>&1 | tail -5); then
            ok "  $name/install.sh 执行完成"
          else
            warn "  $name/install.sh 执行有警告，请手动检查"
          fi
        fi
      else
        err "skill/$name 克隆失败（URL: $source）"
        warn "  请检查 registry.yml 中的 source 地址是否正确"
      fi
    fi

  done < <(parse_git_skills)
}

# ── 显示 Symlink Skills 状态 ────────────────────────────────
show_symlink_skills() {
  header "Symlink Skills 状态"

  local symlink_skills=(defuddle file-organizer find-skills ljg-paper markdown-proxy recall skill-creator)

  for name in "${symlink_skills[@]}"; do
    local target="$CLAUDE_SKILLS_DIR/$name"
    if [[ -L "$target" ]]; then
      ok "$name → $(readlink "$target")"
    else
      warn "$name 未找到（需通过 openclaw/agent 系统安装）"
    fi
  done

  echo ""
  info "Symlink skills 由 openclaw 等 agent 系统管理，安装时请参考对应文档"
}

# ── 显示手动安装提醒 ───────────────────────────────────────
install_backup_skills() {
  header "安装备份的 Manual Skills"

  local backup_dir="$SCRIPT_DIR/skills"
  [[ -d "$backup_dir" ]] || { info "无备份 skill 目录，跳过"; return; }

  for skill_dir in "$backup_dir"/*/; do
    local name
    name=$(basename "$skill_dir")
    local target="$CLAUDE_SKILLS_DIR/$name"

    if [[ -d "$target" ]]; then
      ok "skill/$name 已存在，跳过"
      continue
    fi

    info "安装备份 skill: $name ..."
    if $DRY_RUN; then
      dry "cp -r $skill_dir $target"
    else
      cp -r "$skill_dir" "$target"
      ok "skill/$name 安装完成"
    fi
  done
}

# ── 总结 ──────────────────────────────────────────────────
show_summary() {
  header "安装完成"
  echo ""
  echo -e "  ${BOLD}已安装的 Skills 总览:${NC}"
  echo ""

  # Plugins
  echo -e "  ${CYAN}Plugins (claude plugin list):${NC}"
  claude plugin list 2>/dev/null | grep -E "✔|✘" | while read -r line; do
    echo "    $line"
  done

  # Skills 目录
  echo ""
  echo -e "  ${CYAN}Skills (~/.claude/skills/):${NC}"
  ls "$CLAUDE_SKILLS_DIR" 2>/dev/null | while read -r s; do
    echo "    • $s"
  done

  echo ""
  if $DRY_RUN; then
    warn "以上为 DRY RUN 模式，未实际执行任何安装"
  fi
}

# ── 主流程 ────────────────────────────────────────────────
main() {
  echo -e "${BOLD}${CYAN}"
  echo "╔══════════════════════════════════════════╗"
  echo "║   Claude Code Skills 一键安装            ║"
  echo "║   来源: dotfiles/claude/skills-registry  ║"
  echo "╚══════════════════════════════════════════╝"
  echo -e "${NC}"

  $DRY_RUN && warn "DRY RUN 模式 — 只显示操作，不实际执行"

  check_deps

  if ! $ONLY_SKILLS; then
    install_plugins
  fi

  if ! $ONLY_PLUGINS; then
    install_git_skills
    install_backup_skills
    show_symlink_skills
  fi

  show_summary
}

main "$@"
