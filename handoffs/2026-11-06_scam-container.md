# scam-container handoff, 2026-11-06

## Where it stands

SCAM can run as a single column of the 3D model on a small "container" dynamics grid, bit for bit.
A SCAM case is created the ordinary way at the forcing resolution (e.g. `--res ne30_ne30_mg17` with a
`%SCAM...` compset); CAM's `buildcpp` runs SE on `ne3np4` and passes `-scam_iop_hgrid ne30np4`, so the
namelist, meshes, domain file and surface components are all those of ne30. Proven by `SCT` test
`sctc03` (ab7a475a8): `RUN` and `COMPARE_base_default` PASS, `QDIFF,TDIFF: PASS` for the nudged ne30
Manus column. `compassdev` was fast-forwarded to `ab7a475a8`.

Branch `scam_container` (`jtruesdal/CAM-1`) is now at `7a09c7675`, two commits past `compassdev`:
`bc992bf45` (timers) and `7a09c7675` (forcing grid from the case; IOP file is any set of columns).
`7a09c7675` compiles in a sandbox with stub modules; it has not been built in CAM yet.

## Design (agreed)

- The forcing grid comes only from the case resolution (`--res` -> `ATM_GRID` -> `scm_iop_hgrid`),
  never from the IOP file. The IOP file is just a set of columns: one, a subset, a whole grid, or an
  observed IOP (ARM97) with no grid.
- Two nearest-column choices, once at startup (`scamMod`): the IOP column (forcing; exact geometry
  `scm_clat/scm_clon/scm_area` if present) and the forcing-grid column (from `ncdata`/`bnd_topo`
  coordinates; used for `ncdata`, topo, nudging, other forcing-grid inputs). No exact-match
  requirement: the log reports both and their distance; a warning in BFB mode if they differ; a warning
  if the IOP file's `ne`/`np` global attributes differ from the forcing grid.
- Physics geometry: IOP file's exact geometry if present; otherwise, on a container grid, the
  forcing-grid column's (so ARM97 gets its own solar geometry, not a distant ne3 point).
- The container rule in `buildcpp` (`SCAM_CONTAINER_HGRID = {"se": "ne3np4"}`) is temporary per
  dycore; opt out with `-scam_full_grid` in `CAM_CONFIG_OPTS`. `-scam_iop_hgrid` stays as a feature.
- Domain file: to be removed (mesh-only CMEPS single-column mode, with land/ocean fractions computed
  the way the 3D run does). Until then `PTS_DOMAINFILE` comes from the grid default (ne30: set).

## Commits on top of compassdev's old head fb8444a

| Commit | What | After the single-column refactor |
|---|---|---|
| 677da86 | physics side: read grid by file size, exact IOP column geometry (`scm_clat/scm_clon/scm_area` in CAMIOP output) | revisit |
| 1724a8a | dynamics side: read the IOP column through the `SCM` grid, copy to every element | remove |
| d4b65c0, e5382d5 | Derecho nudging testmod; drop `fincl3` | keep |
| b268622 | skip `compute_adv_tends_xyz` in SCAM; `cam_init` timers | remove skip / keep timers |
| 8625938, 31baabc | grid sizes from the variables' own dimensions (`ncol` vs `ncol_d`) | remove |
| 9394356 | SCM-grid reads into a one-element buffer | remove |
| beca17e | SCM grid column dimension named after the initial file's | remove |
| 311937b | skip `check_file_layout` for constituents in SCAM | remove |
| a323a74 | `configure -scam_iop_hgrid` (IOP-grid namelist defaults, `se_*` from the model grid) | keep |
| ab7a475 | `buildcpp`: SE SCAM cases at a 3D resolution run on the ne3np4 container | delete per dycore |
| bc992bf | timers: SCAM IOP reads, `phys_init` groups | keep |
| 7a09c76 | forcing grid from the case; IOP file any set of columns; one column search per file | keep |

## Timing (ne3 container, debug build, 5 steps, before 7a09c76)

Initialization ~123 s in `cam_init_phys_init`: `pi_chem` 101 s, `pi_prescribed` 21 s (input-data
readers: the input stash should remove most of it). Run ~3.6 s/step, almost all IOP reading:
`scm_readiopdata1` ~3.4 s per call vs `scm_readiopdata2` ~0.23 s for the same records later in the step
(cold, strided reads of one column from the 25.8 GB global CAMIOP file). Physics ~0.24 s/step.
Fix: column-only IOP files (now accepted by 7a09c76) plus one column search per file (in 7a09c76).

## In flight (2026-11-06 evening)

- `sctc04`: `SCT` build from 7a09c7675 (qcmd, `--no-run`); log `~/ss_tools/sctc04_build.log`.
- `/glade/campaign/cgd/amp/jet/cases/SCAM.arm97.ne30.01`: ARM97 observed IOP
  (`/glade/p/cesmdata/inputdata/atm/cam/scam/iop/ARM97_4scam_c180703.nc`), `FSCAMARM97` at
  `ne30_ne30_mg17`, 10 steps; config check showed `hgrid ne3np4`, `scam_iop_hgrid ne30np4`, ne30
  `ncdata`/`bnd_topo`, `se_ne 3`. Build via qcmd; log `~/ss_tools/arm97_build.log`.

## Next

1. Submit `sctc04` (`bash ~/ss_tools/sct_submit.sh sctc04`) and ARM97
   (`bash -c "cd /glade/campaign/cgd/amp/jet/cases/SCAM.arm97.ne30.01 && ./case.submit"`).
2. `sctc04`: PASS, and `atm.log` of the SCAM half shows `scm_set_forcing_column` with distance 0.
   ARM97: runs; `atm.log` reports the ARM site, the nearest ne30 column and their distance.
3. Column-only CAMIOP extract (script with `ncks`, keep global attributes) -> same BFB, less time per step.
4. Fast-forward `compassdev` to `scam_container` once `sctc04` passes.
5. Domain-file removal: `compare_fracs.py` (domain `frac` vs the 3D run's CTSM/mediator fractions),
   then the CMEPS mesh-only single-column mode (needs a CMEPS fork).
6. Clean up: `sctc01`-`sctc03` each keep a 25.8 GB CAMIOP file in scratch; the hand-built
   `SCAM.ne3container.Manus.01` and `SCAM.ne30twin.Manus.01` cases are superseded.

Helpers: `scripts/scam_container/` (copies of `~/ss_tools` on Derecho).
