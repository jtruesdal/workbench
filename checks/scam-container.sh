#!/bin/bash
# scam-container: what we are waiting on (updated at each checkpoint). Read-only.
. "$(dirname "$0")/lib.sh.inc"
S=/glade/derecho/scratch/jet
T=SCT_D_Ln48.ne30_ne30_mg17.F2000climo_SROF.derecho_intel.cam-scm_prep_ERAnudge_derecho
A=/glade/campaign/cgd/amp/jet/cases/SCAM.arm97.ne30.01
case "$1" in
derecho)
  jobs_here
  echo "Builds started 2026-11-06 evening from scam_container 7a09c7675 (forcing grid from --res):"
  cs $S/cs.status.sctc04 "MODEL_BUILD PASS; RUN PEND (built --no-run: submit with sct_submit.sh sctc04)"
  echo "sctc04 build log (last lines):   [expect: 'PASS ... MODEL_BUILD']"
  if [ -f $HOME/ss_tools/sctc04_build.log ]; then
    tail -n 3 $HOME/ss_tools/sctc04_build.log | sed 's/^/    /'
  else echo "    (no log)"; fi
  echo "ARM97 container case build ($A):   [expect: case.build success]"
  if [ -f $A/CaseStatus ]; then grep -h 'case.build' $A/CaseStatus | tail -n 1 | sed 's/^/    /'
  else echo "    (no CaseStatus)"; fi
  echo "ARM97 runs since build:   [expect: none yet; submit in the morning]"
  [ -f $A/CaseStatus ] && grep -h 'case.run' $A/CaseStatus | tail -n 1 | sed 's/^/    /'
  echo "Earlier SCT tests:"
  cs $S/cs.status.sctc02 "PASS (ne30 regression of 31baabca7; never checked)"
  cs $S/cs.status.sctc03 "PASS (end-to-end container, ab7a475a8; passed 2026-11-05)"
  ;;
izumi)
  echo "nothing waiting on Izumi; its checkout /project/amp/jet/collections/cam6_4_207_compass.100926"
  echo "needs a git pull of scam_container (7a09c7675) before the next Izumi work:"
  git -C /project/amp/jet/collections/cam6_4_207_compass.100926 --no-pager log --oneline -1 2>/dev/null | sed 's/^/    local: /'
  ;;
esac
