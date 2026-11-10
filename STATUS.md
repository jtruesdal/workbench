# Status of workstreams

*Last updated 2026-11-06. Each chat updates its own row at the end of a session.*

| Workstream | Repo / branch | Machine | State | Next step | Latest handoff |
|---|---|---|---|---|---|
| **scam-ppe**: nudged-SCAM PPE workflow and science | `CAM-1` `compassdev` (`tools/ppe`, fb8444a) | Derecho | PPE scripts committed; `tools/ppe/PPE_GUIDE.md` is a draft under review. Derecho tests from 2026-11-03 not yet reviewed: `test2` (1-day `m0000`/`m0001` in `$PR`) and `spin5` (5-day `m0000` in `$P2`). | Review `test2` (`ppe_analyze.py`) and `spin5` (`ppe_spinup.py`); then noise floor with `pertlim`, failure handling, full-node scale test. | `tools/ppe/PPE_GUIDE.md` |
| **scam-container**: SCAM as a single column of the 3D model on a small container grid | `CAM-1` `scam_container` (7a09c7675; `compassdev` = ab7a475a8) | Derecho, Izumi | **BFB proven**: `SCT` `sctc03` (ab7a475a8) PASS end to end; a SCAM case created normally at `ne30_ne30_mg17` runs SE on the ne3np4 container automatically (`buildcpp`; `-scam_iop_hgrid` for namelist defaults). Timers: init 123 s = `pi_chem` 101 s + `pi_prescribed` 21 s; run ~3.4 s/step reading the 25.8 GB global CAMIOP file, physics 0.24 s/step. New 7a09c7675: forcing grid only from `--res`; IOP file is any set of columns (also observed IOPs); nearest IOP and forcing-grid columns chosen once (not yet built in CAM). Building overnight: `sctc04` (`/glade/derecho/scratch/jet/cs.status.sctc04`) and ARM97 case `/glade/campaign/cgd/amp/jet/cases/SCAM.arm97.ne30.01`. | 1) Submit `sctc04` and ARM97; check BFB and the new column log lines; 2) column-only CAMIOP extract (BFB, faster); 3) fast-forward `compassdev`; 4) `compare_fracs.py`, then mesh-only CMEPS single column (drop the domain file); 5) scratch cleanup. | `handoffs/2026-11-06_scam-container.md` |
| **input-stash**: SCAM-friendly input files | workbench `scripts/` | Izumi, Derecho | **Continues in the scam-container chat** (from 2026-11-07). Phase 1 done on Izumi: `/project/amp/jet/scam_stash/f2000_cyc2000/` (32 emission files time-subset, verified identical; `user_nl_cam.stash` with Izumi paths). Not yet measured in a run; no Derecho copy; phase 2 not started. | Measure phase 1 against the `pi_chem`/`pi_prescribed` baseline; Derecho stash; phase 2 (conservative regrid to ne30 + time cut); CTSM `finidat` reuse. | `handoffs/2026-11-07_input-stash.md` |
| **stormspeed**: E3SM nonhydrostatic dycores in CAM | `NCAR/StormSPEED` (`stormspeed` = `cam6_4_211_ss.06`, 4638ab06); forks `jtruesdal/ccs_config_cesm` (nh.06), `jtruesdal/ctsm` (nh.01), `jtruesdal/E3SM` (`stormspeed_homme.01`); wiki github.com/NCAR/StormSPEED/wiki. Checkouts: Derecho and Izumi `collections/stormspeed_ss07` (`cam6_4_219_update`) | Derecho, Izumi | Tagged ss.00-ss.06. **ss.07 (cam6_4_219 update, 3cb84acb) tested; every finished result explained**: aux_cam answers = CAM (NLFAIL only `stream_ndep_mapalgo`; rttov build fails on CAM's moved RTTOV path); gate: FHISTC_LTso answer changes from cam6_4_213/219, QPC6 and FKESSLER BFB; Izumi NAG/GNU and new Izumi gate pass. No PR yet. Waiting on: last Derecho Intel aux_cam and gate ne30 tests. Open issues: #100 #101 #105 #107 #110 #111 #113. | 1) Confirm remaining Derecho Intel tests; 2) ss.07 ChangeLog, PR, review summary, merge, tag `cam6_4_219_ss.07`; 3) copy gate baselines to `/glade/campaign/cesm/community/StormSPEED` with tag names; 4) wiki updates; 5) E3SM issue, RTTOV report, CIRRUS PAT. | `handoffs/2026-11-07_stormspeed.md` |
| **cam-pr1643**: StormSPEED shared-memory fixes into ESCOMP/CAM PR #1643 | `ESCOMP/CAM` PR #1643 = `sjsprecious/CAM` `fix_ne1024_init_oom` = `0356a7d6` (pushed) (Jian's `948c578c` + merge of `cam_development` = `cam6_4_219`) ; PR source `jtruesdal/CAM-1` `pr1643_v2` = `d014170a` (pushed) (4 commits, 8 files); tested history kept as `pr1643_shmem` (`f8f5856a`, same tree `f893f2d0`). Checkouts: Derecho `/glade/campaign/cgd/amp/jet/collections/cam_pr1643` (branches `pr1643_tested`, `fix_ne1024_init_oom`, `pr1643_v2`), Izumi `/project/amp/jet/collections/cam_pr1643` | Derecho, Izumi | **Done:** true fallback (`2370546f`/`d014170a`): when the probe fails or `cam_shmem_force_private` is set, CAM runs the original per-rank code (plain allocate, PIO reads in `tracer_data`/`soil_erod_mod`, no MPI-3 windows); sharing stays on by default (also on GPU: ne30 A/B identical, 0.04 SYPD both). `aux_cam` vs `cam6_4_219` all bit-for-bit: derecho intel 55/56 (rttov pre-existing), nvhpc 1/1, izumi gnu 25/25 (shared), nag 16/16 (original paths); NLFAIL only `stream_ndep_mapalgo`. Izumi probe failure explained: MVAPICH2 2.3.3 (Intel, NAG) has the `MPI_Win_shared_query` bad-baseptr bug fixed in 2.3.4; GNU uses 2.3.7. | 1) open PR `jtruesdal/CAM-1:pr1643_v2` -> `sjsprecious:fix_ne1024_init_oom` with `pr1643_PR_description.md` (in the handoff); 2) Jian (or user) merges; CAM SE review of #1643; ChangeLog (draft in handoff), merge to `cam_development`, tag. | `handoffs/2026-11-10_cam-pr1643.md` |
| **housekeeping** | various | Derecho, Izumi, laptop | Derecho `$CAMROOT` has an uncommitted compset `FHISTC_LTso_SROF` in `config_compsets.xml`. Older Derecho checkout `collections/cam6_4_207_compass.100926` (at 8e0952a) holds untracked `scm_prep_ERAnudge_global`, `sct.py.manus`. Old Derecho `tools/ppe` copy at `collections/tools_ppe_old_derecho`. Upstream CICE issue for the single-column TLAT/TLON fix not yet filed. Izumi `ndgiz01` SCT test superseded by Derecho. tmux session `scam` is on derecho2 (laptop alias `dtmux`). | Decide where the compset goes; retire or update the old checkout; delete the old `tools/ppe` copy; file the CICE issue. | — |

## Inbox

Notes left by one chat for another workstream. The receiving chat clears its items.

- **scam-ppe ← scam-container:** the 3D (global) run fails at the first tape-3 write when
  `fincl3` holds `Nudge_*`, `Target_*`, `PS`, `num_a*` (PIO "NetCDF: Index exceeds dimension
  bound", `pio_getput_int.c`; seen on Izumi and Derecho). `fincl3` was dropped from the
  `scm_prep_ERAnudge_*` testmods; SCAM writes the same fields without trouble. Root cause
  still unknown; matters if the PPE wants nudging diagnostics from 3D runs.
- **scam-ppe ← scam-container:** production CAMIOP output cannot be global every step
  (~0.5 GB/step at ne30). Plan column-only IOP output for the chosen sites. SCAM's reader now
  accepts any set of columns (`scam_container` 7a09c7675, pending its first CAM build), and a
  single-column file should also remove most of SCAM's per-step cost (~3.4 s/step reading the
  global file). `compassdev` is now ab7a475a8: PPE members can run on the ne3 container
  (create the SCAM case at the forcing resolution; `buildcpp` does the rest).
- **input-stash ← scam-container:** measured in the ne3 container SCAM (debug, `bc992bf` timers):
  `cam_init_phys_init` 123 s, of which `pi_chem` 101 s (chemistry/emission reader setup) and
  `pi_prescribed` 21 s (prescribed ozone, aerosols, volcanic and stratospheric aerosols). That is
  the baseline for measuring the stash; `profile_tree.py` (`scripts/scam_container/`) prints it.
- **housekeeping ← scam-container:** scratch: `sctc01`, `sctc02`, `sctc03` test directories each hold a
  25.8 GB CAMIOP file (keep one, e.g. `sctc03`); cases `SCAM.ne3container.Manus.01` and
  `SCAM.ne30twin.Manus.01` in `/glade/campaign/cgd/amp/jet/cases/` are superseded.
- **housekeeping ← stormspeed:** Izumi interactive job 820063 is orphaned on i011: `pbs_mom` is
  not running there (only `trqauthd`), so `qdel` fails ("Server could not connect to MOM"). A
  help@ucar.edu ticket was drafted (restart `pbs_mom` on i011, purge 820063); check it was sent and resolved. (820063 no longer in `qstat` as of Nov 5: probably resolved.)
- **housekeeping ← stormspeed:** decide whether to retire the path variables in `scam_env.csh`
  (`CAMROOT`, `TD`, `CC`, `PR`, `P2`, ...) now that WORKFLOW.md asks for absolute paths; the
  scam-ppe and scam-container rows still refer to `$PR`, `$P2`, `$CC`, `$TD`.
- **stormspeed ← cam-pr1643:** PR #1643 tests passed (all bit-for-bit vs cam6_4_219). For StormSPEED's shmem code, the
  final ESCOMP version is `jtruesdal/CAM-1` `pr1643_v2` (`42e83fd5` probe/fallback, `6061be46` + `a54d16ea` docs,
  `d014170a` **true fallback**: original per-rank code when sharing is off; adds `cam_shmem_enabled()`, PIO path back in
  `soil_erod_mod`, `tracer_data` gated). StormSPEED keeps its own `SHM` test. Cause of #106 found: izumi Intel/NAG use
  MVAPICH2 2.3.3 (bad baseptr from `MPI_Win_shared_query`, fixed in 2.3.4); GNU uses 2.3.7. Comment text for #106 is in
  `handoffs/2026-11-10_cam-pr1643.md`.
- **stormspeed ← cam-pr1643:** ESCOMP `ccs_config_cesm1.0.93` lacks `-heap-arrays 64` for Izumi Intel; plain
  ESCOMP CAM (FHISTC_LTso, debug) segfaults during init there, same place as before StormSPEED's `nh.04` fix.
  Izumi Intel is not a CAM regression platform, so low priority; consider upstreaming to ESMCI `ccs_config`.
- **housekeeping ← cam-pr1643:** Derecho CAM baselines moved to `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`
  (`cam6_4_219` updated `archive_baseline.sh`). That location has no `cam6_4_217`/`218`; the full older set is at
  `/glade/campaign/cesm/community.OLD/amwg/cam_baselines`. Update notes that cite the old
  `/glade/campaign/cesm/community/amwg/cam_baselines` path; ask the CAM SE team whether 217/218 will be copied over.
- **housekeeping ← cam-pr1643:** izumi Intel and NAG MPI modules (`mpi/2.3.3/intel/20.0.1`, `mpi/2.3.3/nag/7.0`) are
  MVAPICH2 2.3.3, which has the MPI-3 shared-window bug fixed in 2.3.4; GNU uses 2.3.7. Ask CGD sysadmins about 2.3.7
  builds for Intel/NAG (then `ccs_config` module change). Not needed for CAM: the probe falls back to the original code.
- **housekeeping ← cam-pr1643:** `test_driver.sh` runs `create_test --retry 2`; on derecho its retry pass resubmitted
  tests still waiting in the queue, so two jobs ran in one case (seen Nov 5: CONUS, GPU test). For CAM PR testing the
  stormspeed procedure (`create_test` in `qcmd`, no `--retry`, `-j 8`) avoided that and the build-node OOM kills.
