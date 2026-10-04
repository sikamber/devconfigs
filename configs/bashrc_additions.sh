# These are added to .bashrc by the symlinks script

kdo_bin_path="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../bin"
export PATH="$kdo_bin_path:$PATH"

alias cdw='cd ~/workspace/github.com/sikamber/'

# git, Claude Code (ctrl-g) and most other tools pick their editor from these; with
# neither set they fall back to their own defaults (nano, vim).
if command -v nvim >/dev/null 2>&1; then
  export VISUAL=nvim
  export EDITOR=nvim
fi
