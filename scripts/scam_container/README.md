# scam-container helper scripts

Copies of the helpers used on Derecho from `~/ss_tools`. To refresh that directory:
`cp ~/workbench/scripts/scam_container/* ~/ss_tools/`. All use absolute paths internally.
Builds go through `qcmd` (Derecho); hand-made SCAM/3D pairs run without archiving (`DOUT_S=FALSE`).

## SCT tests (create, run, check)

| Script | Use |
|---|---|
| `sct_common.sh` | sourced by the `sct_*` scripts: test name, paths, `sct_dir ID` |
| `sct_create.sh ID [--generate NAME \| --compare NAME]` | `create_test --no-run` of the nudged ne30 Manus `SCT` (through `qcmd`) |
| `sct_submit.sh ID` | check the column handoff (3D global, SCAM at the column), set walltime/priority, submit |
| `sct_columns.sh ID` | ne30 column `SCT` set: mesh at Manus/Darwin/Barrow/SGP, domain file at Darwin/SGP |
| `sct_ne3.sh ID` | tiny ne3 `F2000climo` `SCT` set (no nudging, no domain file): ocean, land, coast, two sea-ice coasts |
| `aux_scam.sh ID` | CAM's aux_cam `SCT_D_Ln7` test against an official baseline |
| `check_sct.sh [ID]` | queue, `RUN`/`COMPARE` status, `TDIFF`/`QDIFF` line, CAMIOP file and its `scm_*` fields |
| `sct_errors.sh [ID]` | first errors and log tails of the 3D (`run/`) and SCAM (`run/case2run/`) halves |
| `sct_align.py TESTDIR` | SCAM vs 3D at the column, step by step: first differing field, first-step profiles |
| `iop_profile.py TESTDIR` | first step, level by level: SCAM `T`/`Q`/`PS` vs the CAMIOP file (physics and dynamics column) |

## Hand-made SCAM/3D pairs (Barrow)

| Script | Use |
|---|---|
| `bfb_pair.sh` | create `BFB.barrow.3d.01` (48-task debug ne30 CAMIOP, develop queue) and `BFB.barrow.scam.01` (1-task debug SCAM, mesh) |
| `case_build.sh CASE` | build a case (run through `qcmd`) |
| `bfb_rerun.sh` | rerun the pair with coupler history and CAM tape 4 every step |
| `bfb_nudge.sh on\|off` | rerun the pair with nudging on or off |
| `bfb_steps.py [CASE]` | `TDIFF`/`QDIFF` per step from the SCAM run directory |
| `scam_vs_iop.py CASE ...` | `PHIS` and `TDIFF`/`QDIFF` of a SCAM case against its CAMIOP file |
| `cmp_pair.py [CASE3D CASESCAM]` | every coupler field and CAM tape-4 field at the column, step by step; fractions first |

## Fractions, meshes, inputs

| Script | Use |
|---|---|
| `compare_fracs.py [TESTDIR]` | land/ocean/ice fractions at Manus/Nauru/Darwin/Barrow/SGP: domain file vs the 3D run |
| `frac_esmpy.py [MASK DST [ELEM ...]]` | ESMPy: a column's ocean/land fraction exactly as DOCN/CTSM compute it (weights summed in source order) |
| `ne3_mixed.py CASEDIR` | list a grid's mixed land/ocean points (sea-ice candidates marked) |
| `grid_inputs.sh [GRID ...]` | does `F2000climo_SROF` have all inputs at a grid |
| `compare_runs.py CASE_A CASE_B` | bit-for-bit comparison of two runs' history files |

## Timing

| Script | Use |
|---|---|
| `profile_tree.py CASE [REGION ...]` | timer subtrees from a case's newest `cesm.ESMF_Profile.summary` |
| `ppe_timing.sh` | create the PPE-like timing case (ne30 nudged SCAM on the container, optimized) |
| `arm97_setup.sh NAME [--full-grid]` | ARM97 observed-IOP SCAM case at ne30 (container), warm start |
