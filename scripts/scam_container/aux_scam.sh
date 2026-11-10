#!/bin/bash
# aux_scam.sh ID -- CAM's own SCAM regression test from aux_cam (SCAM on ne3, classic path: no
# container), compared with the official cam6_4_207 Intel baseline.  Compare only, never generate.
# Builds, then submits the run.  Run through qcmd:
#   qcmd -l walltime=3:00:00 -- bash ~/ss_tools/aux_scam.sh scamr01 >& ~/ss_tools/scamr01_build.log &
source "$(dirname "$0")/sct_common.sh"
id=${1:?usage: aux_scam.sh ID}
BL_ROOT=/glade/campaign/cesm/community.OLD/amwg/cam_baselines
git --no-pager -C "$SCT_CAM" log --oneline -1
exec "$SCT_CAM/cime/scripts/create_test" SCT_D_Ln7.ne3_ne3_mg37.QPC5.derecho_intel.cam-scm_prep \
     --test-id "$id" --project P93300042 --baseline-root "$BL_ROOT" -c cam6_4_207_intel
