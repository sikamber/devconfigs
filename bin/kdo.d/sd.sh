#!/usr/bin/env bash

# Optional argument: pass "push" to auto-commit and push eligible repos
push="${1:-}"

# Where to look for repos
WORKSPACE="$HOME/workspace/github.com/sikamber"

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

  # Auto-push only if: "push" argument was given, repo is on main, and has no other branches
  if [[ "$push" == "push" ]]; then
    branch_count=$(git -C "$dir" branch | wc -l)
    current_branch=$(git -C "$dir" branch --show-current)

    if [[ "$branch_count" -eq 1 && "$current_branch" == "main" ]]; then
      # Stage everything, commit, and push — suppress git output, show our own message
      if git -C "$dir" add -A &&
        git -C "$dir" commit -m "automatic push" &&
        git -C "$dir" push; then
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
    echo "unpushed changes in: $name (run with 'push' to auto-push)"
  else
    echo "unpushed changes in: $name"
  fi
done
