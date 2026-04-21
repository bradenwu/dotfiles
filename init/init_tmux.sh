#!/usr/bin/env bash
# Install tmux configuration.
#
# Usage (local clone):   bash init/init_tmux.sh
# Usage (remote one-liner):
#   curl -fsSL https://raw.githubusercontent.com/hnhbwzg/dotfiles/master/init/init_tmux.sh | bash
#
# Environment overrides:
#   DOTFILES_RAW_BASE   — override the raw GitHub base URL (useful for testing
#                         against a local http.server)
set -euo pipefail

RAW_BASE="${DOTFILES_RAW_BASE:-https://raw.githubusercontent.com/hnhbwzg/dotfiles/master}"

# Resolve this script's directory (may be empty when piped via curl|bash).
_self="${BASH_SOURCE[0]:-}"
if [ -n "$_self" ] && [ -f "$_self" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"
else
    SCRIPT_DIR=""
fi

# Load lib/common.sh: prefer local sibling, fall back to curl.
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    DOTFILES_MODE=local
    # shellcheck source=../lib/common.sh
    source "$SCRIPT_DIR/../lib/common.sh"
else
    _tmp_common="$(mktemp -t dotfiles_common.XXXXXX)"
    trap 'rm -f "$_tmp_common"' EXIT
    curl -fsSL "$RAW_BASE/lib/common.sh" -o "$_tmp_common" || {
        echo "[ERR] Failed to fetch $RAW_BASE/lib/common.sh" >&2
        exit 1
    }
    # shellcheck disable=SC1090
    source "$_tmp_common"
    DOTFILES_MODE=remote
fi
export DOTFILES_MODE DOTFILES_ROOT RAW_BASE

print_info "Installing tmux module (mode=$DOTFILES_MODE)"

install_file "configs/tmux.conf"    "$HOME/.tmux.conf"
install_file "bin/tmux-session"     "$HOME/.local/bin/tmux-session" --mode 0755

ensure_cmd tmux "install via 'brew install tmux' or 'apt-get install tmux'"

print_ok "tmux module installed"

if ! echo ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
    print_warn "~/.local/bin is not on PATH.  Add it:"
    print_warn "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
fi
