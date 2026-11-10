#!/bin/bash
# cam-pr1643: what we are waiting on (updated at each checkpoint). Read-only.
. "$(dirname "$0")/lib.sh.inc"
# head <label> <repo url> <ref> <expectation>: short hash of a remote ref
head8() {
  echo "$1   [expect: $4]"
  git ls-remote "$2" "$3" 2>/dev/null | sed 's/^\(........\)[0-9a-f]*/    \1/'
}
case "$1" in
derecho)
  R=/glade/campaign/cgd/amp/jet/collections/cam_pr1643
  jobs_here
  echo "Checkout $R:   [expect: pr1643_tested f8f5856a, fix_ne1024_init_oom 0356a7d6, pr1643_v2 d014170a]"
  git -C $R --no-pager branch -v --no-abbrev 2>/dev/null | cut -c1-110 | sed 's/^/    /'
  head8 "Jian's PR branch (sjsprecious/CAM fix_ne1024_init_oom)" https://github.com/sjsprecious/CAM \
        refs/heads/fix_ne1024_init_oom "0356a7d6 (cam_development merge); d014170a or a merge commit once the PR into it is merged"
  head8 "PR source (jtruesdal/CAM-1 pr1643_v2)" https://github.com/jtruesdal/CAM-1 refs/heads/pr1643_v2 \
        "d014170a"
  echo "ESCOMP cam_development / newest tags:   [cam6_4_219 = eb11a0b3; anything newer is news]"
  { git ls-remote https://github.com/ESCOMP/CAM refs/heads/cam_development
    git ls-remote --tags https://github.com/ESCOMP/CAM 'cam6_4_2*' | grep '\^{}' | sort -V -k2 | tail -n 2
  } 2>/dev/null | sed 's/^\(........\)[0-9a-f]*/    \1/; s/\^{}//'
  ;;
izumi)
  jobs_here
  echo "Nothing pending on izumi for cam-pr1643 (gnu/nag aux_cam vs cam6_4_219 done, all bit-for-bit)."
  ;;
esac
