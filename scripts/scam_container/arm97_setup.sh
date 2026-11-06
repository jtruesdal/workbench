#!/bin/bash
# arm97_setup.sh -- create an observed-IOP SCAM case (ARM97, ARM Southern Great Plains) the
# ordinary way: compset FSCAMARM97 at the ne30 resolution.  buildcpp should make it an ne3np4
# container automatically.  Short run (10 steps) for testing.  Does not build or submit.
set -e
CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
CASE=/glade/campaign/cgd/amp/jet/cases/SCAM.arm97.ne30.01
IOP=/glade/p/cesmdata/inputdata/atm/cam/scam/iop/ARM97_4scam_c180703.nc
[ -d "$CASE" ] && { echo "$CASE already exists"; exit 1; }
"$CAM/cime/scripts/create_newcase" --case "$CASE" --compset FSCAMARM97 --res ne30_ne30_mg17 \
    --project P93300042 --run-unsupported > "$CASE.create.log" 2>&1 || { tail -20 "$CASE.create.log"; exit 1; }
cd "$CASE"
./xmlchange STOP_OPTION=nsteps,STOP_N=10,JOB_PRIORITY=premium
./xmlchange JOB_WALLCLOCK_TIME=00:30:00 --subgroup case.run
echo "iopfile = '$IOP'" >> user_nl_cam
./case.setup > case.setup.log 2>&1 || { tail -20 case.setup.log; exit 1; }
./preview_namelists > preview.log 2>&1 || { tail -20 preview.log; exit 1; }
echo "== $CASE"
./xmlquery CAM_CONFIG_OPTS,PTS_LAT,PTS_LON,RUN_STARTDATE,ATM_GRID,PTS_DOMAINFILE | grep -E '^\s+[A-Z_]+:'
echo "== configure (container?):"
grep -h -E 'id="(hgrid|scam_iop_hgrid)"' Buildconf/camconf/config_cache.xml | sed -E 's/.*id="([a-z_]+)" value="([^"]*)".*/   \1 = \2/'
echo "== namelist:"
grep -E '^ *(iopfile|ncdata|bnd_topo|scm_iop_hgrid|se_ne)\s' CaseDocs/atm_in
