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

ensure_alias_loader() {
    local rc="$1"
    local shell_name="$2"
    local loader='[ -r "$HOME/.aliases" ] && . "$HOME/.aliases"'

    if [ -e "$rc" ] || [ -L "$rc" ]; then
        if grep -F '.aliases' "$rc" >/dev/null 2>&1; then
            print_info "$shell_name already loads ~/.aliases"
            return 0
        fi
    fi

    if ! backup_if_exists "$rc"; then
        print_err "Aborting update of $rc (backup failed, original untouched)"
        return 1
    fi

    {
        printf '\n# Load dotfiles aliases\n'
        printf '%s\n' "$loader"
    } >> "$rc" || {
        print_err "Failed to update $rc"
        return 1
    }

    print_ok "enabled ~/.aliases in $rc"
}

enabled_loader=false
for rc_shell in bash zsh; do
    rc="$HOME/.${rc_shell}rc"
    if [ -e "$rc" ] || [ -L "$rc" ]; then
        ensure_alias_loader "$rc" "$rc_shell"
        enabled_loader=true
    fi
done
unset rc rc_shell

if [ "$enabled_loader" = false ]; then
    current_shell="$(basename "${SHELL:-}")"
    case "$current_shell" in
        bash|zsh)
            ensure_alias_loader "$HOME/.${current_shell}rc" "$current_shell"
            ;;
        *)
            print_warn "No bash/zsh rc found; source ~/.aliases from your shell rc to enable aliases"
            ;;
    esac
    unset current_shell
fi
unset enabled_loader

print_ok "alias module installed"
