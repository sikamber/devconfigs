#!/usr/bin/env bash

# Flags (any order): --push to auto-commit and push eligible repos, --verbose to show all output
PUSH=false
VERBOSE=false
for arg in "$@"; do
  [[ "$arg" == "--push"    || "$arg" == "-p" ]] && PUSH=true
  [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && VERBOSE=true
done

WORKSPACE="$HOME/workspace/github.com/sikamber"

# Runs a command with its output on the alternate terminal screen.
# Output disappears on success; on failure the captured output is replayed.
# Skipped in verbose mode — output flows directly to the terminal.
run_quiet() {
  if $VERBOSE; then
    "$@" 2>&1
    return $?
  fi

  # tee to a temp file so we can replay output on failure after rmcup clears the screen
  local tmpfile; tmpfile=$(mktemp)

  # smcup/rmcup switch to the alternate screen buffer and back, like vim/less do.
  # Unlike cursor-save/restore, this works regardless of how much output is produced.
  tput smcup
  "$@" 2>&1 | tee "$tmpfile"
  local status=${PIPESTATUS[0]}
  tput rmcup

  [[ $status -ne 0 ]] && cat "$tmpfile"
  rm -f "$tmpfile"
  return $status
}

# Groups the three git operations so run_quiet covers all of them in one screen switch
do_push() {
  local dir="$1"
  git -C "$dir" add -A &&
  git -C "$dir" commit -m "automatic push" &&
  git -C "$dir" push
}

for dir in "$WORKSPACE"/*/; do
  name="$(basename "$dir")"

  # Skip anything that isn't a git repo
  if [[ ! -d "$dir/.git" ]]; then
    echo "local folder: $name"
    continue
  fi

  # --porcelain gives machine-readable output; empty string means nothing to commit
  uncommitted=$(git -C "$dir" status --porcelain 2>/dev/null)

  # Check for commits that exist locally but not on the remote.
  # @{u} is the upstream tracking branch — if it doesn't exist, treat as unpushed.
  if git -C "$dir" rev-parse @{u} &>/dev/null 2>&1; then
    ahead=$(git -C "$dir" log @{u}.. --oneline 2>/dev/null)
  else
    ahead="no-upstream"
  fi

  # Nothing to do — clean repo
  if [[ -z "$uncommitted" && -z "$ahead" ]]; then
    echo "fully pushed: $name"
    continue
  fi

  # Auto-push only if: --push flag was given, repo is on main, and has no other branches
  if $PUSH; then
    branch_count=$(git -C "$dir" branch | wc -l)
    current_branch=$(git -C "$dir" branch --show-current)

    if [[ "$branch_count" -eq 1 && "$current_branch" == "main" ]]; then
      if run_quiet do_push "$dir"; then
        echo "auto-pushed: $name"
      else
        echo "auto-push failed: $name"
      fi
      continue
    fi
  fi

  # Check if this repo would have been eligible for auto-push
  branch_count=$(git -C "$dir" branch | wc -l)
  current_branch=$(git -C "$dir" branch --show-current)

  if [[ "$branch_count" -eq 1 && "$current_branch" == "main" ]]; then
    echo "unpushed changes in: $name (run with --push to auto-push)"
  else
    echo "unpushed changes in: $name"
  fi
done
