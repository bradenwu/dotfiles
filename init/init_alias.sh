#!/usr/bin/env bash
# Install aliases configuration.
#
# Usage (local clone):   bash init/init_alias.sh
# Usage (remote):        curl -fsSL .../init/init_alias.sh | bash
set -euo pipefail

RAW_BASE="${DOTFILES_RAW_BASE:-https://raw.githubusercontent.com/bradenwu/dotfiles/master}"

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

print_info "Installing alias module (mode=$DOTFILES_MODE)"

install_file "configs/aliases" "$HOME/.aliases"

print_ok "alias module installed"
