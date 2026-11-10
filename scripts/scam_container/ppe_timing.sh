#!/bin/bash
# ppe_timing.sh -- create the nudged ne30 SCAM case the way a PPE member is set up, as an ordinary
# (non-test) case: F2000climo_SROF at ne30_ne30_mg17, -scam camfrc (ne3 container automatically),
# the ERA5 nudging testmod's namelists, the sctc05 CAMIOP file, optimized build, detailed timers,
# 48 steps.  Mirrors what the SCT test does for its SCAM case, minus the test's every-step history.
# Does not build or submit.
set -e
source "$HOME/ss_tools/sct_common.sh"
NEW=/glade/campaign/cgd/amp/jet/cases/SCAM.ne30nudge.timing.01
TM=$SCT_CAM/cime_config/testdefs/testmods_dirs/cam/scm_prep_ERAnudge_derecho
IOP=$(ls "$SCT_SCR/$SCT_TN".*sctc05/run/*.cam.h1i.2002-01-01-00000.nc 2>/dev/null | head -1)
[ -n "$IOP" ] || { echo "sctc05 CAMIOP file not found"; exit 1; }
[ -d "$NEW" ] && { echo "$NEW already exists"; exit 1; }
"$SCT_CAM/cime/scripts/create_newcase" --case "$NEW" --compset F2000climo_SROF --res ne30_ne30_mg17 \
    --project P93300042 --run-unsupported > "$NEW.create.log" 2>&1 || { tail -20 "$NEW.create.log"; exit 1; }
cd "$NEW"
# the testmod's namelists (nudging etc.) and its xml settings, without -camiop/-debug
cp "$TM/user_nl_cam" "$TM/user_nl_clm" "$TM/user_nl_cpl" .
NCPL=$(./xmlquery --value ATM_NCPL)
./xmlchange ROF_NCPL=$NCPL,GLC_NCPL=$NCPL,RUN_STARTDATE=2002-01-01,CAM_NML_USE_CASE=UNSET
./xmlchange PTS_LAT=-1.83777152363091,PTS_LON=147.82917960675
# what SCT does for its SCAM case
./xmlchange CAM_CONFIG_OPTS="$(./xmlquery --value CAM_CONFIG_OPTS) -scam camfrc"
for c in $(./xmlquery --value COMP_CLASSES | tr ',' ' '); do
    ./xmlchange NTASKS_$c=1,NTHRDS_$c=1,ROOTPE_$c=0
done
./xmlchange BFBFLAG=TRUE,REST_OPTION=never
cat >> user_nl_cam << NL
iopfile = '$IOP'
scm_cambfb_mode = .true.
scm_use_obs_uv  = .true.
scm_relaxation  = .false.
scm_use_3dfrc   = .true.
scale_dry_air_mass = 0.0D0
NL
# timing run: optimized, detailed timers, one model day
./xmlchange DEBUG=FALSE,TIMER_LEVEL=10,STOP_OPTION=nsteps,STOP_N=48,JOB_PRIORITY=premium
./xmlchange JOB_WALLCLOCK_TIME=00:30:00 --subgroup case.run
./case.setup > setup.log 2>&1 || { tail -20 setup.log; exit 1; }
./preview_namelists > preview.log 2>&1 || { tail -20 preview.log; exit 1; }
echo "== $NEW"
./xmlquery CAM_CONFIG_OPTS,ATM_GRID,DEBUG,TIMER_LEVEL,STOP_N,CLM_FORCE_COLDSTART,NTASKS_ATM,PTS_LAT,PTS_LON | grep -E '^\s+[A-Z_]+:'
grep -h -E 'id="(hgrid|scam_iop_hgrid)"' Buildconf/camconf/config_cache.xml | sed -E 's/.*id="([a-z_]+)" value="([^"]*)".*/   \1 = \2/'
grep -i -E '^ *(iopfile|scm_iop_hgrid|nudge_model|nudge_path|nudge_file_template|scm_cambfb_mode)\s' CaseDocs/atm_in
ls -l "$IOP"
