export PATH="$HOME/.local/bin:$PATH"
# Zsh Configuration
# This file contains zsh-specific configurations

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Plugins to load
plugins=(
    git
)

# Disable auto-setting terminal title
DISABLE_AUTO_TITLE="true"

# Load oh-my-zsh
if [ -d "$ZSH" ]; then
    source $ZSH/oh-my-zsh.sh
else
    echo "Warning: oh-my-zsh not found. Please install it first."
fi

# User configuration

# Load user-specific files
for file in ~/.{path,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file

# Custom aliases
alias zshconfig="nano ~/.zshrc"
alias zshreload="source ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
export SCRCPY_SERVER_PATH=/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools/scrcpy-server
export PATH=$PATH:/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools
export HOMEBREW_NO_AUTO_UPDATE=1
use_proxy

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias pip=pip3
alias python=python3

# >>> portable init helper >>>
# Usage: init_if_found "name" "source_file" "path1" "path2" ...
# Example: init_if_found "conda" "etc/profile.d/conda.sh" "/opt/anaconda3" "$HOME/anaconda3"
init_if_found() {
    local name="$1"
    local source_file="$2"
    shift 2

    for path in "$@"; do
        if [ -f "$path/$source_file" ]; then
            . "$path/$source_file"
            return 0
        elif [ -x "$path" ] && [ -z "$source_file" ]; then
            export PATH="$path:$PATH"
            return 0
        fi
    done
    return 1
}

# Add to PATH if directory exists
# Usage: add_to_path "path1" "path2" ...
add_to_path() {
    for path in "$@"; do
        if [ -d "$path" ] && [[ ":$PATH:" != *":$path:"* ]]; then
            export PATH="$path:$PATH"
        fi
    done
}
# <<< portable init helper <<<

# >>> conda initialize <<<
init_if_found "conda" "etc/profile.d/conda.sh" \
    "/opt/anaconda3" "/opt/miniconda3" \
    "$HOME/anaconda3" "$HOME/miniconda3" \
    "$HOME/.local/anaconda3" "$HOME/.local/miniconda3"
# <<< conda initialize <<<

