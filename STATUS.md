# Status of workstreams

*Last updated 2026-11-17. Each chat updates its own row at the end of a session.*

| Workstream | Repo / branch | Machine | State | Next step | Latest handoff |
|---|---|---|---|---|---|
| **scam-ppe**: nudged-SCAM PPE workflow and science | `CAM-1` `compassdev` (`tools/ppe`, fb8444a) | Derecho | PPE scripts committed; `tools/ppe/PPE_GUIDE.md` is a draft under review. Derecho tests from 2026-11-03 not yet reviewed: `test2` (1-day `m0000`/`m0001` in `$PR`) and `spin5` (5-day `m0000` in `$P2`). | Review `test2` (`ppe_analyze.py`) and `spin5` (`ppe_spinup.py`); then noise floor with `pertlim`, failure handling, full-node scale test. | `tools/ppe/PPE_GUIDE.md` |
| **scam-container**: SCAM as a single column of the 3D model on a small container grid | `CAM-1` `compassdev` = `scam_container` = `61f4cc3fc`; CMEPS from `jtruesdal/CMEPS` tag `cmeps1.1.58_scammesh` | Derecho, Izumi | **BFB with land, ocean and sea ice, nudged and not, without a domain file.** Barrow pair (ne30 container, land+ocean+ice, nudged and not): `TDIFF`/`QDIFF` 0, all atmosphere coupler fields identical. ne3 `F2000climo` `SCT` set `sctn02` (ocean, land, coast, two sea-ice coasts): all PASS. Fixed: container read doubled state/`PHIS` at element-edge points (`be1f8bd14`); CMEPS mesh mode `PTS_DOMAINFILE=mesh` and full-precision `scol_*` attributes (`376b05d1`). Remaining last-bit residues on the surface side only (CICE fluxes, coupler atm->land map). Izumi checkout at `61f4cc3fc`. | 1) ne30 column `SCT` set with all fixes (`sct_columns.sh`); 2) Izumi GNU/NAG SCAM tests; 3) `sct.py`: SCAM half takes case one's `ncdata`; 4) CICE single-column `tarea` units, residues; 5) column-only CAMIOP extract; scratch cleanup. | `handoffs/2026-11-10_scam-container.md` |
| **input-stash**: SCAM-friendly input files | workbench `scripts/` | Izumi, Derecho | **Continues in the scam-container chat.** Phase 1 done on Derecho (`/glade/campaign/cgd/amp/jet/scam_stash/f2000_cyc2000`, 144 MB, `user_nl_cam.stash`) and Izumi: `cam_init_phys_init` 116 s -> 31 s (`pi_chem` 92.5 -> 8.4 s) in the optimized ne30 nudged container case, BFB. `pi_prescribed` 21-26 s remains. | Phase 2: stratospheric aerosols (biggest remaining), DMS, oxidants, ndep (conservative regrid to ne30 + time cut); CTSM `finidat` reuse. | `handoffs/2026-11-07_input-stash.md` |
| **stormspeed**: E3SM nonhydrostatic dycores in CAM | `NCAR/StormSPEED` (`stormspeed` = `cam6_4_219_ss.07`, 407e0f79); forks `jtruesdal/ccs_config_cesm` (nh.06), `jtruesdal/ctsm` (nh.01), `jtruesdal/E3SM` (`stormspeed_homme.01`; round-2 branch `stormspeed/homme_round2` 6e089864); wiki github.com/NCAR/StormSPEED/wiki. Checkouts: Derecho and Izumi `collections/stormspeed_ss07` (`cam6_4_220_update` 0a791fb6) | Derecho, Izumi | **cam6_4_221 tagged** (revert of #1643; baselines linked to 219). StormSPEED keeps the shared-memory code (ss.09 plan). **HOMME:** E3SM#9154 paused until METIS removal (#9161); round-2 branch `stormspeed/homme_round2`. **Fast input data done on both machines** (`nccopy -u` mirrors, identical answers): Izumi test 4124 -> 248 s, Derecho CAM init 94 -> 25 s (`handoffs/2026-11-13_fast-inputdata.md`); layout requested upstream for the new CMIP7 emission files (ESCOMP/CAM#1722). Izumi `inputdata.sav` trimmed 248 -> 74 GB; Derecho `collections` cleaned (~47 GB). **#111 (GPU ERS):** unify chat's hypothesis (HOMME first-step diagnostics overwrite shared scratch after restart) checked against the code; E1 (diagnostics off via `homme_set_defaults` in `namelist_mod_cam.F90`) at ne30pg2, 16 GPU nodes: `/glade/derecho/scratch/jet/tests/gpu111/*full_nodiag`, resubmitted at premium. ss.08 results still to collect. | 1) #111: read `COMPARE_base_rest` of `full_nodiag` (PASS -> diagnostics are the trigger, E3; FAIL -> E2), confirm energy lines gone in its atm.log, then update #111; 2) follow up the layout request on #1722; 3) ss.08 results, PR, tag; 4) ss.09 shmem fixes + shared-vs-private BFB test; 5) shmem MPI test suite; 6) #106 correction; wiki (Izumi init, mirrors). | `handoffs/2026-11-13_stormspeed.md` |
| **stormspeed-unify**: one SE interface for CAM-SE and E3SM HOMME, then CAM-SIMA readiness and a GPU-resident dycore/physics coupling | `NCAR/StormSPEED`: `stormspeed_unify` = `d24da8cf`; `stormspeed_sima` = `aae0aa2f` on GitHub (refactor steps 1-5); GPU work local in worktree `collections/stormspeed_sima.111626` (pushed as WIP branch `stormspeed_sima_gpu_wip`, re-push to update; it lacks the -cppdefs modes fix and E1b). `jtruesdal/E3SM` WIP branch `stormspeed_homme_02_wip` (on `stormspeed_homme.01`: `sort_mod` fix, `cam_device_coupling`, `cam_skip_forcing_push`/`cam_skip_state_pull`). `jtruesdal/ccs_config_cesm` branch `nvhpc_kokkos_gpu`. `jtruesdal/atmospheric_physics` `kessler_gpu` = `6d04a46` | Derecho | **Refactor done** (R1-R5 BFB). **GPU ladder on FKESSLER ne30pg2, NVHPC, 64 A100s, all RUN PASS:** NVHPC GPU executable (Kokkos dycore + OpenACC) builds and runs in CIME; **Check** (`_gfrcheck`): GPU remap = Fortran remap to roundoff for physics->dynamics (FT/FM/FQ) and for ps, phis, u, v, omega, q, but **T differs by a fixed ~0.5%** (max 1.6 K, lowest level, humid columns, no condensate; virtual temperature ruled out); **Use** (`_gfrdev`, dev1) runs; **Resident** (`_gfrres`, res2: HOMME's per-step push/pull off) **bit-for-bit identical to Use**. Lesson: CAM's configure keeps only the last `-cppdefs`; chained testmods lost defines (res1 invalid); fixed with `se/cam_mods/gfr_device_modes.h` (one macro per mode). Open: keeppull vs Resident differ at roundoff (pull side effect suspected); `_gfrdev_skippull` crashes (`EOS bad state`), cause not found; FHISTC_LTso `_acc` NaN in `Faxa_lwdn` at init (likely needs `-rad rrtmgp_gpu -microphys mg3`). Friday talk given (deck + speaker notes + presenter view). **xDSL CAM-SIMA fork** (`johnmauff/CAM-SIMA` `xdsl-ccpp-adapter`, generator `johnmauff/xdsl-ccpp`): cam4 GPU physics with caps managing device data, cam5 soon; design note drafted for the xDSL team (host-owned device-resident state via `model_var_memory_space=device`, `phys` pointing at it, dycore-boundary rule for hoisted updates). | 1) E1b result (`e1b`: remap inputs compared, `atm.log` 'E1b'); fix the T difference; 2) reproducibility rerun job 8267191 vs `~/res2_run1` (expect identical); 3) send design note to John Mauff, look at generated GPU caps from the fork; 4) CAM-SIMA plan: one-day service map of the ~60 CAM modules, then A1 (theta-l_kokkos + GPU cam4 suite); 5) resident restarts/history; 6) re-push WIP branches; push/tag ccs_config `nh.07` and E3SM `stormspeed_homme.02` when settled; 7) PR #577 review; 8) `collections/` cleanup. | `handoffs/2026-11-20_stormspeed-unify.md` |
| **cam-pr1643**: StormSPEED shared-memory fixes into ESCOMP/CAM PR #1643 | **Done: tagged `cam6_4_220`; reverted by `cam6_4_221`** (ESCOMP/CAM#1754, see stormspeed handoff 2026-11-13) (`00e7349f`, merge of #1643 = `9c1d20b6` ChangeLog on `d014170a`); code identical to the tested tree `f893f2d0`. Branches: `sjsprecious/CAM` `fix_ne1024_init_oom`, `jtruesdal/CAM-1` `pr1643_v2` (PR sjsprecious/CAM#2, fast-forwarded), `pr1643_shmem` (tested history). Checkouts: Derecho `/glade/campaign/cgd/amp/jet/collections/cam_pr1643`, Izumi `/project/amp/jet/collections/cam_pr1643` | Derecho, Izumi | Node-shared tables on by default where the MPI-3 probe passes; otherwise (or `cam_shmem_force_private`) the original per-rank data paths. `aux_cam` vs `cam6_4_219` all bit-for-bit (derecho intel 55/56 + rttov pre-existing, nvhpc 1/1, izumi gnu 25/25, nag 16/16); GPU ne30 A/B identical and same speed; CAM SE extra test OK. Izumi probe failure seen with MVAPICH2 2.3.3 (Intel, NAG); the "fixed in 2.3.4" explanation turned out unsupported (see stormspeed handoff). | Only follow-ups: archive cam6_4_220 baselines (usual tag procedure); post comment on NCAR/StormSPEED#106 (text in handoff); Inbox items for stormspeed (adopt cam6_4_220 shmem code) and housekeeping (izumi MVAPICH2, test_driver --retry). | `handoffs/2026-11-11_cam-pr1643.md` |
| **housekeeping** | various | Derecho, Izumi, laptop | Derecho `$CAMROOT` has an uncommitted compset `FHISTC_LTso_SROF` in `config_compsets.xml`. Older Derecho checkout `collections/cam6_4_207_compass.100926` (at 8e0952a) holds untracked `scm_prep_ERAnudge_global`, `sct.py.manus`. Old Derecho `tools/ppe` copy at `collections/tools_ppe_old_derecho`. Upstream CICE issue for the single-column TLAT/TLON fix not yet filed. Izumi `ndgiz01` SCT test superseded by Derecho. tmux session `scam` is on derecho2 (laptop alias `dtmux`). | Decide where the compset goes; retire or update the old checkout; delete the old `tools/ppe` copy; file the CICE issue. | — |

## Inbox

Notes left by one chat for another workstream. The receiving chat clears its items.

- **scam-ppe ← scam-container:** the 3D (global) run fails at the first tape-3 write when
  `fincl3` holds `Nudge_*`, `Target_*`, `PS`, `num_a*` (PIO "NetCDF: Index exceeds dimension
  bound", `pio_getput_int.c`; seen on Izumi and Derecho). `fincl3` was dropped from the
  `scm_prep_ERAnudge_*` testmods; SCAM writes the same fields without trouble. Root cause
  still unknown; matters if the PPE wants nudging diagnostics from 3D runs.
- **scam-ppe ← scam-container:** `compassdev` is now `61f4cc3fc`. Container runs at a column that is an
  element-edge point of ne3 had doubled initial state and `PHIS` before `be1f8bd14` (Manus and SGP are
  interior, unaffected); redo any such PPE runs. Nudged SCAM is BFB at Barrow (land+ocean+ice). For
  coastal/ice sites use `PTS_DOMAINFILE=mesh` (the ne30 domain file is not exact at Barrow).
- **scam-ppe ← scam-container:** production CAMIOP output cannot be global every step
  (~0.5 GB/step at ne30). Plan column-only IOP output for the chosen sites. SCAM's reader now
  accepts any set of columns (`compassdev` since 7a09c7675), and a
  single-column file should also remove most of SCAM's per-step cost (~3.4 s/step reading the
  global file). PPE members run on the ne3 container: create the SCAM case at the forcing
  resolution; `buildcpp` does the rest.
- **housekeeping ← scam-container:** scratch on Derecho (`/glade/derecho/scratch/jet`): delete test dirs
  `sctc01`-`sctc04` (25.8 GB CAMIOP each; keep `sctc05`), `sctm01`, `sctd01`, `sctl01`, `sctn01`, `sctx01`
  (pre-fix or superseded); cases `SCAM.ne3container.Manus.01`, `SCAM.ne30twin.Manus.01`,
  `SCAM.ne30nudge.mesh.*` in `/glade/campaign/cgd/amp/jet/cases/` are superseded. CICE: still file the
  upstream issue for the single-column TLAT/TLON fix; add the single-column `tarea` units (steradians
  vs m^2) and `ULAT = TLAT + pi` to it.
- **housekeeping ← stormspeed:** Izumi interactive job 820063 is orphaned on i011: `pbs_mom` is
  not running there (only `trqauthd`), so `qdel` fails ("Server could not connect to MOM"). A
  help@ucar.edu ticket was drafted (restart `pbs_mom` on i011, purge 820063); check it was sent and resolved. (820063 no longer in `qstat` as of Nov 5: probably resolved.)
- **housekeeping ← stormspeed:** decide whether to retire the path variables in `scam_env.csh`
  (`CAMROOT`, `TD`, `CC`, `PR`, `P2`, ...) now that WORKFLOW.md asks for absolute paths; the
  scam-ppe and scam-container rows still refer to `$PR`, `$P2`, `$CC`, `$TD`.
- **housekeeping ← cam-pr1643:** Derecho CAM baselines moved to `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`
  (`cam6_4_219` updated `archive_baseline.sh`). That location has no `cam6_4_217`/`218`; the full older set is at
  `/glade/campaign/cesm/community.OLD/amwg/cam_baselines`. Update notes that cite the old
  `/glade/campaign/cesm/community/amwg/cam_baselines` path; ask the CAM SE team whether 217/218 will be copied over.
- **housekeeping ← cam-pr1643:** izumi Intel and NAG MPI modules (`mpi/2.3.3/intel/20.0.1`, `mpi/2.3.3/nag/7.0`) are
  MVAPICH2 2.3.3, which has the MPI-3 shared-window bug fixed in 2.3.4; GNU uses 2.3.7. Ask CGD sysadmins about 2.3.7
  builds for Intel/NAG (then a `ccs_config` module change). Not needed for CAM: the probe falls back to the original code.
- **housekeeping ← cam-pr1643:** `test_driver.sh` runs `create_test --retry 2`; on derecho its retry pass resubmitted
  tests still waiting in the queue, so two jobs ran in one case (Nov 5: CONUS, GPU test). For CAM PR testing the
  stormspeed procedure (`create_test` in `qcmd`, no `--retry`, `-j 8`) avoided that and the build-node OOM kills.
- **scam-container ← stormspeed:** fast input-data mirrors (classic UNLIMITED-time files converted with `nccopy -u`,
  identical answers) on Izumi (`/project/amp/jet/inputdata_fast`) and Derecho (`/glade/campaign/cgd/amp/jet/inputdata_fast`);
  use via `DIN_LOC_ROOT`. Izumi RUN 4124 -> 248 s; Derecho CAM init 94 -> 25 s. How to add a SCAM case's files:
  `handoffs/2026-11-13_fast-inputdata.md`.
- **scam-ppe ← stormspeed:** the same mirrors speed up every CAM/SCAM initialization; for noise-floor and PPE members set
  `DIN_LOC_ROOT` to the mirror (after adding the case's files, see `handoffs/2026-11-13_fast-inputdata.md`).
- **housekeeping ← stormspeed:** Izumi `nfs-fs` (/fs/cgd/csm) showed read RTT 100-240 ms (nfs-amp: 3-4 ms) and ~30 MB/s on
  2026-11-12; report to CGD IS. Also the earlier MVAPICH2 note ("bug fixed in 2.3.4") is not supported by the tests; the
  request for 2.3.7 builds for Intel/NAG still makes sense, but not on that ground alone.
- **housekeeping ← stormspeed:** Derecho `/glade/campaign/cgd/amp/jet/collections` cleanup 2026-11-16: 68 finished
  checkouts and scratch files (~47 GB) reviewed and removed with the new scripts; local-only work saved in `collections/archive_patches_2026-11-16/`). Left for
  their owners to decide: SE-dycore unification (`stormspeed_build*`, `stormspeed_build*.tar` ~7 GB, `e3sm_ref`, `check`,
  `unify_se_dycore.py`, `finish_unify_se.py`, `fetch_and_package.py`, `*_context.txt`); compassdev
  (`cam6_4_207_compass.100926.tar` 2.8 GB, `cam6_4_207_compassdev.102726`); CLUBB-MF (`clubb_mf_ccpp_bstephens.102126`);
  #1643 precursors (`fix_shared_read_and_carry`, `cam6_4_203_stormspeed_fix_init_oom_clubbmf.100126`,
  `cam6_4_211_plus_oom.101426`). New rule in `WORKFLOW.md` §3/§4 and `scripts/clean_check.sh`, `keep_inspect.sh`,
  `archive_local.sh`.
- **stormspeed ← stormspeed-unify:** CAM's `bld/configure` takes a single `-cppdefs` value (Getopt `cppdefs=s`): when
  chained testmods each `--append CAM_CONFIG_OPTS=' -cppdefs ...'`, only the last survives. Check any StormSPEED testmods
  that chain `-cppdefs` (check the case's `env_build.xml`); unify's fix is one macro per mode plus a header.
- **stormspeed ← stormspeed-unify:** the NVHPC GPU executable now runs FKESSLER at ne30pg2 on 64 A100s (`..._kokkos_gpu_acc`);
  FHISTC_LTso with it fails at init (NaN in `Faxa_lwdn`), most likely because the testmod lacks CAM's GPU physics options
  (`-rad rrtmgp_gpu -microphys mg3`, as in CAM's `outfrq9s_gpu_ne3`).
- **stormspeed ← stormspeed-unify:** GPU ERS restart failure (#111): theory and a cheapest-first test plan in
  `handoffs/2026-11-16_unify-to-stormspeed_issue111.md` (first-step HOMME diagnostics after a restart write into the shared
  `FunctorsBuffersManager` pool; decisive test: GPU ERS with `disable_diagnostics=.true.` via SourceMod). Not a Kessler/GPU-demo issue.
- **stormspeed ← stormspeed-unify:** NVHPC on the GPU is possible now: the new NVHPC GPU build path compiles HOMME's C++
  (incl. `ComposeTransportImpl`) with nvcc and NVHPC's g++ 12.4 as host; nvc++ is not used, so the 30 Oct nvc++/KokkosKernels SIMD
  failure (088ab323) doesn't apply to GPU builds (CPU theta-l_kokkos + NVHPC is still broken). An NVHPC cross-check of #111 is feasible
  once `SMS_Ln9.ne30pg2_ne30pg2_mt232.FHISTC_LTso.derecho_nvhpc.cam-outfrq9s_thetal_kokkos_gpu_acc` passes (on `stormspeed_sima`;
  needs the `sort_mod` fix, the buildlib localrc fix and ccs_config branch `nvhpc_kokkos_gpu`; details in the unify handoff 2026-11-18).
  Also: `create_test` cases outside a suite submit with 12 h walltime; `qalter -l walltime=01:00:00 <job>` gets 16-node GPU jobs going.
- **housekeeping ← stormspeed-unify:** WIP branches pushed for review/reading (not merged): `NCAR/StormSPEED`
  `stormspeed_sima_gpu_wip`, `jtruesdal/E3SM` `stormspeed_homme_02_wip`, `jtruesdal/ccs_config_cesm` `nvhpc_kokkos_gpu`; delete or
  replace them once the real branches/tags land. Temporary copy `~/res2_run1` (one history file) can go after the rerun check.
- **housekeeping ← stormspeed-unify:** `git worktree` + `git-fleximod` don't mix: in a worktree the sparse submodules
  (`cam-sima`, `mpas`, `cosp2`, `ext_co2_cooling`, `se/homme`) were checked out in full (CAM-SIMA's `orbital_data.F90` broke
  the build) and the `se/homme` clone hung. Fixed with a local clone + `fix_sparse_submodules.v1.sh` (in the unify handoff).
  For new branches with submodules, prefer a fresh clone; worth a line in `WORKFLOW.md`. Also: Derecho `qsub` wants
  `gpu_type` inside `select` (`select=1:ncpus=4:ngpus=1:gpu_type=a100`); never `xmlchange` a case while it is building.
