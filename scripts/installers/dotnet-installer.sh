curl -fsSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version latest --channel 10.0

# Add .net to path if not already there
DOTNET_PATH="$HOME/.dotnet"
if [[ ":$PATH:" != *":$DOTNET_PATH:"* ]]; then
  export PATH="$PATH:$DOTNET_PATH"
  cat >>~/.bashrc <<'EOF'
export PATH="$PATH:$HOME/.dotnet"
EOF
fi

# Install dotnet-ef tool if not present
if ! command -v dotnet-ef &>/dev/null; then
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
