#!/usr/bin/env bash
# Install shell helpers: aliases, functions, path, exports (shared by bash & zsh).
# This module contains PERSONAL aliases and machine-specific paths — it is
# intentionally NOT recommended for public / shared servers.
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

print_info "Installing shell helpers (mode=$DOTFILES_MODE)"

install_file "configs/aliases"        "$HOME/.aliases"
install_file "configs/functions"      "$HOME/.functions"
install_file "configs/path"           "$HOME/.path"
install_file "configs/exports"        "$HOME/.exports"

case "$(detect_os)" in
    macos) install_file "configs/functions.macos" "$HOME/.functions.macos" ;;
    linux) install_file "configs/functions.linux" "$HOME/.functions.linux" ;;
    *)     print_warn "Unknown OS — skipping platform-specific functions" ;;
esac

print_ok "shell helpers installed"
print_info "Next: install a shell rc (init_zsh.sh or init_bash.sh) to source these files"
