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
  echo "NVHPC GPU build path (OpenACC + Kokkos), expect RUN PASS:"
  cs /glade/derecho/scratch/jet/cs.status.nvgpu1 "_acc case: MODEL_BUILD PASS 2026-11-18; plain case FAIL by design (dropped)"
  echo "GPU step 1+2a remap shadow check (gfr2), expect roundoff-level diffs:"
  zgrep -h -A1 "gfr_device_check" /glade/derecho/scratch/jet/SMS_Ln9*gfrcheck*.gfr2/run/atm.log.* 2>/dev/null | head -8 \
    || echo "    (no atm.log yet)"
  ;;
izumi)
  echo "    (nothing on Izumi)"
  ;;
esac
