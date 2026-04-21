#!/usr/bin/env bash
# Install ~/.gitconfig from template.
# Unlike other modules this generates a REAL file (not a symlink) because the
# config is personalized per-user. Inputs:
#   GIT_NAME, GIT_EMAIL  (env vars) — if set, non-interactive
#   otherwise prompts on a TTY
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

print_info "Installing git module (mode=$DOTFILES_MODE)"

# Fetch the template
tpl="$(mktemp -t dotfiles_gitconfig.XXXXXX)"
trap 'rm -f "$tpl"' EXIT
if [ "$DOTFILES_MODE" = local ]; then
    cp "$DOTFILES_ROOT/configs/gitconfig.template" "$tpl"
else
    curl -fsSL "$RAW_BASE/configs/gitconfig.template" -o "$tpl" || {
        print_err "Failed to fetch gitconfig template"; exit 1; }
fi

# Gather identity
name="${GIT_NAME:-}"
email="${GIT_EMAIL:-}"
if [ -z "$name" ] || [ -z "$email" ]; then
    if [ -t 0 ]; then
        [ -z "$name" ]  && read -r -p "Git user.name:  " name
        [ -z "$email" ] && read -r -p "Git user.email: " email
    else
        print_err "Non-interactive run requires GIT_NAME and GIT_EMAIL env vars"
        exit 1
    fi
fi

ensure_cmd git "required to render ~/.gitconfig"

# Render and back up any existing real ~/.gitconfig
rendered="$(mktemp -t dotfiles_gitconfig_out.XXXXXX)"
cp "$tpl" "$rendered"
git config -f "$rendered" user.name "$name"
git config -f "$rendered" user.email "$email"

if ! backup_if_exists "$HOME/.gitconfig"; then
    print_err "Aborting: could not back up existing ~/.gitconfig"
    rm -f "$rendered"
    exit 1
fi
mv -f "$rendered" "$HOME/.gitconfig"
print_ok "wrote ~/.gitconfig for $name <$email>"
print_ok "git module installed"
