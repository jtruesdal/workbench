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
  echo "stormspeed_sima step 1 (phys_cols_t), done 2026-11-16:"
  cs /glade/derecho/scratch/jet/cs.status.sima1a "ERS thetal: all PASS, BASELINE cam6_4_219_ss.07_e3sm_intel"
  cs /glade/derecho/scratch/jet/cs.status.sima1b "ERC_D CAM-SE mcsp: NLFAIL only (StormSPEED namelist), BASELINE cam6_4_219_intel PASS"
  echo "Kessler GPU demo outputs: $(ls /glade/derecho/scratch/jet/kessler_gpu_demo/out_*.bin 2>/dev/null | wc -l) files (expect 3)"
  ;;
izumi)
  echo "    (nothing on Izumi)"
  ;;
esac
