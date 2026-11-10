#!/bin/bash
# sct_submit.sh ID -- check the SCAM column handoff, set walltime/priority/project, submit the test.
source "$(dirname "$0")/sct_common.sh"
T=$(sct_dir "$1")
cd "$T" || exit 1
echo "== $T"
echo "== SCAM column saved for case 2: $(cat sct_scm_column 2>/dev/null || echo MISSING)"
echo "== 3D case PTS_LAT/LON (must be -999):"; ./xmlquery --value PTS_LAT; echo; ./xmlquery --value PTS_LON; echo
c2=$(ls -d case2/* | head -1)
echo "== SCAM case PTS_LAT/LON:"; "$c2/xmlquery" --caseroot "$c2" --value PTS_LAT; echo; "$c2/xmlquery" --caseroot "$c2" --value PTS_LON; echo
if [ "$(./xmlquery --value PTS_LAT)" != "-999.0" ] || [ ! -f sct_scm_column ]; then
    echo "column handoff not as expected; not submitting"; exit 1
fi
./xmlchange JOB_WALLCLOCK_TIME=01:30:00 --subgroup case.test
./xmlchange JOB_PRIORITY=premium,PROJECT=P93300042
./case.submit 2>&1 | grep -E 'Submitting job script|Submitted job id|ERROR'
