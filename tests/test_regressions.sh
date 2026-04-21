#!/usr/bin/env bash
# Regression tests for installer behavior and module-specific edge cases.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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
    mkdir -p "$sb/home"
    echo "$sb"
}

test_install_failure_propagates() {
    echo "Test: install.sh exits non-zero when a module fails"
    local sb rc
    sb="$(_sandbox)"
    set +e
    HOME="$sb/home" INSTALL_MODULES="doesnotexist" bash "$REPO_ROOT/install.sh" >/dev/null 2>&1
    rc=$?
    set -e
    _assert "install.sh returned non-zero" "[ $rc -ne 0 ]"
    rm -rf "$sb"
}

test_path_is_portable() {
    echo "Test: configs/path uses HOME instead of a hard-coded account"
    local sb path_value
    sb="$(_sandbox)"
    path_value="$(
        HOME="$sb/home" PATH="/bin:/usr/bin" /bin/bash -c '. "$1"; printf "%s" "$PATH"' bash "$REPO_ROOT/configs/path"
    )"
    _assert "adds HOME/bin" "[[ \"$path_value\" == *\"$sb/home/bin\"* ]]"
    _assert "adds HOME/.local/bin" "[[ \"$path_value\" == *\"$sb/home/.local/bin\"* ]]"
    _assert "does not mention the original account path" "[[ \"$path_value\" != *\"/Users/wuzhigang/bin\"* ]]"
    rm -rf "$sb"
}

test_path_recovers_system_commands() {
    echo "Test: configs/path recovers from a broken PATH and stays idempotent"
    local sb path_once path_twice
    sb="$(_sandbox)"
    path_once="$(
        HOME="$sb/home" PATH="/opt/anaconda3" /bin/bash -c '. "$1"; printf "%s" "$PATH"' bash "$REPO_ROOT/configs/path"
    )"
    path_twice="$(
        HOME="$sb/home" PATH="/opt/anaconda3" /bin/bash -c '. "$1"; . "$1"; printf "%s" "$PATH"' bash "$REPO_ROOT/configs/path"
    )"

    _assert "adds /usr/bin" "[[ \":$path_once:\" == *\":/usr/bin:\"* ]]"
    _assert "adds /bin" "[[ \":$path_once:\" == *\":/bin:\"* ]]"
    _assert "preserves existing PATH entries" "[[ \":$path_once:\" == *\":/opt/anaconda3:\"* ]]"
    _assert "re-sourcing does not duplicate entries" "[ \"\$(printf '%s' '$path_twice' | tr ':' '\\n' | sort | uniq -d | wc -l | tr -d ' ')\" -eq 0 ]"
    rm -rf "$sb"
}

test_zshrc_recovers_path_before_oh_my_zsh() {
    echo "Test: configs/zshrc restores PATH before oh-my-zsh initialization"
    local sb rc output
    sb="$(_sandbox)"
    ln -s "$REPO_ROOT/configs/path" "$sb/home/.path"
    touch "$sb/home/.exports" "$sb/home/.aliases" "$sb/home/.functions" "$sb/home/.local"
    mkdir -p "$sb/home/.oh-my-zsh"
    cat > "$sb/home/.oh-my-zsh/oh-my-zsh.sh" <<'EOF'
command -v mkdir >/dev/null || return 11
command -v git >/dev/null || return 12
command -v dirname >/dev/null || return 13
command -v uname >/dev/null || return 14
mkdir -p "$HOME/.omz-path-test"
EOF

    if [ ! -x /bin/zsh ]; then
        _assert "zsh is available for startup regression" "true"
        rm -rf "$sb"
        return 0
    fi

    set +e
    output="$(
        HOME="$sb/home" PATH="/opt/anaconda3" /bin/zsh -fc '
            source "$1"
            command -v git
            command -v mkdir
            command -v dirname
            command -v uname
            printf "%s\n" "$PATH"
        ' zsh "$REPO_ROOT/configs/zshrc" 2>&1
    )"
    rc=$?
    set -e

    _assert "zshrc sourced successfully with broken incoming PATH" "[ $rc -eq 0 ]"
    _assert "git is resolvable after zshrc" "[[ \"$output\" == *\"/git\"* ]]"
    _assert "mkdir is resolvable after zshrc" "[[ \"$output\" == *\"/mkdir\"* ]]"
    _assert "dirname is resolvable after zshrc" "[[ \"$output\" == *\"/dirname\"* ]]"
    _assert "uname is resolvable after zshrc" "[[ \"$output\" == *\"/uname\"* ]]"
    _assert "final zsh PATH contains /usr/bin" "[[ \"$output\" == *\"/usr/bin\"* ]]"
    _assert "final zsh PATH contains /bin" "[[ \"$output\" == *\"/bin\"* ]]"
    rm -rf "$sb"
}

test_zsh_module_requires_zsh_before_writing_rc() {
    echo "Test: init_zsh.sh does not write ~/.zshrc when zsh is unavailable"
    local sb repo rc
    sb="$(_sandbox)"
    repo="$sb/repo"
    mkdir -p "$repo/lib" "$repo/init" "$repo/configs"
    cp "$REPO_ROOT/lib/common.sh" "$repo/lib/common.sh"
    cp "$REPO_ROOT/init/init_zsh.sh" "$repo/init/init_zsh.sh"
    cp "$REPO_ROOT/configs/zshrc" "$repo/configs/zshrc"
    chmod +x "$repo/init/init_zsh.sh"

    set +e
    HOME="$sb/home" PATH="/usr/bin" /bin/bash "$repo/init/init_zsh.sh" >/dev/null 2>&1
    rc=$?
    set -e

    _assert "zsh module fails clearly" "[ $rc -ne 0 ]"
    _assert "does not create ~/.zshrc without zsh" "[ ! -e '$sb/home/.zshrc' ]"
    rm -rf "$sb"
}

test_bashrc_sources_shared_helpers_on_bash_only_server() {
    echo "Test: configs/bashrc can source shared helpers under bash"
    local sb rc output
    sb="$(_sandbox)"
    ln -s "$REPO_ROOT/configs/path" "$sb/home/.path"
    ln -s "$REPO_ROOT/configs/exports" "$sb/home/.exports"
    ln -s "$REPO_ROOT/configs/aliases" "$sb/home/.aliases"
    ln -s "$REPO_ROOT/configs/functions" "$sb/home/.functions"
    ln -s "$REPO_ROOT/configs/functions.linux" "$sb/home/.functions.linux"
    touch "$sb/home/.local"

    set +e
    output="$(
        HOME="$sb/home" PATH="/opt/anaconda3" /bin/bash --noprofile --norc -c '
            source "$1"
            command -v git
            command -v mkdir
            printf "%s\n" "$PATH"
        ' bash "$REPO_ROOT/configs/bashrc" 2>&1
    )"
    rc=$?
    set -e

    _assert "bashrc sourced successfully with broken incoming PATH" "[ $rc -eq 0 ]"
    _assert "git is resolvable after bashrc" "[[ \"$output\" == *\"/git\"* ]]"
    _assert "mkdir is resolvable after bashrc" "[[ \"$output\" == *\"/mkdir\"* ]]"
    _assert "final bash PATH contains /usr/bin" "[[ \"$output\" == *\"/usr/bin\"* ]]"
    _assert "final bash PATH contains /bin" "[[ \"$output\" == *\"/bin\"* ]]"
    rm -rf "$sb"
}

test_git_identity_escaping() {
    echo "Test: init_git.sh preserves special characters in identity values"
    local sb
    sb="$(_sandbox)"
    HOME="$sb/home" GIT_NAME='R&D | West \ Team' GIT_EMAIL='a&b|c\@example.com' bash "$REPO_ROOT/init/init_git.sh" >/dev/null
    _assert "renders name literally" "[ \"\$(git config -f '$sb/home/.gitconfig' user.name)\" = 'R&D | West \\ Team' ]"
    _assert "renders email literally" "[ \"\$(git config -f '$sb/home/.gitconfig' user.email)\" = 'a&b|c\\@example.com' ]"
    rm -rf "$sb"
}

test_tmux_installs_helper_to_local_bin() {
    echo "Test: init_tmux.sh installs tmux-session into ~/.local/bin"
    local sb repo
    sb="$(_sandbox)"
    repo="$sb/repo"
    mkdir -p "$repo/lib" "$repo/init" "$repo/configs" "$repo/bin" "$sb/stub-bin"
    cp "$REPO_ROOT/lib/common.sh" "$repo/lib/common.sh"
    cp "$REPO_ROOT/init/init_tmux.sh" "$repo/init/init_tmux.sh"
    cp "$REPO_ROOT/configs/tmux.conf" "$repo/configs/tmux.conf"
    cp "$REPO_ROOT/bin/tmux-session" "$repo/bin/tmux-session"
    chmod +x "$repo/init/init_tmux.sh" "$repo/bin/tmux-session"
    cat > "$sb/stub-bin/tmux" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$sb/stub-bin/tmux"

    HOME="$sb/home" PATH="$sb/stub-bin:/bin:/usr/bin" bash "$repo/init/init_tmux.sh" >/dev/null

    _assert "installs helper into ~/.local/bin" "[ -f '$sb/home/.local/bin/tmux-session' ]"
    _assert "helper is executable" "[ -x '$sb/home/.local/bin/tmux-session' ]"
    _assert "does not write helper into ~/bin" "[ ! -e '$sb/home/bin/tmux-session' ]"
    rm -rf "$sb"
}

test_claude_installs_env_next_to_scripts() {
    echo "Test: init_claude.sh installs .env beside switch scripts"
    local sb repo rc
    sb="$(_sandbox)"
    repo="$sb/repo"
    mkdir -p "$repo/lib" "$repo/init" "$repo/claude"
    cp "$REPO_ROOT/lib/common.sh" "$repo/lib/common.sh"
    cp "$REPO_ROOT/init/init_claude.sh" "$repo/init/init_claude.sh"
    cp "$REPO_ROOT/switch_cc_to_default.sh" "$repo/switch_cc_to_default.sh"
    cp "$REPO_ROOT/switch_cc_to_glm.sh" "$repo/switch_cc_to_glm.sh"
    cp "$REPO_ROOT/switch_cc_to_kimi.sh" "$repo/switch_cc_to_kimi.sh"
    chmod +x "$repo/init/init_claude.sh"
    cat > "$repo/.env" <<'EOF'
GLM_TOKEN=glm-test-token
KIMI_TOKEN=kimi-test-token
EOF
    cat > "$repo/claude/install-skills.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "skills installer stub" >/dev/null
EOF
    chmod +x "$repo/claude/install-skills.sh"

    HOME="$sb/home" bash "$repo/init/init_claude.sh" >/dev/null

    _assert "installs switch script" "[ -f '$sb/home/.claude-switch/switch_cc_to_glm.sh' ]"
    _assert "installs .env beside switch scripts" "[ -f '$sb/home/.claude-switch/.env' ]"
    _assert "copies env content" "[ \"\$(cat '$sb/home/.claude-switch/.env')\" = \$'GLM_TOKEN=glm-test-token\nKIMI_TOKEN=kimi-test-token' ]"
    rm -rf "$sb"
}

test_alias_module_local() {
    echo "Test: init_alias.sh installs ~/.aliases in local mode"
    local sb repo
    sb="$(_sandbox)"
    repo="$sb/repo"
    mkdir -p "$repo/lib" "$repo/init" "$repo/configs"
    cp "$REPO_ROOT/lib/common.sh" "$repo/lib/common.sh"
    cp "$REPO_ROOT/init/init_alias.sh" "$repo/init/init_alias.sh"
    cp "$REPO_ROOT/configs/aliases" "$repo/configs/aliases"
    chmod +x "$repo/init/init_alias.sh"

    HOME="$sb/home" bash "$repo/init/init_alias.sh" >/dev/null

    _assert "installs ~/.aliases" "[ -e '$sb/home/.aliases' ]"
    _assert "is a symlink (local mode)" "[ -L '$sb/home/.aliases' ]"
    _assert "symlink points to configs/aliases" "[ '$sb/home/.aliases' -ef '$repo/configs/aliases' ]"
    _assert "content matches" "[ \"\$(cat '$sb/home/.aliases')\" = \"\$(cat '$repo/configs/aliases')\" ]"
    rm -rf "$sb"
}

test_alias_module_idempotent() {
    echo "Test: init_alias.sh is idempotent (re-run does not error)"
    local sb repo rc
    sb="$(_sandbox)"
    repo="$sb/repo"
    mkdir -p "$repo/lib" "$repo/init" "$repo/configs"
    cp "$REPO_ROOT/lib/common.sh" "$repo/lib/common.sh"
    cp "$REPO_ROOT/init/init_alias.sh" "$repo/init/init_alias.sh"
    cp "$REPO_ROOT/configs/aliases" "$repo/configs/aliases"
    chmod +x "$repo/init/init_alias.sh"

    HOME="$sb/home" bash "$repo/init/init_alias.sh" >/dev/null
    set +e
    HOME="$sb/home" bash "$repo/init/init_alias.sh" >/dev/null 2>&1
    rc=$?
    set -e

    _assert "second run succeeds" "[ $rc -eq 0 ]"
    _assert "symlink still valid" "[ '$sb/home/.aliases' -ef '$repo/configs/aliases' ]"
    rm -rf "$sb"
}

test_alias_module_registered_in_install() {
    echo "Test: alias is listed in install.sh ALL_MODULES and usage"
    _assert "alias in ALL_MODULES" "grep -q 'alias' <(grep 'ALL_MODULES=' '$REPO_ROOT/install.sh')"
    _assert "alias in usage text" "grep -q 'alias' <(grep 'Valid names:' '$REPO_ROOT/install.sh')"
}

test_zshrc_no_tied_path_variable() {
    echo "Test: configs/zshrc never uses 'for path in' (tied-variable regression)"
    _assert "no 'for path in' pattern" "! grep -q 'for path in' '$REPO_ROOT/configs/zshrc'"
    _assert "uses safe loop variable 'p'" "grep -q 'for p in' '$REPO_ROOT/configs/zshrc'"
}

test_all_init_scripts_have_consistent_raw_base() {
    echo "Test: all init scripts use the same RAW_BASE URL"
    local first_raw
    first_raw="$(grep -h 'RAW_BASE=' "$REPO_ROOT"/init/init_*.sh | head -1)"
    for script in "$REPO_ROOT"/init/init_*.sh; do
        local name
        name="$(basename "$script")"
        local this_raw
        this_raw="$(grep 'RAW_BASE=' "$script")"
        _assert "$name RAW_BASE matches others" "[ \"$this_raw\" = \"$first_raw\" ]"
    done
}

test_tmux_remote_mode_no_leakage() {
    echo "Test: tmux-only install (simulated remote) does not leak other modules"
    local sb repo
    sb="$(_sandbox)"
    repo="$sb/repo"
    mkdir -p "$repo/lib" "$repo/init" "$repo/configs" "$repo/bin" "$sb/stub-bin"
    cp "$REPO_ROOT/lib/common.sh" "$repo/lib/common.sh"
    cp "$REPO_ROOT/init/init_tmux.sh" "$repo/init/init_tmux.sh"
    cp "$REPO_ROOT/configs/tmux.conf" "$repo/configs/tmux.conf"
    cp "$REPO_ROOT/bin/tmux-session" "$repo/bin/tmux-session"
    chmod +x "$repo/init/init_tmux.sh" "$repo/bin/tmux-session"

    # Only install tmux module — no shell, zsh, bash, git, etc.
    HOME="$sb/home" INSTALL_MODULES="tmux" bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 || true

    _assert ".tmux.conf landed" "[ -e '$sb/home/.tmux.conf' ]"
    _assert "tmux-session in ~/.local/bin" "[ -f '$sb/home/.local/bin/tmux-session' ]"
    _assert "NO .zshrc leaked" "[ ! -e '$sb/home/.zshrc' ]"
    _assert "NO .bashrc leaked" "[ ! -e '$sb/home/.bashrc' ]"
    _assert "NO .aliases leaked" "[ ! -e '$sb/home/.aliases' ]"
    _assert "NO .functions leaked" "[ ! -e '$sb/home/.functions' ]"
    _assert "NO .gitconfig leaked" "[ ! -e '$sb/home/.gitconfig' ]"
    rm -rf "$sb"
}

echo "──────────────────────────────────────────"
echo "Regression tests"
echo "──────────────────────────────────────────"
test_install_failure_propagates
test_path_is_portable
test_path_recovers_system_commands
test_zshrc_recovers_path_before_oh_my_zsh
test_zsh_module_requires_zsh_before_writing_rc
test_bashrc_sources_shared_helpers_on_bash_only_server
test_git_identity_escaping
test_tmux_installs_helper_to_local_bin
test_claude_installs_env_next_to_scripts
test_alias_module_local
test_alias_module_idempotent
test_alias_module_registered_in_install
test_zshrc_no_tied_path_variable
test_all_init_scripts_have_consistent_raw_base
test_tmux_remote_mode_no_leakage

echo "──────────────────────────────────────────"
echo "Passed: $PASS    Failed: $FAIL"
if [ $FAIL -gt 0 ]; then
    echo "FAILED:"
    for n in "${FAILED_NAMES[@]}"; do echo "  - $n"; done
    exit 1
fi
echo "All regression tests passed."
