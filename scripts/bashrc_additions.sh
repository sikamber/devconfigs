# Checks workspace for git stuff that should be pushed
unpushed() {
  local root="${1:-$HOME/workspace}"
  find "$root" -maxdepth 4 -type d -name ".git" | while IFS= read -r gitdir; do
    repo="${gitdir%/.git}"
    if ! git -C "$repo" rev-parse @\{u\} &>/dev/null; then
      echo "NO UPSTREAM: $repo"
    else
      count=$(git -C "$repo" log --oneline @\{u\}.. 2>/dev/null | wc -l)
      [ "$count" -gt 0 ] && echo "$count unpushed: $repo"
    fi
  done
}
