#!/bin/bash
# stormspeed: what we are waiting on (updated at each checkpoint). Read-only.
# ss.07 = cam6_4_219 merged into stormspeed (branch cam6_4_219_update, 3cb84acb), plus izumi gate entries.
. "$(dirname "$0")/lib.sh.inc"
case "$1" in
derecho)
  jobs_here
  T=/glade/derecho/scratch/jet/tests
  echo "aux_cam vs cam6_4_219 (soft_eng/cam_baselines):"
  cs $T/stormspeed_3cb84acb.aux_cam.intel/cs.status.ss07_intel "all BASELINE PASS except SHM tests (no CAM baseline) and known intermittent FX2000 ERS (#113)"
  cs $T/stormspeed_3cb84acb.aux_cam.nvhpc/cs.status.ss07_nvhpc "PASS"
  echo "aux_cam_e3sm gate vs ss.06 (stormspeed_70f8354b_e3sm_*), generating stormspeed_3cb84acb_e3sm_*:"
  cs $T/stormspeed_3cb84acb.aux_cam_e3sm.intel/cs.status.ss07_e3sm_intel "35 tests; DIFF possible where cam6_4_219 changed physics (attribute via CAM ChangeLog)"
  cs $T/stormspeed_3cb84acb.aux_cam_e3sm.gnu/cs.status.ss07_e3sm_gnu "16 tests; as for intel"
  ;;
izumi)
  jobs_here
  S=/scratch/cluster/jet
  echo "aux_cam vs cam6_4_219 (gnu: pretag_bl; nag: cacraig's 2026-11-03 run, baseline name 'baselines'):"
  cs $S/stormspeed_3cb84acb.aux_cam.gnu/cs.status.ss07_gnu "BASELINE PASS except SHM (no CAM baseline)"
  cs $S/stormspeed_3cb84acb.aux_cam.nag/cs.status.ss07_nag "BASELINE PASS except SHM"
  echo "izumi gate (first run), generating stormspeed_3cb84acb_e3sm_*:"
  cs $S/stormspeed_3cb84acb.aux_cam_e3sm.gnu/cs.status.ss07_e3sm_gnu "8 tests RUN PASS (no baselines yet)"
  cs $S/stormspeed_3cb84acb.aux_cam_e3sm.nag/cs.status.ss07_e3sm_nag "1 test (SMS_D thetal) RUN PASS"
  cs $S/stormspeed_3cb84acb.aux_cam_e3sm.intel/cs.status.ss07_e3sm_intel "1 test (SMS_D thetal) RUN PASS"
  ;;
esac
