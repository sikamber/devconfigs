#!/usr/bin/env bash

echo "# CONFIG SYMLINKS"
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
SYMLINKS_DIR="$SCRIPT_DIR/../symlinks"

SYMLINKS=(
    ".config/nvim"
    ".tmux.conf"
)

for item in "${SYMLINKS[@]}"; do
    SOURCE="$SYMLINKS_DIR/$item"
    TARGET="$HOME/$item"
    mkdir -p "$(dirname "$TARGET")"
    if [[ -L "$TARGET" ]]; then
        echo "checked: $item is already symlinked"
    elif [[ -e "$TARGET" ]]; then
        echo "warning: $item exists but is not a symlink, skipping"
    else
        ln -s "$SOURCE" "$TARGET"
        echo "installed: $item symlinked"
    fi
done
