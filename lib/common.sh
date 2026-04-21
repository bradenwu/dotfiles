#!/usr/bin/env bash
# Shared runtime for init_*.sh modules.
# Sourced by each init script (not executed). Provides:
#   - colored print helpers
#   - detect_os
#   - install_file  (dual-mode: symlink when local clone, curl when remote curl|bash)
#   - backup_if_exists  (FAIL-CLOSED: returns non-zero on any backup failure)
#
# Safety contract:
#   install_file will NEVER remove or overwrite an existing target unless
#   backup_if_exists has returned success. A failed backup aborts with the
#   original file untouched.

# ── Colors ────────────────────────────────────────────────
if [ -t 1 ]; then
    _RED=$'\033[0;31m'; _GREEN=$'\033[0;32m'; _YELLOW=$'\033[1;33m'
    _BLUE=$'\033[0;34m'; _BOLD=$'\033[1m'; _NC=$'\033[0m'
else
    _RED=""; _GREEN=""; _YELLOW=""; _BLUE=""; _BOLD=""; _NC=""
fi

print_info() { echo "${_BLUE}[INFO]${_NC}  $*"; }
print_ok()   { echo "${_GREEN}[OK]${_NC}    $*"; }
print_warn() { echo "${_YELLOW}[WARN]${_NC}  $*"; }
print_err()  { echo "${_RED}[ERR]${_NC}   $*" >&2; }

# ── OS detection ─────────────────────────────────────────
detect_os() {
    case "$OSTYPE" in
        darwin*)     echo macos ;;
        linux-gnu*)  echo linux ;;
        *)           echo unknown ;;
    esac
}

# ── Backup ────────────────────────────────────────────────
# backup_if_exists <path> [<new_source>]
#
# Contract:
#   - Returns 0 and prints "Backed up …" only when a verified backup now exists on disk.
#   - Returns 0 with no work if <path> does not exist, or if it is already a symlink
#     pointing at <new_source> (idempotent no-op).
#   - Returns NON-ZERO on any failure (cannot create backup dir, cp failed, backup
#     file did not actually land). The target is never modified here, so callers
#     can abort safely.
backup_if_exists() {
    local target="$1"
    local new_source="${2:-}"
    [ -e "$target" ] || [ -L "$target" ] || return 0

    # Idempotent short-circuit: already the exact symlink we would install.
    if [ -L "$target" ] && [ -n "$new_source" ]; then
        local current
        current="$(readlink "$target")"
        [ "$current" = "$new_source" ] && return 0
    fi

    local backup_dir="$HOME/.dotfiles_backup"
    if ! mkdir -p "$backup_dir"; then
        print_err "Cannot create backup dir: $backup_dir"
        return 1
    fi
    if [ ! -w "$backup_dir" ]; then
        print_err "Backup dir not writable: $backup_dir"
        return 1
    fi

    local ts name backup_path
    ts="$(date +%Y%m%d_%H%M%S)"
    name="$(basename "$target")"
    backup_path="$backup_dir/${name}_${ts}"

    # Let cp errors surface; do NOT redirect stderr to /dev/null.
    if ! cp -RP "$target" "$backup_path"; then
        print_err "Backup failed: $target → $backup_path (original preserved)"
        rm -rf "$backup_path" || true
        return 1
    fi
    # Verify the backup actually exists on disk before we return success.
    if [ ! -e "$backup_path" ] && [ ! -L "$backup_path" ]; then
        print_err "Backup verification failed: $backup_path not found (original preserved)"
        return 1
    fi

    print_info "Backed up $target → $backup_path"
    return 0
}

# ── Core install primitive ────────────────────────────────
# install_file <logical_path_under_repo> <target_absolute_path> [--mode 0755]
#
# Modes:
#   local  — symlink <target> → $DOTFILES_ROOT/<logical>
#   remote — download $RAW_BASE/<logical> as a real file at <target>
#
# Safety:
#   - If <target> already exists, we REFUSE to modify it until backup_if_exists
#     has confirmed a durable backup. A failed backup => function returns 1 and
#     the user's original file is left in place.
#   - Remote mode downloads to <target>.tmp first; the original is only replaced
#     by an atomic mv AFTER both download and backup have succeeded.
#
# Caller must have set: DOTFILES_MODE (local|remote), and either DOTFILES_ROOT
# (local) or RAW_BASE (remote).
install_file() {
    local logical="$1"
    local target="$2"
    shift 2
    local mode=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --mode) mode="$2"; shift 2 ;;
            *) print_err "install_file: unknown flag $1"; return 1 ;;
        esac
    done

    local target_dir
    target_dir="$(dirname "$target")"
    if ! mkdir -p "$target_dir"; then
        print_err "Cannot create target dir: $target_dir"
        return 1
    fi

    case "$DOTFILES_MODE" in
        local)
            local src="$DOTFILES_ROOT/$logical"
            if [ ! -e "$src" ]; then
                print_err "Source not found: $src"
                return 1
            fi
            # Fast path: already the correct symlink. Nothing to do.
            if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
                print_info "unchanged: $target → $src"
                return 0
            fi
            if ! backup_if_exists "$target" "$src"; then
                print_err "Aborting install of $target (backup failed, original untouched)"
                return 1
            fi
            # Backup confirmed durable; safe to replace.
            rm -rf "$target"
            if ! ln -s "$src" "$target"; then
                print_err "Failed to create symlink: $target → $src"
                return 1
            fi
            print_ok "symlink $target → $src"
            ;;
        remote)
            local url="$RAW_BASE/$logical"
            local tmp="${target}.dotfiles-new.$$"
            # 1) download first — does not touch target
            if ! curl -fsSL "$url" -o "$tmp"; then
                print_err "Download failed: $url"
                rm -f "$tmp"
                return 1
            fi
            # 2) now back up the existing target (if any). A failed backup aborts.
            if ! backup_if_exists "$target"; then
                print_err "Aborting install of $target (backup failed, original untouched)"
                rm -f "$tmp"
                return 1
            fi
            # 3) atomic replace on same filesystem
            if ! mv -f "$tmp" "$target"; then
                print_err "Failed to move $tmp → $target"
                rm -f "$tmp"
                return 1
            fi
            [ -n "$mode" ] && chmod "$mode" "$target"
            print_ok "downloaded $url → $target"
            ;;
        *)
            print_err "DOTFILES_MODE not set (expected local|remote)"
            return 1
            ;;
    esac
}

# ── Convenience ───────────────────────────────────────────
# ensure_cmd <name> [<install-hint>]
ensure_cmd() {
    command -v "$1" >/dev/null 2>&1 && return 0
    print_warn "'$1' not found${2:+ ($2)}"
    return 1
}
