#!/bin/bash
# bfb_rerun.sh -- rerun the Barrow pair with per-step surface diagnostics (no rebuild):
#  * CAM tape 4 every step: surface fluxes, fractions, surface temperatures (both cases)
#  * coupler (mediator) history every step: every component's imports/exports and the fractions
#  * no short-term archiving; SCAM reads the 3D run's CAMIOP file from its run directory again
# Then submits the 3D run, and SCAM with a dependency on it.
set -e
C3=/glade/campaign/cgd/amp/jet/cases/BFB.barrow.3d.01
CS=/glade/campaign/cgd/amp/jet/cases/BFB.barrow.scam.01
FL="fincl4 = 'SHFLX','LHFLX','QFLX','TS','TREFHT','QREFHT','ICEFRAC','OCNFRAC','LANDFRAC','FSNS','FLNS','TAUX','TAUY','PS'"
for c in "$C3" "$CS"; do
    cd "$c"
    ./xmlchange DOUT_S=FALSE,HIST_OPTION=nsteps,HIST_N=1
    sed -i '/^ *fincl4 *=/d' user_nl_cam
    echo "$FL" >> user_nl_cam
done
# 3D case: tape 4 every step, one file per run (the testmod sets tapes 1-2 only)
cd "$C3"
sed -i -E '/^ *(nhtfrq|mfilt) *=/d' user_nl_cam
printf "nhtfrq = 0,1,1,1\nmfilt = 1,10000,1,48\n" >> user_nl_cam
RUN3=$(./xmlquery --value RUNDIR)
# SCAM case: its SCT settings already write every tape every step; IOP file back in the run directory
cd "$CS"
sed -i "s|^iopfile = .*|iopfile = '$RUN3/BFB.barrow.3d.01.cam.h1i.2002-01-01-00000.nc'|" user_nl_cam
for c in "$C3" "$CS"; do
    cd "$c"
    ./preview_namelists > preview_rerun.log 2>&1 || { tail -20 preview_rerun.log; exit 1; }
    echo "== $(basename $c): $(grep -i -E '^ *(nhtfrq|mfilt|iopfile)\s' CaseDocs/atm_in | tr -s ' ' | tr '\n' ' ')"
    grep -i '^ *fincl4' CaseDocs/atm_in | cut -c1-120
    ./xmlquery DOUT_S,HIST_OPTION,HIST_N | grep -E '^\s+[A-Z_]+:'
done
cd "$C3"
id=$(./case.submit 2>&1 | sed -n 's/.*Submitted job case.run with id \([0-9]*\).*/\1/p')
echo "3D job: $id"
cd "$CS"
./case.submit --prereq "$id" 2>&1 | grep -E 'Submitted job|ERROR'
