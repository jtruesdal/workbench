#!/bin/bash
# bfb_pair.sh -- the SCT test at Barrow done by hand, as two ordinary cases (no build, no submit):
#   BFB.barrow.3d.01   ne30 F2000climo_SROF, debug, -camiop, ERA5 nudging, 48 tasks, develop queue, 9 steps
#   BFB.barrow.scam.01 the same, as SCAM at the Barrow column (ne3 container, PTS_DOMAINFILE=mesh),
#                      debug, 1 task, 7 steps, IOP file = the 3D case's CAMIOP output
# Mirrors cime_config/SystemTests/sct.py (_case_one_setup / _case_two_setup) and the testmod
# scm_prep_ERAnudge_derecho; TDIFF/QDIFF in the SCAM case's h1 file must be 0.
set -e
CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
TM=$CAM/cime_config/testdefs/testmods_dirs/cam/scm_prep_ERAnudge_derecho
C3=/glade/campaign/cgd/amp/jet/cases/BFB.barrow.3d.01
CS=/glade/campaign/cgd/amp/jet/cases/BFB.barrow.scam.01
LAT=71.184778184951568; LON=204.92322624340073
for c in "$C3" "$CS"; do [ -d "$c" ] && { echo "$c already exists"; exit 1; }; done

common() {   # the nudging testmod, without its CAM_CONFIG_OPTS line
    cp "$TM/user_nl_cam" "$TM/user_nl_clm" "$TM/user_nl_cpl" .
    local ncpl; ncpl=$(./xmlquery --value ATM_NCPL)
    ./xmlchange ROF_NCPL=$ncpl,GLC_NCPL=$ncpl,RUN_STARTDATE=2002-01-01,CAM_NML_USE_CASE=UNSET
    ./xmlchange DEBUG=TRUE,BFBFLAG=TRUE,STOP_OPTION=nsteps,JOB_PRIORITY=premium,JOB_QUEUE=develop --force
    ./xmlchange REST_OPTION=never,DOUT_S=FALSE   # no archiving: SCAM reads the 3D run directory
}

# ---- 3D case (SCT case one)
"$CAM/cime/scripts/create_newcase" --case "$C3" --compset F2000climo_SROF --res ne30_ne30_mg17 \
    --project P93300042 --run-unsupported > "$C3.create.log" 2>&1 || { tail -20 "$C3.create.log"; exit 1; }
cd "$C3"
common
./xmlchange --append CAM_CONFIG_OPTS="-camiop -debug"
for comp in $(./xmlquery --value COMP_CLASSES | tr ',' ' '); do
    ./xmlchange NTASKS_$comp=48,NTHRDS_$comp=1,ROOTPE_$comp=0
done
./xmlchange STOP_N=9
./xmlchange JOB_WALLCLOCK_TIME=02:00:00 --subgroup case.run
printf "inithist = 'CAMIOP'\nscale_dry_air_mass     = 0.0D0\n" >> user_nl_cam
./case.setup > setup.log 2>&1 || { tail -20 setup.log; exit 1; }
RUN3=$(./xmlquery --value RUNDIR)

# ---- SCAM case (SCT case two)
"$CAM/cime/scripts/create_newcase" --case "$CS" --compset F2000climo_SROF --res ne30_ne30_mg17 \
    --project P93300042 --run-unsupported > "$CS.create.log" 2>&1 || { tail -20 "$CS.create.log"; exit 1; }
cd "$CS"
common
./xmlchange --append CAM_CONFIG_OPTS="-debug -scam camfrc"
for comp in $(./xmlquery --value COMP_CLASSES | tr ',' ' '); do
    ./xmlchange NTASKS_$comp=1,NTHRDS_$comp=1,ROOTPE_$comp=0
done
./xmlchange PTS_LAT=$LAT,PTS_LON=$LON,PTS_DOMAINFILE=mesh,STOP_N=7
./xmlchange JOB_WALLCLOCK_TIME=01:00:00 --subgroup case.run
cat >> user_nl_cam << NL
NDENS    = 1,1,1,1,1,1
MFILT    = 1,10000,1,1,1,1
nhtfrq   = 1,1,1,1,1,1
fincl2='T','Q','TDIFF','QDIFF','LANDFRAC'
iopfile = '$RUN3/BFB.barrow.3d.01.cam.h1i.2002-01-01-00000.nc'
inithist = 'YEARLY'
scm_cambfb_mode                = .true.
scm_use_obs_uv         = .true.
scm_relaxation         = .false.
scm_use_3dfrc          = .true.
scale_dry_air_mass     = 0.0D0
NL
./case.setup > setup.log 2>&1 || { tail -20 setup.log; exit 1; }

for c in "$C3" "$CS"; do
    cd "$c"
    ./preview_namelists > preview.log 2>&1 || { tail -20 preview.log; exit 1; }
    echo "== $(basename $c)"
    ./xmlquery CAM_CONFIG_OPTS,DEBUG,NTASKS_ATM,STOP_N,JOB_QUEUE,PTS_LAT,PTS_LON,PTS_DOMAINFILE | grep -E '^\s+[A-Z_]+:'
    grep -h -E 'id="(hgrid|scam_iop_hgrid)"' Buildconf/camconf/config_cache.xml | sed -E 's/.*id="([a-z_]+)" value="([^"]*)".*/   \1 = \2/'
    grep -i -E '^ *(inithist|iopfile|nudge_model|scm_cambfb_mode|fincl2)\s' CaseDocs/atm_in
done
