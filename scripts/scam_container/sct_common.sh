# sct_common.sh -- sourced by the sct_*.sh scripts: resolve a test id or directory.
SCT_TN=SCT_D_Ln48.ne30_ne30_mg17.F2000climo_SROF.derecho_intel.cam-scm_prep_ERAnudge_derecho
SCT_SCR=/glade/derecho/scratch/jet
SCT_CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
SCT_BL=/glade/derecho/scratch/jet/scam_baselines      # personal baselines (not the official ones)
sct_dir() {   # sct_dir [ID|DIR] -> test directory (default id sctc01)
    local id=${1:-sctc01} d
    case "$id" in /*) echo "$id"; return ;; esac
    # with baselines create_test inserts .G/.C/.GC before the id: <test>.G.<id>
    for d in "$SCT_SCR/$SCT_TN.$id" "$SCT_SCR/$SCT_TN".*."$id"; do
        [ -d "$d" ] && { echo "$d"; return; }
    done
    echo "$SCT_SCR/$SCT_TN.$id"
}
