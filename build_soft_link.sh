#!/bin/bash
mkdir -p ~/bin/tmux-session

# 获取脚本所在的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# 遍历配置文件中的每一行
while IFS= read -r FILE; do
    # 跳过以'#'开头的行
    if [[ $FILE =~ ^# ]]; then
        continue
    fi
    # 创建或更新符号链接
    ln -snf $SCRIPT_DIR/"$FILE" ~/"$FILE"
done < "$SCRIPT_DIR/config_list"

#for FILE in `cat config_list`;do
#    if [[ $FILE =~ '#' ]];then
#	    continue;
#    fi
#    ln -snf ~/dotfiles/$FILE ~/$FILE
#done
