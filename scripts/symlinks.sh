mkdir -p ~/.config/
ln -s ~/workspace/github.com/sikamber/devconfigs/configs/nvim ~/.config/
ln -s ~/workspace/github.com/sikamber/devconfigs/configs/tmux.conf ~/.tmux.conf

BASHRC="$HOME/.bashrc"
CUSTOM="$HOME/workspace/github.com/sikamber/devconfigs/scripts/bashrc_additions.sh"

grep -qF "[ -f $CUSTOM ]" "$BASHRC" || echo "[ -f $CUSTOM ] && source $CUSTOM" >>"$BASHRC"
