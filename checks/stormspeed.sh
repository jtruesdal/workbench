#!/bin/bash
# stormspeed: what we are waiting on (updated at each checkpoint). Read-only.
. "$(dirname "$0")/lib.sh.inc"
case "$1" in
derecho)
  jobs_here
  echo "ss.06 gate on nag_portability 70f8354b vs ss.04 (qcmd 8084786/8084787):"
  cs /glade/derecho/scratch/jet/tests/stormspeed_70f8354b.aux_cam_e3sm.intel/cs.status.ss06_intel "35 PASS (BFB vs cam6_4_211_ss.04_e3sm_intel)"
  cs /glade/derecho/scratch/jet/tests/stormspeed_70f8354b.aux_cam_e3sm.gnu/cs.status.ss06_gnu "16 PASS (BFB vs cam6_4_211_ss.04_e3sm_gnu)"
  ;;
izumi)
  jobs_here
  echo "Izumi probes (overrides version eba02b95, same code as 70f8354b):"
  cs /scratch/cluster/jet/stormspeed_eba02b95.izumi/cs.status.ss06gnu "12 tests; ERS_Ln9 ne3pg3 thetal (+_hy) may FAIL (#110); others PASS"
  cs /scratch/cluster/jet/stormspeed_eba02b95.izumi/cs.status.ss06intel "1 test, intel debug thetal: PASS unless #107-like"
  cs /scratch/cluster/jet/stormspeed_07aebdd2.nag/cs.status.ss06nag3 "NAG non-debug thetal_kokkos: MODEL_BUILD and RUN PASS"
  ;;
esac
