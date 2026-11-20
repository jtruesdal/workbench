#!/bin/bash
# stormspeed-unify: what we are waiting on (updated at each checkpoint). Read-only.
. "$(dirname "$0")/lib.sh.inc"
case "$1" in
derecho)
  jobs_here
  C=/glade/campaign/cgd/amp/jet/collections
  echo "branches (local head vs origin; 'ahead N' = not pushed yet):"
  for r in stormspeed_unify.101626 stormspeed_sima.111626 atmos_phys_kessler_gpu.111626; do
    b=$(git -C $C/$r branch --show-current 2>/dev/null)
    printf '    %-34s %-18s %s  %s\n' $r "$b" "$(git -C $C/$r log -1 --format=%h 2>/dev/null)" \
      "$(git -C $C/$r status -sb 2>/dev/null | head -1 | grep -o '\[.*\]')"
  done
  echo "    ccs_config (stormspeed_sima): $(git -C $C/stormspeed_sima.111626/ccs_config branch --show-current 2>/dev/null) $(git -C $C/stormspeed_sima.111626/ccs_config log -1 --format=%h 2>/dev/null)"
  echo "stormspeed_sima steps 1-5 (done, BFB): sima1a..sima6b; latest:"
  cs /glade/derecho/scratch/jet/cs.status.sima6a "ERS thetal: all PASS vs cam6_4_219_ss.07_e3sm_intel"
  cs /glade/derecho/scratch/jet/cs.status.sima6b "ERC_D CAM-SE mcsp: NLFAIL only, BASELINE cam6_4_219_intel PASS"
  echo "HOMME fork (se/homme): $(git -C $C/stormspeed_sima.111626/src/dynamics/se/homme branch --show-current 2>/dev/null) $(git -C $C/stormspeed_sima.111626/src/dynamics/se/homme log -1 --format=%h 2>/dev/null)"
  J=/glade/derecho/scratch/jet
  echo "GPU ladder (FKESSLER ne30pg2, NVHPC, 64 A100s): Check chk1/e1, Use dev1, Resident res2 (all RUN PASS):"
  for t in dev1 res2 e1; do cs $J/cs.status.$t "see handoff 2026-11-20"; done
  echo "Resident vs Use (expect IDENTICAL):"
  [ -f ~/cprnc_use_res2.txt ] && grep diff_test ~/cprnc_use_res2.txt
  echo "Reproducibility rerun of _gfrres.res2 (job 8267191) vs saved copy in ~/res2_run1 (expect IDENTICAL):"
  S=$(ls -d $J/SMS_Ln9*FKESSLER*_gfrres.res2 2>/dev/null)
  if [ -n "$S" ] && ls ~/res2_run1/*.nc >/dev/null 2>&1; then
    P=$(cd $S && ./xmlquery --value CCSM_CPRNC)
    $P ~/res2_run1/*.cam.h0i.*.nc $S/run/*.cam.h0i.*.nc 2>/dev/null | grep diff_test
  fi
  echo "E1b (temperature: remap inputs compared), lines 'E1b' in atm.log:"
  zgrep -h "E1b" $J/SMS_Ln9*FKESSLER*gfrcheck.e1b/run/atm.log.* 2>/dev/null | head -6 || echo "    (no atm.log yet)"
  ;;
izumi)
  echo "    (nothing on Izumi)"
  ;;
esac
