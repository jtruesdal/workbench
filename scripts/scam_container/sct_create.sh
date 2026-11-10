#!/bin/bash
# sct_create.sh ID [--generate NAME | --compare NAME]
# Create and build (no run) the SCAM SCT regression test on Derecho.  With --generate/--compare the
# 3D run's history files are written to / compared with the personal baseline NAME under $SCT_BL.
# Run through qcmd, e.g.  qcmd -l walltime=3:00:00 -- bash ~/ss_tools/sct_create.sh sctc05 --generate NAME
source "$(dirname "$0")/sct_common.sh"
id=${1:?usage: sct_create.sh ID [--generate NAME | --compare NAME]}
case "$2" in
    --generate) bl=(--baseline-root "$SCT_BL" -g "${3:?baseline name}") ;;
    --compare)  bl=(--baseline-root "$SCT_BL" -c "${3:?baseline name}") ;;
    "")         bl=() ;;
    *)          echo "unknown option $2"; exit 1 ;;
esac
git --no-pager -C "$SCT_CAM" log --oneline -1
echo "baseline options: ${bl[*]:-none}"
exec "$SCT_CAM/cime/scripts/create_test" "$SCT_TN" --test-id "$id" --no-run --project P93300042 "${bl[@]}"
