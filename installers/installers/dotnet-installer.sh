#!/usr/bin/env bash

report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

# Use the full path since dotnet may not be on PATH yet during a first install
before=$("$HOME/.dotnet/dotnet" --version 2>/dev/null)

# Re-running the install script upgrades dotnet if already present
curl -fsSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel LTS

# Add .net to path if not already there
DOTNET_PATH="$HOME/.dotnet"
if [[ ":$PATH:" != *":$DOTNET_PATH:"* ]]; then
  export PATH="$PATH:$DOTNET_PATH"
  cat >>~/.bashrc <<'EOF'
export PATH="$PATH:$HOME/.dotnet"
EOF
fi

# Install or upgrade dotnet-ef tool
if command -v dotnet-ef &>/dev/null; then
  dotnet tool update --global dotnet-ef
else
  dotnet tool install --global dotnet-ef
fi

# Add DOTNET_ROOT to .bashrc if not already there
if ! grep -q 'DOTNET_ROOT' ~/.bashrc; then
  echo "export DOTNET_ROOT=\"\$HOME/.dotnet\"" >>~/.bashrc
fi

# Add .dotnet/tools to PATH in .bashrc if not already there
if ! grep -q '.dotnet/tools' ~/.bashrc; then
  echo "export PATH=\"\$PATH:\$HOME/.dotnet/tools\"" >>~/.bashrc
fi

after=$("$HOME/.dotnet/dotnet" --version 2>/dev/null)

if [[ -z "$before" ]]; then
  report "installed: dotnet ($after)"
elif [[ "$before" != "$after" ]]; then
  report "upgraded: dotnet ($before -> $after)"
else
  report "up to date: dotnet ($after)"
fi
