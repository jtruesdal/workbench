#!/bin/bash
# bfb_nudge.sh on|off -- rerun the Barrow pair (BFB.barrow.3d.01 + BFB.barrow.scam.01) with nudging on or
# off in both halves; no archiving, coupler history every step, SCAM reads the 3D run's CAMIOP file from
# its run directory.  Namelist-only: no rebuild.  Submits the 3D run, then SCAM with a dependency on it.
set -e
case "$1" in on) val=.true. ;; off) val=.false. ;; *) echo "usage: bfb_nudge.sh on|off"; exit 1 ;; esac
C3=/glade/campaign/cgd/amp/jet/cases/BFB.barrow.3d.01
CS=/glade/campaign/cgd/amp/jet/cases/BFB.barrow.scam.01
for c in "$C3" "$CS"; do
    cd "$c"
    if grep -q -i -E '^ *nudge_model *=' user_nl_cam; then
        sed -i -E "s/^( *[Nn][Uu][Dd][Gg][Ee]_[Mm][Oo][Dd][Ee][Ll] *= *).*/\1$val/" user_nl_cam
    else
        echo "Nudge_Model = $val" >> user_nl_cam
    fi
    ./xmlchange DOUT_S=FALSE,HIST_OPTION=nsteps,HIST_N=1
    ./preview_namelists > preview_nudge.log 2>&1 || { tail -20 preview_nudge.log; exit 1; }
    echo "== $(basename $c): $(grep -h -i -E '^\s*(nudge_model|iopfile)\s*=' CaseDocs/atm_in | tr -s ' ' | tr '\n' ' ')"
done
cd "$C3"
id=$(./case.submit 2>&1 | sed -n 's/.*Submitted job case.run with id \([0-9]*\).*/\1/p')
[ -n "$id" ] || { echo "3D submit failed"; exit 1; }
echo "3D job: $id"
cd "$CS"
./case.submit --prereq "$id" 2>&1 | grep -E 'Submitted job|ERROR'
