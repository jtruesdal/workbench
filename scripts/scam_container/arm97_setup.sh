#!/bin/bash
# arm97_setup.sh NAME [--full-grid]
# Create an observed-IOP SCAM case (ARM97, ARM Southern Great Plains) the ordinary way: compset
# FSCAMARM97 at ne30.  Default: buildcpp makes it an ne3np4 container.  --full-grid adds
# -scam_full_grid (classic SCAM on the full ne30 grid).  CLM warm start.  10-step test run.
# Does not build or submit.
set -e
CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
CASE=/glade/campaign/cgd/amp/jet/cases/${1:?usage: arm97_setup.sh NAME [--full-grid]}
IOP=/glade/p/cesmdata/inputdata/atm/cam/scam/iop/ARM97_4scam_c180703.nc
[ -d "$CASE" ] && { echo "$CASE already exists"; exit 1; }
"$CAM/cime/scripts/create_newcase" --case "$CASE" --compset FSCAMARM97 --res ne30_ne30_mg17 \
    --project P93300042 --run-unsupported > "$CASE.create.log" 2>&1 || { tail -20 "$CASE.create.log"; exit 1; }
cd "$CASE"
echo "== CLM_FORCE_COLDSTART as created: $(./xmlquery --value CLM_FORCE_COLDSTART)   (scam_mandatory without the cold start: off)"
./xmlchange CLM_FORCE_COLDSTART=off
if [ "$2" = "--full-grid" ]; then
    ./xmlchange CAM_CONFIG_OPTS="$(./xmlquery --value CAM_CONFIG_OPTS) -scam_full_grid"
fi
./xmlchange STOP_OPTION=nsteps,STOP_N=10,JOB_PRIORITY=premium
./xmlchange JOB_WALLCLOCK_TIME=00:30:00 --subgroup case.run
echo "iopfile = '$IOP'" >> user_nl_cam
./case.setup > case.setup.log 2>&1 || { tail -20 case.setup.log; exit 1; }
./preview_namelists > preview.log 2>&1 || { tail -20 preview.log; exit 1; }
echo "== $CASE"
./xmlquery CAM_CONFIG_OPTS,ATM_GRID,RUN_STARTDATE,PTS_LAT,PTS_LON,CLM_FORCE_COLDSTART | grep -E '^\s+[A-Z_]+:'
echo "== configure:"
grep -h -E 'id="(hgrid|scam_iop_hgrid)"' Buildconf/camconf/config_cache.xml | sed -E 's/.*id="([a-z_]+)" value="([^"]*)".*/   \1 = \2/'
echo "== CAM namelist:"
grep -E '^ *(iopfile|ncdata|scm_iop_hgrid|se_ne)\s' CaseDocs/atm_in
echo "== CLM start:"
grep -E '^ *(finidat|use_init_interp|init_interp_method|check_finidat_year_consistency)\s' CaseDocs/lnd_in || echo "   (no finidat in lnd_in: cold start)"
