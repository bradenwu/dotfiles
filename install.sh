#!/usr/bin/env bash
# Full dotfiles install for a trusted personal machine.
#
# This orchestrates the per-tool init modules under init/.  On a shared or
# public server you usually do NOT want this — run a single init_*.sh instead:
#
#   curl -fsSL https://raw.githubusercontent.com/bradenwu/dotfiles/master/init/init_tmux.sh | bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<EOF
Usage: $0 [install|check|help]

  install   Run all init_*.sh modules interactively (default)
  check     Run check_env.sh only
  help      Show this help

Environment:
  INSTALL_MODULES   Space-separated module names to install non-interactively.
                    Example: INSTALL_MODULES="shell zsh tmux vim" ./install.sh
                    Bash-only server: INSTALL_MODULES="shell alias bash tmux vim" ./install.sh
                    Valid names: shell alias zsh bash tmux vim git ssh claude
  GIT_NAME / GIT_EMAIL
                    Skip the git identity prompt when used with init_git.sh.
EOF
}

ask_yn() {
    local prompt="$1"
    if [ -t 0 ]; then
        read -r -p "$prompt [y/N] " reply
        [[ "$reply" =~ ^[Yy]$ ]]
    else
        return 1
    fi
}

run_module() {
    local name="$1"
    local script="$SCRIPT_DIR/init/init_${name}.sh"
    if [ ! -x "$script" ]; then
        print_err "Module not found or not executable: $script"
        return 1
    fi
    echo
    print_info "── module: $name ──"
    bash "$script"
}

cmd="${1:-install}"
case "$cmd" in
    help|-h|--help)
        usage; exit 0 ;;
    check)
        exec "$SCRIPT_DIR/check_env.sh" ;;
    install)
        : ;;
    *)
        print_err "Unknown command: $cmd"; usage; exit 1 ;;
esac

# Default module order: shell helpers first (zsh/bash rc's source them).
ALL_MODULES=(shell alias)
if command -v zsh >/dev/null 2>&1; then
    ALL_MODULES+=(zsh)
fi
ALL_MODULES+=(bash tmux vim git ssh claude)

# Pre-flight env check (non-fatal — warn only)
if [ -x "$SCRIPT_DIR/check_env.sh" ]; then
    print_info "Running environment check..."
    "$SCRIPT_DIR/check_env.sh" || print_warn "check_env.sh reported issues; continuing"
fi

# Determine which modules to install
if [ -n "${INSTALL_MODULES:-}" ]; then
    # Non-interactive: use the env var verbatim
    # shellcheck disable=SC2206
    modules=($INSTALL_MODULES)
else
    modules=()
    for m in "${ALL_MODULES[@]}"; do
        if ask_yn "Install $m module?"; then
            modules+=("$m")
        fi
    done
fi

if [ "${#modules[@]}" -eq 0 ]; then
    print_warn "No modules selected; nothing to do"
    exit 0
fi

print_info "Will install: ${modules[*]}"
failed_modules=()
for m in "${modules[@]}"; do
    if ! run_module "$m"; then
        failed_modules+=("$m")
        print_err "Module '$m' failed (continuing with remaining modules)"
    fi
done

if [ "${#failed_modules[@]}" -ne 0 ]; then
    print_err "Install failed for: ${failed_modules[*]}"
    exit 1
fi

echo
print_ok "Done.  Backups (if any) are in ~/.dotfiles_backup/"
print_info "Restart your shell or run: exec \$SHELL -l"
