#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
INSTALLERS_DIR="$SCRIPT_DIR/installers"

# Parse flags; strip from args before forwarding to sub-scripts
VERBOSE=false
filtered_args=()
for arg in "$@"; do
  [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && VERBOSE=true || filtered_args+=("$arg")
done

# Each run appends to a timestamped log file so noise stays off the terminal
# but is always available for debugging.
LOG_DIR="$SCRIPT_DIR/.setuplogs"
LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%dT%H:%M:%S').log"
mkdir -p "$LOG_DIR"

# When piped through run_step, stdout is not a terminal — prefix triggers display logic.
# When run directly, just echo normally.
report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

# Wraps a command whose output is pure process noise (e.g. apt, npm).
# All output is logged. Lines prefixed with "report:" are extracted and printed
# to the terminal after the step completes; everything else stays in the log.
# Scripts should use the report() helper function to emit those lines.
run_step() {
  local label="$1"
  shift

  printf '\n=== %s (%s) ===\n' "$label" "$(date '+%H:%M:%S')" >>"$LOG_FILE"

  if $VERBOSE; then
    # Strip report: markers — they're just normal output lines in verbose mode
    "$@" 2>&1 | tee -a "$LOG_FILE" | sed 's/^report://'
    local status=${PIPESTATUS[0]}
    return "$status"
  fi

  local tmpfile
  tmpfile=$(mktemp)
  local cols
  cols=$(tput cols 2>/dev/null || echo 80)

  echo "# ${label^^}"
  printf '  %s...' "$label"

  "$@" 2>&1 | while IFS= read -r line; do
    printf '%s\n' "$line" >>"$LOG_FILE"
    printf '%s\n' "$line" >>"$tmpfile"
    printf '\r\033[K  %s' "${line:0:$((cols - 4))}"
  done
  local status=${PIPESTATUS[0]}

  # Clear the live status line
  printf '\r\033[K'

  if [[ $status -eq 0 ]]; then
    # Print any lines the script explicitly marked for display; fall back to a generic message
    local reported
    reported=$(grep '^report:' "$tmpfile" | sed 's/^report://')
    if [[ -n "$reported" ]]; then
      echo "$reported"
    else
      echo "done: $label"
    fi
  else
    echo "failed: $label"
    sed 's/^report://' "$tmpfile"
    echo "(full log: $LOG_FILE)"
  fi

  rm -f "$tmpfile"
  return "$status"
}

# Pure apt commands live here rather than in a separate script — easy to see
# and edit what's installed, and report() is already in scope.
apt_packages() {
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -
  sudo apt update

  # Capture output to extract apt's own summary line ("X upgraded, Y newly installed")
  apt_out=$(sudo apt install -y \
    curl git gh ripgrep fd-find neovim xsel \
    zip unzip nodejs tmux \
    python3 python3-pip python3-venv 2>&1)
  echo "$apt_out"
  apt_summary=$(printf '%s\n' "$apt_out" | grep -oE '^[0-9]+ upgraded.*' | head -n1)

  report "${apt_summary:-apt: all packages up to date}"
}

PACKAGES_DIR="$INSTALLERS_DIR/installers"

echo ""
bash "$INSTALLERS_DIR/symlinks.sh" "${filtered_args[@]}"
echo ""
bash "$INSTALLERS_DIR/bashrc.sh"
echo ""
bash "$INSTALLERS_DIR/gitconfig.sh"
echo ""
run_step "apt packages" apt_packages
echo ""
run_step "npm packages" bash "$PACKAGES_DIR/npm-installer.sh"
echo ""
run_step "uv" bash "$PACKAGES_DIR/uv-installer.sh"
echo ""
run_step "nvm" bash "$PACKAGES_DIR/nvm-installer.sh"
echo ""
run_step "claude" bash "$PACKAGES_DIR/claude-installer.sh"
echo ""
run_step "docker" bash "$PACKAGES_DIR/docker-installer.sh"
echo ""
run_step "dotnet" bash "$PACKAGES_DIR/dotnet-installer.sh"
echo ""
echo "log: $LOG_FILE"
echo ""
