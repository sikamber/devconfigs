#!/usr/bin/env bash

echo "# BASH.RC ADDITIONS"
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

TARGETPATH="$HOME/.bashrc"

# realpath collapses the "steps/.." segment before the path is written to .bashrc.
# Without it the stored line encodes whatever directory this script happened to live
# in, and ".." cannot traverse out of a directory that no longer exists — so renaming
# that directory leaves a line that silently stops resolving. The [ -f ] guard turns
# that into a no-op rather than an error, which drops bin/ off PATH with no warning.
ADDITIONS="$(realpath "$SCRIPT_DIR/../configs/bashrc_additions.sh")"
SOURCE_LINE="[ -f $ADDITIONS ] && source $ADDITIONS"

# Any other line sourcing a bashrc_additions.sh is left over from an earlier layout
# (there have been two: scripts/ and installers/). Drop them so .bashrc does not
# accumulate one dead line per rename, and so machines set up under an old layout
# repair themselves the next time setup.sh runs.
mapfile -t STALE < <(grep -F 'bashrc_additions.sh' "$TARGETPATH" | grep -vxF "$SOURCE_LINE")

if [[ ${#STALE[@]} -gt 0 ]]; then
  cp "$TARGETPATH" "$TARGETPATH.bak"
  # Read from the backup, write to the original — safe to redirect over the source.
  grep -vF 'bashrc_additions.sh' "$TARGETPATH.bak" >"$TARGETPATH"
  echo "removed: ${#STALE[@]} stale bashrc_additions.sh line(s) (backup: $TARGETPATH.bak)"
fi

if grep -qxF "$SOURCE_LINE" "$TARGETPATH"; then
  echo "checked: bashrc_additions.sh is sourced"
else
  echo "$SOURCE_LINE" >>"$TARGETPATH"
  echo "installed: sourced bashrc_additions.sh"
fi
