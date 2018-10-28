
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

source $ZSH/oh-my-zsh.sh

# Path to your oh-my-zsh installation.
ZSH_THEME="robbyrussell"
plugins=(git)

DISABLE_AUTO_TITLE="true"
