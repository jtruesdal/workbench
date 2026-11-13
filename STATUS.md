# Status of workstreams

*Last updated 2026-11-13. Each chat updates its own row at the end of a session.*

| Workstream | Repo / branch | Machine | State | Next step | Latest handoff |
|---|---|---|---|---|---|
| **scam-ppe**: nudged-SCAM PPE workflow and science | `CAM-1` `compassdev` (`tools/ppe`, fb8444a) | Derecho | PPE scripts committed; `tools/ppe/PPE_GUIDE.md` is a draft under review. Derecho tests from 2026-11-03 not yet reviewed: `test2` (1-day `m0000`/`m0001` in `$PR`) and `spin5` (5-day `m0000` in `$P2`). | Review `test2` (`ppe_analyze.py`) and `spin5` (`ppe_spinup.py`); then noise floor with `pertlim`, failure handling, full-node scale test. | `tools/ppe/PPE_GUIDE.md` |
| **scam-container**: SCAM as a single column of the 3D model on a small container grid | `CAM-1` `compassdev` = `scam_container` = `61f4cc3fc`; CMEPS from `jtruesdal/CMEPS` tag `cmeps1.1.58_scammesh` | Derecho, Izumi | **BFB with land, ocean and sea ice, nudged and not, without a domain file.** Barrow pair (ne30 container, land+ocean+ice, nudged and not): `TDIFF`/`QDIFF` 0, all atmosphere coupler fields identical. ne3 `F2000climo` `SCT` set `sctn02` (ocean, land, coast, two sea-ice coasts): all PASS. Fixed: container read doubled state/`PHIS` at element-edge points (`be1f8bd14`); CMEPS mesh mode `PTS_DOMAINFILE=mesh` and full-precision `scol_*` attributes (`376b05d1`). Remaining last-bit residues on the surface side only (CICE fluxes, coupler atm->land map). Izumi checkout at `61f4cc3fc`. | 1) ne30 column `SCT` set with all fixes (`sct_columns.sh`); 2) Izumi GNU/NAG SCAM tests; 3) `sct.py`: SCAM half takes case one's `ncdata`; 4) CICE single-column `tarea` units, residues; 5) column-only CAMIOP extract; scratch cleanup. | `handoffs/2026-11-10_scam-container.md` |
| **input-stash**: SCAM-friendly input files | workbench `scripts/` | Izumi, Derecho | **Continues in the scam-container chat.** Phase 1 done on Derecho (`/glade/campaign/cgd/amp/jet/scam_stash/f2000_cyc2000`, 144 MB, `user_nl_cam.stash`) and Izumi: `cam_init_phys_init` 116 s -> 31 s (`pi_chem` 92.5 -> 8.4 s) in the optimized ne30 nudged container case, BFB. `pi_prescribed` 21-26 s remains. | Phase 2: stratospheric aerosols (biggest remaining), DMS, oxidants, ndep (conservative regrid to ne30 + time cut); CTSM `finidat` reuse. | `handoffs/2026-11-07_input-stash.md` |
| **stormspeed**: E3SM nonhydrostatic dycores in CAM | `NCAR/StormSPEED` (`stormspeed` = `cam6_4_219_ss.07`, 407e0f79); forks `jtruesdal/ccs_config_cesm` (nh.06), `jtruesdal/ctsm` (nh.01), `jtruesdal/E3SM` (`stormspeed_homme.01`; round-2 branch `stormspeed/homme_round2` 6e089864); wiki github.com/NCAR/StormSPEED/wiki. Checkouts: Derecho and Izumi `collections/stormspeed_ss07` (`cam6_4_220_update` 0a791fb6) | Derecho, Izumi | **Shared memory:** CAM maintainers agreed to revert #1643 -> **cam6_4_221** (PR ESCOMP/CAM#1754, approved; code == cam6_4_219; baselines linked) awaiting Cheryl's merge, then tag. StormSPEED keeps the code: ss.09 = fixed modules (plan in handoff). Izumi windows non-shared inside cesm.exe: reproduced in a small program, root cause open; #106 explanation to correct. **HOMME:** E3SM#9154 (0aab3626 + 7a890a59, tested Intel/GNU/NAG BFB) paused until E3SM removes METIS (#9161); round 2 later. **Izumi init:** cause found (classic CMIP6 files with UNLIMITED time, slow nfs-fs); mirror `/project/amp/jet/inputdata_fast` (`nccopy -u`) being built; inputdata inventory running. ss.08 rounds' results not yet collected. | 1) tag cam6_4_221 (`cam221_tag.sh`, DRY=1 first); 2) Izumi: mirror -> before/after timing -> use for test rounds; guarded dup deletion; report nfs-fs to CGD IS; 3) ss.08 results, PR, tag; 4) ss.09 shmem fixes + shared-vs-private BFB test; 5) shmem MPI test suite; 6) #106 correction; wiki. | `handoffs/2026-11-13_stormspeed.md` |
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
