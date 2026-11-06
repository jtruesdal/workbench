#!/bin/bash
# Morning check, run on one machine: bash ~/workbench/checks/run.sh <derecho|izumi>
# Updates the workbench clone, then runs every workstream's checks/<workstream>.sh for this machine.
M=${1:?usage: run.sh derecho|izumi}
W=$(cd "$(dirname "$0")/.." && pwd)
git -C "$W" pull -q --ff-only 2>/dev/null || echo "(workbench: git pull failed; using the local copy)"
echo "######## $M  $(date '+%Y-%m-%d %H:%M')  workbench $(git -C "$W" rev-parse --short HEAD)"
for f in "$W"/checks/*.sh; do
  [ "$(basename "$f")" = run.sh ] && continue
  echo; echo "==== $(basename "$f" .sh)"
  bash "$f" "$M" 2>&1 | sed 's/^/  /'
done
