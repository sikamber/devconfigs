# These are added to .bashrc by the symlinks script

kdo_bin_path="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../bin"
export PATH="$kdo_bin_path:$PATH"

alias cdw='cd ~/workspace/github.com/sikamber/'
