#!/usr/bin/env bash
# Bootstrap a fresh WSL instance. Run from the directory where devconfigs should be cloned.
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/sikamber/devconfigs/main/bootstrap.sh)

REPO_URL="https://github.com/sikamber/devconfigs.git"
REPO_DIR="$PWD/devconfigs"

# Install git if missing
if ! command -v git &>/dev/null; then
    echo "Installing git..."
    sudo apt-get update -qq && sudo apt-get install -y git
fi

# Clone the repo if not already present
if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "Cloning devconfigs to $REPO_DIR..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

exec bash "$REPO_DIR/setup.sh"
