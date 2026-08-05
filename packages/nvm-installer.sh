#!/usr/bin/env bash

report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

# NVM installs itself as a git repo, so git describe is more reliable than grepping nvm.sh
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
before=$(git -C "$NVM_DIR" describe --tags 2>/dev/null)
NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
after=$(git -C "$NVM_DIR" describe --tags 2>/dev/null)

if [[ -z "$before" ]]; then
  report "installed: nvm ($after)"
elif [[ "$before" != "$after" ]]; then
  report "upgraded: nvm ($before -> $after)"
else
  report "up to date: nvm ($after)"
fi
