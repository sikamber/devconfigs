#!/usr/bin/env bash

# When piped through run_step, stdout is not a terminal — prefix triggers display logic.
# When run directly, just echo normally.
report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

before=$(claude --version 2>/dev/null | head -n1)

# Skip the slow installer when already on the latest published version
if [[ -n "$before" ]]; then
  latest=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
  current_version=$(echo "$before" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
  if [[ -n "$latest" && "$current_version" == "$latest" ]]; then
    report "up to date: claude ($before)"
    exit 0
  fi
fi

# Re-running the install script upgrades claude if already present
curl -fsSL https://claude.ai/install.sh | bash

after=$(claude --version 2>/dev/null | head -n1)

if [[ -z "$before" ]]; then
  report "installed: claude ($after)"
elif [[ "$before" != "$after" ]]; then
  report "upgraded: claude ($before -> $after)"
else
  report "up to date: claude ($after)"
fi
