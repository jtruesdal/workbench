#!/bin/bash
# sct_errors.sh [ID|TESTDIR] -- first errors and log tails for both halves of a SCAM SCT test:
# the 3D run (run/) and the SCAM run (run/case2run/).
source "$(dirname "$0")/sct_common.sh"
T=$(sct_dir "$1")
echo "== TestStatus.log (last 6 lines)"
tail -6 "$T/TestStatus.log"
for d in "$T/run" "$T/run/case2run"; do
    echo
    echo "######## $d"
    [ -d "$d" ] || { echo "   (no such directory)"; continue; }
    cl=$(ls -t "$d"/cesm.log.* 2>/dev/null | head -1)
    al=$(ls -t "$d"/atm.log.* 2>/dev/null | head -1)
    echo "== newest cesm.log: ${cl:-none}"
    [ -n "$cl" ] && zgrep -n -m6 -E 'forrtl|ERROR|endrun|Abort|abort|exceeds' "$cl"
    echo "== newest atm.log (last 12 lines): ${al:-none}"
    [ -n "$al" ] && zcat -f "$al" | tail -12
    echo "== geometry / grid lines in atm.log"
    [ -n "$al" ] && zgrep -E 'scm_read_iop_geometry|phys_grid_init: SCAM|scm_read_gridname|scm_read_iop_column' "$al" | head -6
done
