#!/usr/bin/env bash

# Azure DevOps helpers. Organization, project and repo are auto-detected from the git
# remote of the current directory, so these run from inside a DevOps-backed repo — there
# is nothing to pass and nothing to configure per project. Auth is the PAT stored by
# `az devops login`; see manualsetup.md if a command reports that login is needed.

usage() {
  echo "usage: kdo devops <command>"
  echo ""
  echo "commands:"
  echo "  list            open work items in this project"
  echo "  create <name>   create a Feature work item"
}

# Organization and project are read off the git remote, so every command needs to be
# standing in a repo — az reports this as an auth-ish error otherwise, which misleads.
require_repo() {
  git rev-parse --git-dir &>/dev/null && return 0
  echo "kdo devops: run this from inside a repo — the project is detected from its git remote"
  return 1
}

# "Open" has to span process templates: Agile closes to Closed, Scrum and Basic to Done.
# Removed is the discard state in all three. Anything not in this list counts as open.
CLOSED_STATES="'Closed', 'Removed', 'Done'"

# az boards query returns each item with its columns nested under .fields, which -o table
# renders unusably. The --query projection flattens the ones worth seeing. Title goes last
# because it is the only column with unbounded width.
devops_list() {
  require_repo || return 1

  az boards query \
    --wiql "SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State], [System.AssignedTo]
            FROM WorkItems
            WHERE [System.State] NOT IN ($CLOSED_STATES)
            ORDER BY [System.ChangedDate] DESC" \
    --query '[].{ID:fields."System.Id", Type:fields."System.WorkItemType", State:fields."System.State", Assigned:fields."System.AssignedTo".displayName, Title:fields."System.Title"}' \
    --output table "$@"
}

# The whole remainder is the title, so `kdo devops create Some new thing` works unquoted.
# That rules out passing extra az flags — reach for `az boards work-item create` directly
# when --description, --assigned-to or --iteration are needed. The type is fixed to
# Feature; change it here if this ends up wanting Task or Bug too.
devops_create() {
  require_repo || return 1

  local title="$*"
  if [[ -z "$title" ]]; then
    echo "usage: kdo devops create <name>"
    return 1
  fi

  # The create response carries id at the top level, unlike query results where every
  # column lives under .fields
  az boards work-item create \
    --title "$title" \
    --type Feature \
    --query '{ID:id, Type:fields."System.WorkItemType", State:fields."System.State", Title:fields."System.Title"}' \
    --output table
}

cmd="$1"

if [[ -z "$cmd" ]]; then
  usage
  exit 1
fi

shift # remaining args pass through to az, so `kdo devops list -o json` overrides the table

case "$cmd" in
list) devops_list "$@" ;;
create) devops_create "$@" ;;
*)
  echo "kdo devops: unknown command '$cmd'"
  echo ""
  usage
  exit 1
  ;;
esac
