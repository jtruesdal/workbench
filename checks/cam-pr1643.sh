#!/bin/bash
# cam-pr1643: done (cam6_4_220 tagged 2026-11-11). Read-only reminder of the final state.
. "$(dirname "$0")/lib.sh.inc"
case "$1" in
derecho)
  echo "cam-pr1643 is done: ESCOMP/CAM cam6_4_220 (00e7349f).   [expect: tag present; newer tags are other PRs]"
  git ls-remote --tags https://github.com/ESCOMP/CAM 'cam6_4_22*' 2>/dev/null | grep '\^{}' \
    | sed 's/^\(........\)[0-9a-f]*/    \1/; s/\^{}//'
  ;;
izumi)
  echo "cam-pr1643: nothing pending on izumi."
  ;;
esac
