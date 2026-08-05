#!/usr/bin/env bash

report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

echo "# GIT CONFIG"

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
SHARED_CONFIG="$(realpath "$SCRIPT_DIR/../configs/gitconfig")"
GITCONFIG="$HOME/.gitconfig"

if [[ ! -f "$GITCONFIG" ]]; then
  touch "$GITCONFIG"
  git config --file "$GITCONFIG" --add include.path "$SHARED_CONFIG"
  report "installed: .gitconfig"
elif grep -qF "path = $SHARED_CONFIG" "$GITCONFIG"; then
  report "checked: .gitconfig (include already present)"
else
  git config --file "$GITCONFIG" --add include.path "$SHARED_CONFIG"
  report "updated: .gitconfig (include added)"
fi
