# scam_env.csh -- shell environment for the SCAM / CAM work on Derecho and Izumi.
# Usage (tcsh):  source ~/workbench/scam_env.csh
# Sets the same variable names on both machines; only the paths differ.
# Edit the "current work" block when a test or case changes, commit, pull on
# the other machine.

set _h = `hostname`

if ( "$_h" =~ derecho* || "$_h" =~ dec* || "$_h" =~ crhtc* ) then
   setenv WB_MACHINE derecho
   setenv PBS_ACCOUNT P93300042
   set SCRATCH = /glade/derecho/scratch/$USER
   set CASES   = /glade/campaign/cgd/amp/jet/cases
   set CAMROOT = /glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
   set NUDGE   = /glade/campaign/cesm/stormspeed/ERA5_nudging_input_1h/2002-2008/ne30np4/L32
   set MACHSFX = derecho_intel
else if ( "$_h" =~ izumi* || "$_h" =~ i0* ) then
   setenv WB_MACHINE izumi
   set SCRATCH = /scratch/cluster/$USER
   set CASES   = /project/amp/jet/cases        # check: Izumi case directory
   set CAMROOT = /project/amp/jet/collections/cam6_4_207_compass.100926
   set NUDGE   = /project/amp/jet/nudging/ERA5_nudging_input_1h/2002-2008/ne30np4/L32
   set MACHSFX = izumi_intel
else
   echo "scam_env.csh: unknown host $_h; nothing set"
   goto _wb_end
endif

set PP = $CAMROOT/tools/ppe
set WB = ~/workbench

# ---- current work (edit as tests/cases change) -------------------------
# SCT regression test of scam_container (3D CAMIOP + ne30 SCAM)
set TDNAME = SCT_D_Ln48.ne30_ne30_mg17.F2000climo_SROF
if ( $WB_MACHINE == derecho ) then
   set TD = $SCRATCH/${TDNAME}.${MACHSFX}.cam-scm_prep_ERAnudge_derecho.sctc01
else
   set TD = $SCRATCH/${TDNAME}.${MACHSFX}.cam-scm_prep_ERAnudge_izumi.ndgiz01
endif
# ne3 "container" SCAM case (Derecho)
set CC = $CASES/SCAM.ne3container.Manus.01
# PPE areas (Derecho)
set PR = $SCRATCH/scam_ppe/manus_5d
set P2 = $SCRATCH/scam_ppe/manus_spin
# -------------------------------------------------------------------------

# Python: the workbench conda environment (see environment.yml)
alias scampy 'conda activate scamppe'
# tmux: attach to the project session, or create it
alias scamtmux 'tmux new -A -s scam'
# Turn off a stuck bracketed-paste mode (pastes arrive as 00~ ... 01~)
alias fixpaste 'printf "\033[?2004l"'
if ($?prompt) then
    echo "scam_env: $WB_MACHINE  CAMROOT=$CAMROOT"
    echo "          TD=$TD:t"
    echo "          CC=$CC:t"
endif
_wb_end:
unset _h
