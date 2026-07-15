#!/usr/bin/env bash

# Resolved so this works regardless of how kdo.d/tmux.sh was invoked (symlink, relative path, etc.)
script_dir="$(dirname "$(realpath "$0")")"
# kdo.d -> bin -> devconfigs -> workspace root; Vault is a sibling of devconfigs there
workspace_root="$(dirname "$(dirname "$(dirname "$script_dir")")")"
vault_dir="$workspace_root/Vault"

start_dir="$PWD"
# tmux session names can't contain ':' or '.'
session="$(basename "$start_dir" | tr '.:' '__')"

if tmux has-session -t "$session" 2>/dev/null; then
  exec tmux attach -t "$session"
fi

tmux new-session -d -s "$session" -n claude -c "$start_dir" claude
tmux new-window  -t "$session" -n bash -c "$start_dir"
tmux new-window  -t "$session" -n vault -c "$vault_dir" nvim

tmux select-window -t "$session:claude"
exec tmux attach -t "$session"
