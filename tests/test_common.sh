#!/usr/bin/env bash
# Unit tests for lib/common.sh safety contract.
# Focus: install_file must NEVER destroy an existing target unless a backup
# has been verified on disk.
#
# Run: bash tests/test_common.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

PASS=0
FAIL=0
FAILED_NAMES=()

_assert() {
    local name="$1"
    local cond="$2"
    if eval "$cond"; then
        echo "  ✓ $name"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $name  (cond: $cond)"
        FAIL=$((FAIL + 1))
        FAILED_NAMES+=("$name")
    fi
}

_sandbox() {
    local sb
    sb="$(mktemp -d)"
    mkdir -p "$sb/repo/configs"
    mkdir -p "$sb/home"
    echo "NEW_CONTENT" > "$sb/repo/configs/hello.conf"
    echo "$sb"
}

# ── Test 1: happy path local mode — creates symlink, backs up existing file ─
test_happy_local() {
    echo "Test: local mode creates symlink and backs up pre-existing real file"
    local sb; sb="$(_sandbox)"
    HOME="$sb/home" DOTFILES_MODE=local DOTFILES_ROOT="$sb/repo"
    echo "ORIGINAL" > "$sb/home/.hello"

    install_file "configs/hello.conf" "$sb/home/.hello" >/dev/null

    _assert "target is symlink" "[ -L '$sb/home/.hello' ]"
    _assert "symlink points at repo source" "[ \"\$(readlink '$sb/home/.hello')\" = '$sb/repo/configs/hello.conf' ]"
    _assert "target reads new content via symlink" "[ \"\$(cat '$sb/home/.hello')\" = 'NEW_CONTENT' ]"
    _assert "backup dir exists" "[ -d '$sb/home/.dotfiles_backup' ]"
    _assert "exactly one backup landed" "[ \$(ls -1A '$sb/home/.dotfiles_backup' | wc -l | tr -d ' ') -eq 1 ]"
    _assert "backup preserves original content" "grep -q ORIGINAL $sb/home/.dotfiles_backup/.hello_*"
    rm -rf "$sb"
}

# ── Test 2: CRITICAL — backup dir unwritable → abort, original preserved ──
test_backup_failure_preserves_original() {
    echo "Test: unwritable backup dir → install aborts, original file preserved (data-loss guard)"
    local sb; sb="$(_sandbox)"
    HOME="$sb/home" DOTFILES_MODE=local DOTFILES_ROOT="$sb/repo"
    echo "DO_NOT_LOSE_ME" > "$sb/home/.hello"

    # Pre-create backup dir as read-only so mkdir -p succeeds but cp fails.
    mkdir -p "$sb/home/.dotfiles_backup"
    chmod 500 "$sb/home/.dotfiles_backup"

    # Under readable+executable but non-writable dir, cp will fail.
    # install_file must return non-zero and NOT touch $sb/home/.hello.
    set +e
    install_file "configs/hello.conf" "$sb/home/.hello" >/dev/null 2>&1
    local rc=$?
    set -e

    _assert "install_file returned non-zero" "[ $rc -ne 0 ]"
    _assert "original target still exists" "[ -f '$sb/home/.hello' ]"
    _assert "original target is NOT a symlink" "[ ! -L '$sb/home/.hello' ]"
    _assert "original content intact" "[ \"\$(cat '$sb/home/.hello')\" = 'DO_NOT_LOSE_ME' ]"

    chmod 700 "$sb/home/.dotfiles_backup"  # cleanup perms
    rm -rf "$sb"
}

# ── Test 3: idempotent — already-correct symlink is a no-op, no dup backup ─
test_idempotent() {
    echo "Test: re-running on already-correct symlink does not create duplicate backups"
    local sb; sb="$(_sandbox)"
    HOME="$sb/home" DOTFILES_MODE=local DOTFILES_ROOT="$sb/repo"

    install_file "configs/hello.conf" "$sb/home/.hello" >/dev/null
    install_file "configs/hello.conf" "$sb/home/.hello" >/dev/null
    install_file "configs/hello.conf" "$sb/home/.hello" >/dev/null

    _assert "symlink still correct" "[ -L '$sb/home/.hello' ]"
    if [ -d "$sb/home/.dotfiles_backup" ]; then
        _assert "no backups accumulated on re-runs" "[ \$(ls -1A '$sb/home/.dotfiles_backup' | wc -l | tr -d ' ') -eq 0 ]"
    else
        _assert "no backup dir created on clean idempotent run" "true"
    fi
    rm -rf "$sb"
}

# ── Test 4: source missing → abort with no damage ─────────────────────────
test_missing_source() {
    echo "Test: missing source in local mode aborts without touching target"
    local sb; sb="$(_sandbox)"
    HOME="$sb/home" DOTFILES_MODE=local DOTFILES_ROOT="$sb/repo"
    echo "KEEP_ME" > "$sb/home/.nope"

    set +e
    install_file "configs/does-not-exist.conf" "$sb/home/.nope" >/dev/null 2>&1
    local rc=$?
    set -e

    _assert "install_file returned non-zero for missing source" "[ $rc -ne 0 ]"
    _assert "target untouched" "[ \"\$(cat '$sb/home/.nope')\" = 'KEEP_ME' ]"
    rm -rf "$sb"
}

# ── Test 5: remote mode with bad URL → no target damage ───────────────────
test_remote_bad_url() {
    echo "Test: remote mode with unreachable URL does not damage existing target"
    local sb; sb="$(_sandbox)"
    HOME="$sb/home" DOTFILES_MODE=remote RAW_BASE="http://127.0.0.1:1/does-not-exist"
    echo "REMOTE_KEEP" > "$sb/home/.hello"

    set +e
    install_file "configs/hello.conf" "$sb/home/.hello" >/dev/null 2>&1
    local rc=$?
    set -e

    _assert "install_file returned non-zero on download failure" "[ $rc -ne 0 ]"
    _assert "target file still present" "[ -f '$sb/home/.hello' ]"
    _assert "target content unchanged" "[ \"\$(cat '$sb/home/.hello')\" = 'REMOTE_KEEP' ]"
    _assert "no .dotfiles-new.* temp left behind" "[ -z \"\$(ls $sb/home/.hello.dotfiles-new.* 2>/dev/null)\" ]"
    rm -rf "$sb"
}

echo "──────────────────────────────────────────"
echo "lib/common.sh safety tests"
echo "──────────────────────────────────────────"
test_happy_local
test_backup_failure_preserves_original
test_idempotent
test_missing_source
test_remote_bad_url

echo "──────────────────────────────────────────"
echo "Passed: $PASS    Failed: $FAIL"
if [ $FAIL -gt 0 ]; then
    echo "FAILED:"
    for n in "${FAILED_NAMES[@]}"; do echo "  - $n"; done
    exit 1
fi
echo "All safety tests passed."
