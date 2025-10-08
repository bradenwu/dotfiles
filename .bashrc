# Bash Configuration
# This file contains bash-specific configurations for server environments

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment and startup programs

# Load user-specific files
for file in ~/.{path,exports,aliases,functions,local}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file

# Load environment variables from .env file in dotfiles directory
if [ -f ~/dotfiles/.env ]; then
    set -a
    source ~/dotfiles/.env
    set +a
fi

# Load platform-specific functions
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Load macOS-specific functions
    if [ -f ~/.functions.macos ]; then
        source ~/.functions.macos
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Load Linux-specific functions
    if [ -f ~/.functions.linux ]; then
        source ~/.functions.linux
    fi
fi

# Enable bash completion if available
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
elif [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# Custom bash aliases
alias bashconfig="nano ~/.bashrc"
alias bashreload="source ~/.bashrc"

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Shell options
shopt -s checkwinsize
shopt -s expand_aliases
shopt -s histappend
shopt -s cmdhist

# History settings
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth
HISTIGNORE='ls:pwd:clear:history'

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Load pyenv automatically by appending
# the following to
# ~/.bash_profile if it exists, otherwise ~/.profile (for login shells)
# and ~/.bashrc (for interactive shells) :

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

# Restart your shell for the changes to take effect.

# Load pyenv-virtualenv automatically by adding
# the following to ~/.bashrc:

eval "$(pyenv virtualenv-init -)"
