#!/usr/bin/env bash

# Flags (any order): --push to auto-commit and push eligible repos, --pull to auto-pull eligible repos,
# --sync to do both, --verbose to show all output
PUSH=false
PULL=false
VERBOSE=false
for arg in "$@"; do
  [[ "$arg" == "--push"    || "$arg" == "-p" ]] && PUSH=true
  [[ "$arg" == "--pull"    || "$arg" == "-l" ]] && PULL=true
  [[ "$arg" == "--sync"    || "$arg" == "-s" ]] && { PUSH=true; PULL=true; }
  [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && VERBOSE=true
done

WORKSPACE="$HOME/workspace/github.com/sikamber"
MACHINE="$(hostname -s 2>/dev/null || hostname)"

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
  # A preceding rebase may already have made this repo ahead with nothing uncommitted,
  # so only add/commit if there's actually something to commit.
  if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
    git -C "$dir" add -A &&
    git -C "$dir" commit -m "automatic push (${MACHINE})" || return 1
  fi
  git -C "$dir" push
}

do_pull() {
  local dir="$1"
  # fetch already ran before this call, so rebase avoids a second network round trip.
  # On failure (conflicts), abort so the repo is left clean for the user to sort out by hand.
  git -C "$dir" rebase @{u} || { git -C "$dir" rebase --abort 2>/dev/null; return 1; }
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
  # Fetch first so the ahead/behind check reflects actual remote state.
  if git -C "$dir" rev-parse @{u} &>/dev/null 2>&1; then
    git -C "$dir" fetch 2>/dev/null
    ahead=$(git -C "$dir" log @{u}.. --oneline 2>/dev/null)
    behind=$(git -C "$dir" log ..@{u} --oneline 2>/dev/null)
  else
    ahead="no-upstream"
    behind=""
  fi

  branch_count=$(git -C "$dir" branch | wc -l)
  current_branch=$(git -C "$dir" branch --show-current)
  on_main=$([[ "$branch_count" -eq 1 && "$current_branch" == "main" ]] && echo true || echo false)

  # Nothing to do — fully in sync with remote
  if [[ -z "$uncommitted" && -z "$ahead" && -z "$behind" ]]; then
    echo "fully synced: $name"
    continue
  fi

  # Auto-pull (rebase) only if: --pull/--sync given, clean working tree, on main, behind
  # (whether or not also ahead — rebase replays local commits on top of the fetched ones).
  if $PULL && $on_main && [[ -z "$uncommitted" && -n "$behind" ]]; then
    if run_quiet do_pull "$dir"; then
      echo "auto-pulled: $name"
      ahead=$(git -C "$dir" log @{u}.. --oneline 2>/dev/null)
      behind=$(git -C "$dir" log ..@{u} --oneline 2>/dev/null)
    else
      echo "auto-pull failed: $name (rebase hit conflicts — resolve by hand)"
      continue
    fi
  fi

  # Auto-push only if: --push/--sync given, repo is on main, and there's something to push
  # (a pull above may have just made this true via a rebase with no working-tree changes).
  if $PUSH && $on_main && [[ -n "$uncommitted" || -n "$ahead" ]]; then
    if run_quiet do_push "$dir"; then
      echo "auto-pushed: $name"
    else
      echo "auto-push failed: $name"
    fi
    continue
  fi

  # Nothing left to do after a successful pull with nothing to push
  if [[ -z "$uncommitted" && -z "$ahead" && -z "$behind" ]]; then
    continue
  fi

  # Reporting
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
