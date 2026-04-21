#!/usr/bin/env bash
# Install personal Claude Code assets: model-switch helpers + skills registry.
#
# This module is PERSONAL — it references .env tokens and writes files that are
# only useful on a trusted machine. It is deliberately LOCAL-MODE-ONLY: running
# curl|bash on a shared server is not supported here (would be a footgun).
set -euo pipefail

RAW_BASE="${DOTFILES_RAW_BASE:-https://raw.githubusercontent.com/hnhbwzg/dotfiles/master}"

_self="${BASH_SOURCE[0]:-}"
if [ -n "$_self" ] && [ -f "$_self" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"
else
    SCRIPT_DIR=""
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    DOTFILES_MODE=local
    source "$SCRIPT_DIR/../lib/common.sh"
else
    echo "[ERR] init_claude.sh requires a local clone of the repo (it references .env and claude/ registry)." >&2
    echo "      Clone https://github.com/hnhbwzg/dotfiles first, then run bash init/init_claude.sh" >&2
    exit 1
fi
export DOTFILES_MODE DOTFILES_ROOT RAW_BASE

print_info "Installing claude module (mode=$DOTFILES_MODE)"

# The switch scripts are sourced — leave them inside the repo and expose
# stable paths under ~/.claude-switch/.  This avoids polluting $HOME and
# keeps all switch scripts under a single directory.
mkdir -p "$HOME/.claude-switch"
for sw in switch_cc_to_default.sh switch_cc_to_glm.sh switch_cc_to_kimi.sh; do
    [ -f "$DOTFILES_ROOT/$sw" ] || { print_warn "skip $sw (missing)"; continue; }
    install_file "$sw" "$HOME/.claude-switch/$sw" --mode 0644
done

if [ -f "$DOTFILES_ROOT/.env" ]; then
    if ! backup_if_exists "$HOME/.claude-switch/.env"; then
        print_err "Aborting: could not back up existing ~/.claude-switch/.env"
        exit 1
    fi
    tmp_env="$HOME/.claude-switch/.env.dotfiles-new.$$"
    if ! cp "$DOTFILES_ROOT/.env" "$tmp_env"; then
        print_err "Failed to copy .env to ~/.claude-switch"
        rm -f "$tmp_env"
        exit 1
    fi
    chmod 600 "$tmp_env"
    if ! mv -f "$tmp_env" "$HOME/.claude-switch/.env"; then
        print_err "Failed to install ~/.claude-switch/.env"
        rm -f "$tmp_env"
        exit 1
    fi
else
    print_warn ".env not found. Copy .env.example to .env and fill in your tokens."
fi

# Skills & plugins registry lives in claude/ — delegate to its installer.
if [ -x "$DOTFILES_ROOT/claude/install-skills.sh" ]; then
    print_info "Running claude/install-skills.sh"
    bash "$DOTFILES_ROOT/claude/install-skills.sh" || print_warn "install-skills.sh returned non-zero"
else
    print_warn "claude/install-skills.sh not found or not executable"
fi

print_ok "claude module installed"
print_info "Usage: source ~/.claude-switch/switch_cc_to_glm.sh"
