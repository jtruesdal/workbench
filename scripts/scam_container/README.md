# scam-container helper scripts

Copies of the helpers used on Derecho from `~/ss_tools`. To refresh that directory:
`cp ~/workbench/scripts/scam_container/* ~/ss_tools/`. All use absolute paths internally.

| Script | Use |
|---|---|
| `sct_common.sh` | sourced by the `sct_*` scripts: test name, paths, `sct_dir ID` |
| `sct_create.sh ID` | `create_test --no-run` of the SCAM `SCT` test (run through `qcmd`) |
| `sct_submit.sh ID` | check the column handoff (3D global, SCAM at Manus), set walltime/priority, submit |
| `check_sct.sh [ID]` | queue, `RUN`/`COMPARE` status, `TDIFF`/`QDIFF` line, CAMIOP file and its `scm_*` fields |
| `sct_errors.sh [ID]` | first errors and log tails of the 3D (`run/`) and SCAM (`run/case2run/`) halves |
| `profile_tree.py CASE [REGION ...]` | timer subtrees from a case's newest `cesm.ESMF_Profile.summary` |
| `compare_fracs.py [TESTDIR]` | land/ocean fractions at Manus/Nauru/Darwin: domain file vs the 3D run |
| `arm97_setup.sh` | create the ARM97 observed-IOP SCAM case at ne30 (container automatically) |
