#!/usr/bin/env bash
# Install ~/.ssh/config from template. Writes a real file (not symlink) because
# host blocks are personal. Will back up any existing config first.
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
    _tmp_common="$(mktemp -t dotfiles_common.XXXXXX)"
    trap 'rm -f "$_tmp_common"' EXIT
    curl -fsSL "$RAW_BASE/lib/common.sh" -o "$_tmp_common" || {
        echo "[ERR] Failed to fetch $RAW_BASE/lib/common.sh" >&2; exit 1; }
    source "$_tmp_common"
    DOTFILES_MODE=remote
fi
export DOTFILES_MODE DOTFILES_ROOT RAW_BASE

print_info "Installing ssh module (mode=$DOTFILES_MODE)"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Template is copied as a real file (not symlinked) — users add their own
# sensitive host blocks to ~/.ssh/config.  Back up any pre-existing config.
tpl="$(mktemp -t dotfiles_ssh_cfg.XXXXXX)"
trap 'rm -f "$tpl"' EXIT
if [ "$DOTFILES_MODE" = local ]; then
    cp "$DOTFILES_ROOT/configs/ssh_config.template" "$tpl"
else
    curl -fsSL "$RAW_BASE/configs/ssh_config.template" -o "$tpl" || {
        print_err "Failed to fetch ssh config template"; exit 1; }
fi

if ! backup_if_exists "$HOME/.ssh/config"; then
    print_err "Aborting: could not back up existing ~/.ssh/config"
    exit 1
fi
mv -f "$tpl" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"
print_ok "wrote ~/.ssh/config (mode 600)"

print_ok "ssh module installed"
print_info "Review and edit ~/.ssh/config to add your host entries"
