#!/usr/bin/env bash

echo "# BASH.RC ADDITIONS"
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

TARGETPATH="$HOME/.bashrc"
ADDITIONS="$SCRIPT_DIR/../configs/bashrc_additions.sh"

if grep -qF "[ -f $ADDITIONS ]" "$TARGETPATH"; then
  echo "checked: bashrc_additions.sh is sourced"
else
  echo "[ -f $ADDITIONS ] && source $ADDITIONS" >>"$TARGETPATH"
  echo "installed: Sourced bashrc_additions.sh"
fi
