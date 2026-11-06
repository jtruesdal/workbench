# Status of workstreams

*Last updated 2026-11-06. Each chat updates its own row at the end of a session.*

| Workstream | Repo / branch | Machine | State | Next step | Latest handoff |
|---|---|---|---|---|---|
| **scam-ppe**: nudged-SCAM PPE workflow and science | `CAM-1` `compassdev` (`tools/ppe`, fb8444a) | Derecho | PPE scripts committed; `tools/ppe/PPE_GUIDE.md` is a draft under review. Derecho tests from 2026-11-03 not yet reviewed: `test2` (1-day `m0000`/`m0001` in `$PR`) and `spin5` (5-day `m0000` in `$P2`). | Review `test2` (`ppe_analyze.py`) and `spin5` (`ppe_spinup.py`); then noise floor with `pertlim`, failure handling, full-node scale test. | `tools/ppe/PPE_GUIDE.md` |
| **scam-container**: SCAM as a single column of the 3D model on a small container grid | `CAM-1` `scam_container` (7a09c7675; `compassdev` = ab7a475a8) | Derecho, Izumi | **BFB proven**: `SCT` `sctc03` (ab7a475a8) PASS end to end; a SCAM case created normally at `ne30_ne30_mg17` runs SE on the ne3np4 container automatically (`buildcpp`; `-scam_iop_hgrid` for namelist defaults). Timers: init 123 s = `pi_chem` 101 s + `pi_prescribed` 21 s; run ~3.4 s/step reading the 25.8 GB global CAMIOP file, physics 0.24 s/step. New 7a09c7675: forcing grid only from `--res`; IOP file is any set of columns (also observed IOPs); nearest IOP and forcing-grid columns chosen once (not yet built in CAM). Building overnight: `sctc04` (`/glade/derecho/scratch/jet/cs.status.sctc04`) and ARM97 case `/glade/campaign/cgd/amp/jet/cases/SCAM.arm97.ne30.01`. | 1) Submit `sctc04` and ARM97; check BFB and the new column log lines; 2) column-only CAMIOP extract (BFB, faster); 3) fast-forward `compassdev`; 4) `compare_fracs.py`, then mesh-only CMEPS single column (drop the domain file); 5) scratch cleanup. | `handoffs/2026-11-06_scam-container.md` |
| **input-stash**: SCAM-friendly input files | workbench `scripts/` | Izumi (Derecho next) | Phase 1 done on Izumi: `/project/amp/jet/scam_stash/f2000_cyc2000/` (32 emission files time-subset, verified identical). | Measure phase 1 in a run; phase 2 (conservative regrid to ne30 + time cut for strataero, DMS, oxidants, ndep; reuse CTSM `finidat` interpolation). | `handoffs/2026-11-04_scam_speedups.md` |
| **stormspeed**: E3SM nonhydrostatic dycores in CAM | `NCAR/StormSPEED` (`stormspeed` = `cam6_4_211_ss.06`, 4638ab06); forks `jtruesdal/ccs_config_cesm` (`ccs_config_nh`, nh.06), `jtruesdal/ctsm` (nh.01), `jtruesdal/E3SM` (`stormspeed_homme.01`). Checkouts: Derecho `/glade/campaign/cgd/amp/jet/collections/stormspeed_ss07` (`cam6_4_219_update`); Izumi `/project/amp/jet/collections/stormspeed_ss07` (`cam6_4_219_update`) | Derecho, Izumi | Tagged `ss.00`-`ss.06` (`ss.06`: NAG/portability via E3SM fork commit, SENH fixes, ccs_config nh.05; Derecho gate BFB vs ss.04). **`ss.07` in testing**: `cam6_4_219_update` 3cb84acb = cam6_4_219 merged (conflicts only .gitmodules/ccs_config -> `ccs_config_cesm1.0.93_nh.06`; atmos_phys0_34_001, clubb submodule gone) + izumi gnu(8)/nag(1)/intel(1) theta-l tests in `aux_cam_e3sm`. Running: Derecho aux_cam intel/nvhpc vs cam6_4_219 + gate intel/gnu vs ss.06; Izumi aux_cam gnu/nag vs cam6_4_219 + izumi gate (jobs 820214-820218). CAM baselines: Derecho `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`, Izumi `/fs/cgd/csm/models/atm/cam/pretag_bl` (nag 219 not yet there: `/scratch/cluster/cacraig/aux_cam_nag_20261103160711/baselines`). Open: NAG theta-l_kokkos non-debug run fails; #110 also hits theta-l_kokkos. Open issues: #100 #101 #105 #107 #110 #111 #113. | 1) `wbcheck` results; 2) analyse diffs vs cam6_4_219 / ss.06; 3) ChangeLog, PR, review summary, merge, tag `ss.07`; 4) NAG kokkos non-debug failure; 5) file the E3SM issue (handoffs/2026-11-06_stormspeed.md). | `handoffs/2026-11-06_stormspeed.md` |
| **cam-pr1643**: StormSPEED shared-memory fixes into ESCOMP/CAM PR #1643 | `ESCOMP/CAM` PR #1643 = `sjsprecious/CAM` `fix_ne1024_init_oom` (head `948c578c`, untouched). Work branch: `jtruesdal/CAM-1` `pr1643_shmem` (`ceb71700`). Checkouts: Derecho `/glade/campaign/cgd/amp/jet/collections/cam_pr1643`, Izumi `/project/amp/jet/collections/cam_pr1643` (both branch `fix_ne1024_init_oom` at `ceb71700`) | Derecho, Izumi | Branch = PR head + `3410e688` (StormSPEED `44cb2d12`: probe + per-rank fallback, `cam_shmem_force_private` fail-safe, not in atm_in by default) + merge of `cam6_4_218` (`d55e63db`; clean, 15 files vs the tag) + comment/description cleanups `1ae0e111`, `ceb71700`. **Decided:** shared memory stays on by default (as in Jian's PR); no SHM test, no testmod changes (`87731ef2`/`af5051b1` dropped); hand-check probe lines in the aux_cam logs. **Proven on Izumi with plain ESCOMP CAM:** probe PASSED on GNU, FAILED -> fallback on NAG and Intel (so not a StormSPEED artifact); GNU shared vs forced-private BFB. **Running:** `aux_cam` Izumi GNU (820166) and NAG (820167) on `1ae0e111` vs `pretag_bl/cam6_4_218_*`; Derecho Intel (8081882) and NVHPC (8081883) on `ceb71700` vs `/glade/campaign/cesm/community.OLD/amwg/cam_baselines/cam6_4_218_*` (the new location lacks 217/218). Expect BFB everywhere; NLCOMP diffs only from `stream_ndep_mapalgo` (already in the PR); Derecho Intel `ERC_D_Ln9.ne3_ne3_mg37.QPC7...outfrq9s_rttov` FAIL is expected (rttov library moved, ESCOMP/CAM#1745). **New:** `cam6_4_219` was tagged Nov 5 after the suites started (PUMAS answer changes; baselines now under `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`); merging it into `ceb71700` is clean in the sandbox. | 1) `checks/cam-pr1643.sh` results: cs.status + probe lines (GNU/Derecho PASSED, NAG FAILED); 2) decide on `cam6_4_219`: keep the 218 results as the BFB evidence and merge 219 before the PR (clean), or merge 219 and rerun all four suites vs 219 baselines; 3) open PR `jtruesdal/CAM-1:pr1643_shmem` -> `sjsprecious/CAM:fix_ne1024_init_oom` with the description in the handoff (fill in results); Jian merges, or the user (has write access) if he doesn't respond; 4) StormSPEED moves to this shmem commit (Inbox). | `handoffs/2026-11-05_cam-pr1643_checkpoint.md` |
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
- **stormspeed ← cam-pr1643:** once the PR #1643 regression tests pass, StormSPEED moves its shmem code to
  the ESCOMP version (`jtruesdal/CAM-1` `pr1643_shmem`: `3410e688` + description cleanups `1ae0e111`,
  `ceb71700`). Fortran is identical to StormSPEED's `cam_shmem_mod`; only the `cam_shmem_force_private`
  comments and namelist description differ. StormSPEED keeps its own `SHM` test. Probe results with plain
  ESCOMP CAM on Izumi match StormSPEED (#106): GNU PASSED, NAG and Intel FAILED -> fallback.
- **stormspeed ← cam-pr1643:** ESCOMP `ccs_config_cesm1.0.93` lacks `-heap-arrays 64` for Izumi Intel; plain
  ESCOMP CAM (FHISTC_LTso, debug) segfaults during init there, same place as before StormSPEED's `nh.04` fix.
  Izumi Intel is not a CAM regression platform, so low priority; consider upstreaming to ESMCI `ccs_config`.
- **housekeeping ← cam-pr1643:** Derecho CAM baselines moved to `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`
  (`cam6_4_219` updated `archive_baseline.sh`). That location has no `cam6_4_217`/`218`; the full older set is at
  `/glade/campaign/cesm/community.OLD/amwg/cam_baselines`. Update notes that cite the old
  `/glade/campaign/cesm/community/amwg/cam_baselines` path; ask the CAM SE team whether 217/218 will be copied over.
