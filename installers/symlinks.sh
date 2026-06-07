#!/usr/bin/env bash

echo "# CONFIG SYMLINKS"
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
SYMLINKS_DIR="$SCRIPT_DIR/../symlinks"

FIX=false
for arg in "$@"; do
  [[ "$arg" == "--fix" ]] && FIX=true
done

SYMLINKS=(
  ".config/nvim"
  ".tmux.conf"
  ".claude/CLAUDE.md"
)

for item in "${SYMLINKS[@]}"; do
  SOURCE="$(realpath "$SYMLINKS_DIR/$item")"
  TARGET="$HOME/$item"
  mkdir -p "$(dirname "$TARGET")"
  if [[ -L "$TARGET" ]]; then
    CURRENT="$(realpath "$TARGET")"
    if [[ "$CURRENT" == "$SOURCE" ]]; then
      echo "checked: $item is already symlinked"
    elif $FIX; then
      ln -sfn "$SOURCE" "$TARGET"
      echo "updated: $item ($CURRENT -> $SOURCE)"
    else
      echo "warning: $item points to $CURRENT (expected $SOURCE) — run with --fix to update"
    fi
  elif [[ -e "$TARGET" ]]; then
    echo "warning: $item exists but is not a symlink, skipping"
  else
    ln -s "$SOURCE" "$TARGET"
    echo "installed: symlink to $item"
  fi
done
