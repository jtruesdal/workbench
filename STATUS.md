# Status of workstreams

*Last updated 2026-11-06. Each chat updates its own row at the end of a session.*

| Workstream | Repo / branch | Machine | State | Next step | Latest handoff |
|---|---|---|---|---|---|
| **scam-ppe**: nudged-SCAM PPE workflow and science | `CAM-1` `compassdev` (`tools/ppe`, fb8444a) | Derecho | PPE scripts committed; `tools/ppe/PPE_GUIDE.md` is a draft under review. Derecho tests from 2026-11-03 not yet reviewed: `test2` (1-day `m0000`/`m0001` in `$PR`) and `spin5` (5-day `m0000` in `$P2`). | Review `test2` (`ppe_analyze.py`) and `spin5` (`ppe_spinup.py`); then noise floor with `pertlim`, failure handling, full-node scale test. | `tools/ppe/PPE_GUIDE.md` |
| **scam-container**: SCAM as a single column of the 3D model on a small container grid | `CAM-1` `scam_container` (7a09c7675; `compassdev` = ab7a475a8) | Derecho, Izumi | **BFB proven**: `SCT` `sctc03` (ab7a475a8) PASS end to end; a SCAM case created normally at `ne30_ne30_mg17` runs SE on the ne3np4 container automatically (`buildcpp`; `-scam_iop_hgrid` for namelist defaults). Timers: init 123 s = `pi_chem` 101 s + `pi_prescribed` 21 s; run ~3.4 s/step reading the 25.8 GB global CAMIOP file, physics 0.24 s/step. New 7a09c7675: forcing grid only from `--res`; IOP file is any set of columns (also observed IOPs); nearest IOP and forcing-grid columns chosen once (not yet built in CAM). Building overnight: `sctc04` (`/glade/derecho/scratch/jet/cs.status.sctc04`) and ARM97 case `/glade/campaign/cgd/amp/jet/cases/SCAM.arm97.ne30.01`. | 1) Submit `sctc04` and ARM97; check BFB and the new column log lines; 2) column-only CAMIOP extract (BFB, faster); 3) fast-forward `compassdev`; 4) `compare_fracs.py`, then mesh-only CMEPS single column (drop the domain file); 5) scratch cleanup. | `handoffs/2026-11-06_scam-container.md` |
| **input-stash**: SCAM-friendly input files | workbench `scripts/` | Izumi (Derecho next) | Phase 1 done on Izumi: `/project/amp/jet/scam_stash/f2000_cyc2000/` (32 emission files time-subset, verified identical). | Measure phase 1 in a run; phase 2 (conservative regrid to ne30 + time cut for strataero, DMS, oxidants, ndep; reuse CTSM `finidat` interpolation). | `handoffs/2026-11-04_scam_speedups.md` |
| **stormspeed**: E3SM nonhydrostatic dycores in CAM | `NCAR/StormSPEED` (`stormspeed` = `cam6_4_211_ss.05`, 1fee24e3); forks `jtruesdal/ccs_config_cesm` (`ccs_config_nh`), `jtruesdal/ctsm`, `jtruesdal/E3SM` (`stormspeed/homme_nag_portability`). Checkouts: Derecho `/glade/campaign/cgd/amp/jet/collections/stormspeed_ss06` (`nag_portability`), `/glade/campaign/cgd/amp/jet/collections/e3sm_fork` (sparse); Izumi `/project/amp/jet/collections/stormspeed_ss06` (`nag_portability`, still at the old eba02b95 until the Izumi runs finish) | Derecho, Izumi | Tagged `ss.00`-`ss.05` (`ss.04` 8cfdd3eb: ne30pg2/climate/GPU tests, SHM test fix; `ss.05` 1fee24e3: upstream CTSM `ctsm5.4.057_nh.01`, BFB everywhere). Gate baselines `cam6_4_211_ss.04_e3sm_intel` (35) / `_gnu` (16). **`ss.06` in progress** on `nag_portability` 70f8354b (no PR yet): `ccs_config` `nh.05` (`-std=c++17` for NAG), SENH fixes (`namelist_mod_cam` implicit none/SFCURVE/nnodes, `restart_dynamics` local m), `dycore` -> `jtruesdal/E3SM` tag `stormspeed_homme.01` (E3SM b70b675a7b + 1 commit, 8 HOMME files, 20 lines; incl. two real bugs). NAG theta-l SMS_D PASS; theta-l_kokkos builds with NAG, debug run traps on HOMME's deliberate NaN padding. Running: Derecho gate on 70f8354b vs ss.04; Izumi GNU 12 theta-l + Intel debug probe; NAG non-debug kokkos. Open issues: #100 #101 #102 #105 #107 #110 #111 #113. | 1) Results of the running tests; 2) switch the Izumi clone to 70f8354b (after its jobs end); 3) testlist: Izumi GNU/NAG/Intel theta-l tests into `aux_cam_e3sm`; 4) ChangeLog, PR, review summary, merge, tag `ss.06`; 5) file the E3SM issue (draft in the handoff), close #102. | `handoffs/2026-11-06_stormspeed.md` |
| **cam-pr1643**: StormSPEED shared-memory fixes into ESCOMP/CAM PR #1643 | `ESCOMP/CAM` PR #1643 (Jian Sun's branch, head `948c578c`); fixes from `NCAR/StormSPEED` `44cb2d12`, `87731ef2`, `af5051b1` | Derecho, Izumi | Not started. `44cb2d12` cherry-picks cleanly onto the PR head; `87731ef2` needs the two SHM testlist blocks added by hand; `af5051b1` then applies. PR is behind `cam_development` (last merged #1690). | 1) Cherry-pick the three commits onto a branch from the PR head; 2) merge current `cam_development`; 3) `aux_cam` Derecho Intel/NVHPC and Izumi GNU/NAG plus SHM tests; 4) PR into Jian's branch. | `handoffs/2026-11-05_cam-pr1643.md` |
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
