# sct_common.sh -- sourced by the sct_*.sh scripts: resolve a test id or directory.
SCT_TN=SCT_D_Ln48.ne30_ne30_mg17.F2000climo_SROF.derecho_intel.cam-scm_prep_ERAnudge_derecho
SCT_SCR=/glade/derecho/scratch/jet
SCT_CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
sct_dir() {   # sct_dir [ID|DIR] -> test directory (default id sctc01)
    case "${1:-sctc01}" in
        /*) echo "$1" ;;
        *)  echo "$SCT_SCR/$SCT_TN.${1:-sctc01}" ;;
    esac
}
