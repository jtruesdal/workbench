#!/bin/bash
# sct_create.sh ID -- create and build (no run) the scam_container SCT regression test on Derecho.
# Run through qcmd, e.g.  qcmd -l walltime=3:00:00 -- bash ~/ss_tools/sct_create.sh sctc02
source "$(dirname "$0")/sct_common.sh"
id=${1:?usage: sct_create.sh ID   (e.g. sctc02)}
git --no-pager -C "$SCT_CAM" log --oneline -1
exec "$SCT_CAM/cime/scripts/create_test" "$SCT_TN" --test-id "$id" --no-run --project P93300042
