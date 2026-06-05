#!/usr/bin/env bash

report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

# Replace any apt-managed tree-sitter-cli — that version is outdated
sudo apt remove -y tree-sitter-cli 2>/dev/null || true

# Capture output to extract npm's own summary line ("added X", "changed X", "up to date")
npm_out=$(sudo npm install -g typescript tree-sitter-cli 2>&1)
echo "$npm_out"
npm_summary=$(printf '%s\n' "$npm_out" | grep -oE '^(added|changed|up to date)[^$]*' | head -n1)

# Install treesitter parsers headlessly now that tree-sitter-cli is present
nvim --headless "+TSInstall all" +qa

report "${npm_summary:-done: npm packages}"
