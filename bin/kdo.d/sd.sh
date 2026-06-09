#!/usr/bin/env bash

# Flags (any order): --push to auto-commit and push eligible repos, --pull to auto-pull eligible repos, --verbose to show all output
PUSH=false
PULL=false
VERBOSE=false
for arg in "$@"; do
  [[ "$arg" == "--push"    || "$arg" == "-p" ]] && PUSH=true
  [[ "$arg" == "--pull"    || "$arg" == "-l" ]] && PULL=true
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

do_pull() {
  local dir="$1"
  # fetch already ran before this call, so merge --ff-only avoids a second network round trip
  git -C "$dir" merge --ff-only @{u}
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

  # Check for commits ahead/behind the remote.
  # @{u} is the upstream tracking branch — if it doesn't exist, treat as unpushed.
  # With --pull, fetch first so the behind check reflects actual remote state.
  if git -C "$dir" rev-parse @{u} &>/dev/null 2>&1; then
    $PULL && git -C "$dir" fetch 2>/dev/null
    ahead=$(git -C "$dir" log @{u}.. --oneline 2>/dev/null)
    behind=$(git -C "$dir" log ..@{u} --oneline 2>/dev/null)
  else
    ahead="no-upstream"
    behind=""
  fi

  # Nothing to do — fully in sync with remote
  if [[ -z "$uncommitted" && -z "$ahead" && -z "$behind" ]]; then
    echo "fully synced: $name"
    continue
  fi

  # Auto-pull only if: --pull flag was given, clean working tree, on main, behind only (not diverged)
  if $PULL && [[ -z "$uncommitted" && -z "$ahead" && -n "$behind" ]]; then
    branch_count=$(git -C "$dir" branch | wc -l)
    current_branch=$(git -C "$dir" branch --show-current)

    if [[ "$branch_count" -eq 1 && "$current_branch" == "main" ]]; then
      if run_quiet do_pull "$dir"; then
        echo "auto-pulled: $name"
      else
        echo "auto-pull failed: $name"
      fi
      continue
    fi
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

  # Reporting — check eligibility once for hint messages
  branch_count=$(git -C "$dir" branch | wc -l)
  current_branch=$(git -C "$dir" branch --show-current)
  on_main=$([[ "$branch_count" -eq 1 && "$current_branch" == "main" ]] && echo true || echo false)

  if [[ -n "$behind" && (-n "$uncommitted" || -n "$ahead") ]]; then
    echo "diverged: $name"
  elif [[ -n "$behind" ]]; then
    if $on_main; then
      echo "behind remote: $name (run with --pull to auto-pull)"
    else
      echo "behind remote: $name"
    fi
  elif $on_main; then
    echo "unpushed changes in: $name (run with --push to auto-push)"
  else
    echo "unpushed changes in: $name"
  fi
done
