#!/bin/bash
# check_sct.sh [ID|TESTDIR] -- status of a SCAM SCT test (3D CAMIOP + SCAM BFB check).
# ID like sctc02, or a full test directory; default sctc01.
source "$(dirname "$0")/sct_common.sh"
T=$(sct_dir "$1")
N=$(basename "$T")
echo "== test: $N"
echo "== queue"
qstat -u "$USER" 2>/dev/null | tail -n +4
echo "== TestStatus"
grep -E 'RUN|COMPARE' "$T/TestStatus"
echo "== TDIFF/QDIFF lines in TestStatus.log"
grep -E 'TDIFF|QDIFF' "$T/TestStatus.log" | tail -3
H="$T/run/$N.cam.h1i.2002-01-01-00000.nc"
echo "== CAMIOP file"
if [ -f "$H" ]; then
    ls -l "$H"
    echo "== scm_* geometry fields"
    ncdump -h "$H" | grep -E 'scm_(clat|clon|area)\(' || echo "   (none found)"
else
    echo "   not written yet: $H"
fi
