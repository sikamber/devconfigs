#!/usr/bin/env bash

report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

before=$(uv --version 2>/dev/null)
curl -LsSf https://astral.sh/uv/install.sh | sh
after=$(~/.local/bin/uv --version 2>/dev/null || uv --version 2>/dev/null)

if [[ -z "$before" ]]; then
  report "installed: uv ($after)"
elif [[ "$before" != "$after" ]]; then
  report "upgraded: uv ($before -> $after)"
else
  report "up to date: uv ($after)"
fi
