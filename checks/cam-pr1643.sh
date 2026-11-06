#!/bin/bash
# cam-pr1643: what we are waiting on (updated at each checkpoint). Read-only.
. "$(dirname "$0")/lib.sh.inc"
# probes <test root> <expectation>: count the cam_shmem probe/mode lines in every run's atm.log.
probes() {
  local d=$1; shift
  echo "cam_shmem lines in $(basename "$d")/*/run/atm.log*   [expect: $*]"
  local out
  out=$(zgrep -h 'MPI-3 shared-memory probe\|node-shared tables enabled\|falling back to per-rank' \
        "$d"/*/run/atm.log.* 2>/dev/null | sed 's/ (.*//' | sort | uniq -c)
  if [ -z "$out" ]; then echo "    (no atm.log lines yet)"; else printf '%s\n' "$out" | sed 's/^/    /'; fi
}
case "$1" in
derecho)
  R=/glade/campaign/cgd/amp/jet/collections/cam_pr1643
  S=/glade/derecho/scratch/jet
  jobs_here
  echo "Checkout $R:   [expect: ceb71700 = jt/pr1643_shmem]"
  git -C $R --no-pager log --oneline -1 2>/dev/null | sed 's/^/    /'
  echo "aux_cam on ceb71700 vs community.OLD/amwg/cam_baselines/cam6_4_218_* (PBS 8081882/8081883):"
  cs $S/aux_cam_intel_20261105142055/cs.status.aux_cam_intel_20261105142055 \
     "56 tests PASS (BFB vs cam6_4_218_intel) except outfrq9s_rttov FAIL (CAM#1745); NLFAIL only for ndep-stream tests"
  cs $S/aux_cam_nvhpc_20261105142055/cs.status.aux_cam_nvhpc_20261105142055 \
     "1 test PASS (BFB vs cam6_4_218_nvhpc)"
  probes $S/aux_cam_intel_20261105142055 "only 'probe PASSED' and 'node-shared tables enabled', equal counts; no FAILED"
  probes $S/aux_cam_nvhpc_20261105142055 "probe PASSED + node-shared tables enabled"
  echo "ESCOMP cam_development / next tag:   [cam6_4_219 = eb11a0b3 (tagged Nov 5, PUMAS); anything newer is news]"
  { git ls-remote https://github.com/ESCOMP/CAM refs/heads/cam_development
    git ls-remote --tags https://github.com/ESCOMP/CAM 'cam6_4_2*' | grep '\^{}' | sort -V -k2 | tail -n 2
  } 2>/dev/null | sed 's/^\(........\)[0-9a-f]*/    \1/; s/\^{}//'
  ;;
izumi)
  R=/project/amp/jet/collections/cam_pr1643
  S=/scratch/cluster/jet
  jobs_here
  echo "Checkout $R:   [expect: ceb71700; suites ran on 1ae0e111 (only description text differs)]"
  git -C $R --no-pager log --oneline -1 2>/dev/null | sed 's/^/    /'
  echo "aux_cam on 1ae0e111 vs /fs/cgd/csm/models/atm/cam/pretag_bl/cam6_4_218_* (jobs 820166/820167):"
  cs $S/aux_cam_gnu_20261105134342/cs.status.aux_cam_gnu_20261105134342 \
     "25 tests all PASS (BFB vs cam6_4_218_gnu); NLFAIL allowed only for ndep-stream tests"
  cs $S/aux_cam_nag_20261105134342/cs.status.aux_cam_nag_20261105134342 \
     "16 tests all PASS (BFB vs cam6_4_218_nag); NLFAIL allowed only for ndep-stream tests"
  probes $S/aux_cam_gnu_20261105134342 "only 'probe PASSED' and 'node-shared tables enabled'"
  probes $S/aux_cam_nag_20261105134342 "only 'probe FAILED' and 'falling back to per-rank'"
  ;;
esac
