#!/bin/bash
# stormspeed: what we are waiting on (updated at each checkpoint). Read-only.
# ss.08 = cam6_4_220 (PR #1643, CAM's cam_shmem with true per-rank fallback) merged into stormspeed:
# branch cam6_4_220_update, 0a791fb6. cam6_4_220 is BFB with cam6_4_219, so aux_cam compares against 219.
. "$(dirname "$0")/lib.sh.inc"
case "$1" in
derecho)
  jobs_here
  T=/glade/derecho/scratch/jet/tests
  echo "aux_cam vs cam6_4_219 (soft_eng/cam_baselines):"
  cs $T/ss08.aux_cam.intel/cs.status.ss08_intel "as ss.07: BASELINE PASS where CAM has a baseline; FKESSLER thetal + SHM missing baseline; QPC7 rttov MODEL_BUILD FAIL; NLCOMP stream_ndep_mapalgo maybe"
  cs $T/ss08.aux_cam.nvhpc/cs.status.ss08_nvhpc "BASELINE PASS"
  echo "gate vs cam6_4_219_ss.07 (community/StormSPEED), generating stormspeed_0a791fb6_e3sm_*:"
  cs $T/ss08.gate.intel/cs.status.ss08_e3sm_intel "35 tests, all BFB (NLCOMP at most cam_shmem defaults)"
  cs $T/ss08.gate.gnu/cs.status.ss08_e3sm_gnu "16 tests, all BFB"
  echo "for one line per non-PASS test: python3 ~/ss_tools/classify_tests.py <testroot> <testid>"
  ;;
izumi)
  jobs_here
  S=/scratch/cluster/jet
  echo "aux_cam vs cam6_4_219 (gnu: pretag_bl; nag: cacraig 2026-11-03 'baselines'):"
  cs $S/ss08.aux_cam.gnu/cs.status.ss08_gnu "as ss.07: BASELINE PASS; FKESSLER thetal + SHM missing baseline"
  cs $S/ss08.aux_cam.nag/cs.status.ss08_nag "17 tests BASELINE PASS except SHM; SHM COMPARE_base_private PASS (probe fails on MVAPICH2 2.3.3 -> per-rank code)"
  echo "izumi gate vs ss.07 (stormspeed_3cb84acb_e3sm_*), generating stormspeed_0a791fb6_e3sm_*:"
  cs $S/ss08.gate.gnu/cs.status.ss08_e3sm_gnu "8 tests BFB"
  cs $S/ss08.gate.nag/cs.status.ss08_e3sm_nag "1 test BFB"
  cs $S/ss08.gate.intel/cs.status.ss08_e3sm_intel "1 test BFB"
  ;;
esac
