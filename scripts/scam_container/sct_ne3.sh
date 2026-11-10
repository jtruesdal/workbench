#!/bin/bash
# sct_ne3.sh ID -- tiny debug SCT tests at ne3 (F2000climo_SROF, no nudging, PTS_DOMAINFILE=mesh)
# at five columns: all ocean, all land, land+ocean, and two land+ocean+sea-ice coasts.
#   qcmd -l walltime=5:00:00 -- bash ~/ss_tools/sct_ne3.sh sctn01 >& ~/ss_tools/sctn01_build.log &
CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
id=${1:?usage: sct_ne3.sh ID}
git --no-pager -C "$CAM" log --oneline -1
git --no-pager -C "$CAM/components/cmeps" log --oneline -1
T=SCT_D_Ln9.ne3_ne3_mg37.F2000climo_SROF.derecho_intel.cam-scm_prep_F_ne3
exec "$CAM/cime/scripts/create_test" ${T}_ocean ${T}_land ${T}_coast ${T}_ice_greenland ${T}_ice_canada \
     --test-id "$id" --project P93300042 --queue develop
