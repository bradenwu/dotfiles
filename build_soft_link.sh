for FILE in `cat config_list`;do
    ln -snf ~/dotfiles/$FILE ~/$FILE
done
