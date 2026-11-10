#!/bin/bash
# grid_inputs.sh [GRID ...] -- can F2000climo_SROF run at these grids? Creates a throwaway case per
# grid in scratch (no build), generates the namelists and lists the input files CIME cannot find.
# Default grids: ne3_ne3_mg37 ne5_ne5_mg37
CAM=/glade/campaign/cgd/amp/jet/collections/cam6_4_207_compassdev.102726
for g in ${@:-ne3_ne3_mg37 ne5_ne5_mg37}; do
    c=/glade/derecho/scratch/jet/inputcheck.F2000climo_SROF.$g
    echo "==================== $g   ($c)"
    rm -rf "$c"
    "$CAM/cime/scripts/create_newcase" --case "$c" --compset F2000climo_SROF --res "$g" \
        --project P93300042 --run-unsupported > "$c.create.log" 2>&1 \
        || { echo "create_newcase failed:"; tail -5 "$c.create.log"; continue; }
    cd "$c" || continue
    ./case.setup > setup.log 2>&1 || { echo "case.setup failed:"; tail -5 setup.log; continue; }
    ./preview_namelists > preview.log 2>&1 || { echo "preview_namelists failed:"; grep -m5 -i error preview.log; continue; }
    echo "-- key inputs"
    grep -h -E '^ *(ncdata|bnd_topo|drydep_srf_file)\s' CaseDocs/atm_in
    grep -h -E '^ *(fsurdat|finidat|flanduse_timeseries)\s' CaseDocs/lnd_in
    grep -h -E '^ *(ice_ic|grid_file|kmt_file)\s' CaseDocs/ice_in 2>/dev/null
    echo "-- missing input files (check_input_data)"
    ./check_input_data > cid.log 2>&1
    grep -i -E 'missing|not found|cannot' cid.log | sort -u | head -30
    grep -q -i -E 'missing|not found' cid.log || echo "   none missing"
done
