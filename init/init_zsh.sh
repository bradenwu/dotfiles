#!/usr/bin/env bash
# Install ~/.zshrc. Optionally install oh-my-zsh + plugins.
# Relies on init_shell.sh for .aliases/.functions/.path/.exports sourcing.
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

print_info "Installing zsh module (mode=$DOTFILES_MODE)"

ensure_cmd zsh "skipping zsh module; install zsh first or use init_bash.sh on bash-only servers"

install_file "configs/zshrc" "$HOME/.zshrc"

# Optional: oh-my-zsh.  Controlled by INSTALL_OH_MY_ZSH=yes|no|ask (default ask).
INSTALL_OH_MY_ZSH="${INSTALL_OH_MY_ZSH:-ask}"
install_omz=false
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_info "oh-my-zsh already present"
else
    case "$INSTALL_OH_MY_ZSH" in
        yes) install_omz=true ;;
        no)  install_omz=false ;;
        ask)
            if [ -t 0 ]; then
                read -r -p "Install oh-my-zsh? [y/N] " reply
                [[ "$reply" =~ ^[Yy]$ ]] && install_omz=true
            else
                print_info "Non-interactive; skipping oh-my-zsh (set INSTALL_OH_MY_ZSH=yes to force)"
            fi
            ;;
    esac
fi

if [ "$install_omz" = true ]; then
    print_info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
        || print_warn "oh-my-zsh installer returned non-zero"
    # Plugins
    local_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    [ -d "$local_custom/plugins/zsh-autosuggestions" ] \
        || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$local_custom/plugins/zsh-autosuggestions" 2>/dev/null \
        || print_warn "zsh-autosuggestions install skipped"
    [ -d "$local_custom/plugins/zsh-syntax-highlighting" ] \
        || git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$local_custom/plugins/zsh-syntax-highlighting" 2>/dev/null \
        || print_warn "zsh-syntax-highlighting install skipped"
fi

print_ok "zsh module installed"
print_info "Reload with: exec zsh -l"
