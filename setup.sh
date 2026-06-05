#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
INSTALLERS_DIR="$SCRIPT_DIR/installers"

# Parse flags; strip --verbose before forwarding remaining args to sub-scripts
VERBOSE=false
filtered_args=()
for arg in "$@"; do
  [[ "$arg" == "--verbose" ]] && VERBOSE=true || filtered_args+=("$arg")
done

# Runs a labeled step with its output on the alternate terminal screen.
# The screen is restored when the step finishes, leaving just a done/failed line.
# On failure, the captured output is replayed so the error is visible.
run_step() {
  local label="$1"; shift

  if $VERBOSE; then
    "$@" 2>&1
    local status=$?
    [[ $status -eq 0 ]] && echo "done: $label" || echo "failed: $label"
    return $status
  fi

  # tee to a temp file so we can replay output on failure after rmcup clears the screen
  local tmpfile; tmpfile=$(mktemp)

  # smcup switches to the alternate screen buffer, like vim/less do.
  # Unlike cursor-save/restore, this works regardless of how much output is produced.
  tput smcup
  "$@" 2>&1 | tee "$tmpfile"
  local status=${PIPESTATUS[0]}

  # rmcup restores the original screen, erasing everything printed above
  tput rmcup

  if [[ $status -eq 0 ]]; then
    echo "done: $label"
  else
    echo "failed: $label"
    cat "$tmpfile"
  fi

  rm -f "$tmpfile"
  return $status
}

echo ""
run_step "config symlinks" bash "$INSTALLERS_DIR/symlinks.sh" "${filtered_args[@]}"
echo ""
run_step "bashrc additions" bash "$INSTALLERS_DIR/bashrc.sh"
echo ""
