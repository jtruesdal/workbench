#!/bin/bash
# sct_columns.sh ID -- all column SCT tests in one create_test: Manus/Darwin/Barrow/SGP with
# PTS_DOMAINFILE=mesh, and Darwin/SGP with the domain file (Barrow omitted: the ne30 domain file frac there is not the 3D value) (debug, 9 steps).  Builds and submits.
#   qcmd -l walltime=5:00:00 -- bash ~/ss_tools/sct_columns.sh sctx01 >& ~/ss_tools/sctx01_build.log &
CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
id=${1:?usage: sct_columns.sh ID}
git --no-pager -C "$CAM" log --oneline -1
git --no-pager -C "$CAM/components/cmeps" log --oneline -1
T=SCT_D_Ln9.ne30_ne30_mg17.F2000climo_SROF.derecho_intel.cam-scm_prep_ERAnudge_derecho
exec "$CAM/cime/scripts/create_test" ${T}_mesh_manus ${T}_mesh_darwin ${T}_mesh_barrow ${T}_mesh_sgp \
     ${T}_dom_darwin ${T}_dom_sgp --test-id "$id" --project P93300042
