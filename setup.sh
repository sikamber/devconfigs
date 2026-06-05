#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
INSTALLERS_DIR="$SCRIPT_DIR/installers"

echo ""

# Add symlinks to config files
bash "$INSTALLERS_DIR/symlinks.sh"
echo ""

# Add bashadditions to .bashrc
bash "$INSTALLERS_DIR/bashrc.sh"
echo ""
