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
export PATH=$PATH:/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools
export HOMEBREW_NO_AUTO_UPDATE=1
use_proxy
