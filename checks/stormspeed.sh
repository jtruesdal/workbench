#!/bin/bash
# stormspeed: what we are waiting on (updated at each checkpoint). Read-only.
# ss.07 = cam6_4_219 merged into stormspeed (branch cam6_4_219_update, 3cb84acb) + izumi gate entries.
# All finished results so far are explained (see handoffs/2026-11-07_stormspeed.md); only Derecho Intel tests pending.
. "$(dirname "$0")/lib.sh.inc"
case "$1" in
derecho)
  jobs_here
  T=/glade/derecho/scratch/jet/tests
  echo "aux_cam intel vs cam6_4_219 (still pending: mpasa120 F2000climo, F1850C_MTso, ARCTIC/CONUS, PC6, ... ):"
  cs $T/stormspeed_3cb84acb.aux_cam.intel/cs.status.ss07_intel "no PEND; NLFAIL=+stream_ndep_mapalgo with BASELINE PASS; FKESSLER thetal + SHM: missing baseline; QPC7 rttov MODEL_BUILD FAIL (CAM RTTOV path); FX2000 ERS may fail (#113)"
  echo "gate intel vs ss.06 (pending: ne30 ERP/ERS F2000climo, ERS ne30pg2, SMS FHISTC_MTso):"
  cs $T/stormspeed_3cb84acb.aux_cam_e3sm.intel/cs.status.ss07_e3sm_intel "no PEND; FHISTC/F2000climo DIFF (cam6_4_213/219) with NL -clubb_do_icesuper,-clubb_do_liqsupersat; QPC6 BFB; FKESSLER missing-files (DGLC)"
  echo "for one line per non-PASS test: python3 ~/ss_tools/classify_tests.py <testroot> <testid>"
  ;;
izumi)
  jobs_here
  echo "ss.07 izumi runs all finished and explained (aux_cam gnu/nag, gate gnu/nag/intel); nothing pending."
  ;;
esac
