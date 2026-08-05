#!/usr/bin/env bash

report() { if [[ -t 1 ]]; then echo "$@"; else echo "report:$*"; fi; }

# Installs the native Linux az. WSL also exposes a Windows az.exe through interop, but
# every invocation pays the Windows process-start cost and extensions land in the Windows
# profile, so this script always addresses /usr/bin/az explicitly.
AZ=/usr/bin/az

# Only the organization is stable enough to pin. `az repos` auto-detects org and project
# from the git remote when run inside a repo, so a project default only matters for
# `az boards` / `az pipelines` invoked from elsewhere.
DEVOPS_ORG="https://dev.azure.com/SduLandingZones"

before=$("$AZ" version --query '"azure-cli"' -o tsv 2>/dev/null)

# Microsoft's installer adds the apt repo and installs; re-running it upgrades in place
curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash

# --upgrade installs when missing and upgrades when present
"$AZ" extension add --name azure-devops --upgrade --only-show-errors

"$AZ" devops configure --defaults organization="$DEVOPS_ORG"

after=$("$AZ" version --query '"azure-cli"' -o tsv 2>/dev/null)
ext=$("$AZ" extension show --name azure-devops --query version -o tsv 2>/dev/null)

if [[ -z "$before" ]]; then
  report "installed: az ($after, azure-devops $ext)"
  report "  run 'az login --use-device-code' once to sign in"
elif [[ "$before" != "$after" ]]; then
  report "upgraded: az ($before -> $after, azure-devops $ext)"
else
  report "up to date: az ($after, azure-devops $ext)"
fi

# WSL appends the Windows PATH, so /usr/bin should win — but say so if it does not,
# since a shadowed az is slow rather than broken and would otherwise go unnoticed.
resolved=$(command -v az 2>/dev/null)
if [[ "$resolved" != "$AZ" ]]; then
  report "  warning: 'az' resolves to $resolved, not $AZ"
fi
