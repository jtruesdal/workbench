# Status of workstreams

*Last updated 2026-11-04. Each chat updates its own row at the end of a session.*

| Workstream | Repo / branch | Machine | State | Next step | Latest handoff |
|---|---|---|---|---|---|
| **scam-ppe**: nudged-SCAM PPE workflow and science | `CAM-1` `compassdev` (`tools/ppe`, fb8444a) | Derecho | PPE scripts committed; `tools/ppe/PPE_GUIDE.md` is a draft under review. Derecho tests from 2026-11-03 not yet reviewed: `test2` (1-day `m0000`/`m0001` in `$PR`) and `spin5` (5-day `m0000` in `$P2`). | Review `test2` (`ppe_analyze.py`) and `spin5` (`ppe_spinup.py`); then noise floor with `pertlim`, failure handling, full-node scale test. | `tools/ppe/PPE_GUIDE.md` |
| **scam-container**: SCAM speed and memory (run the exact ne30 column on an ne3 grid) | `CAM-1` `scam_container` (677da86, d4b65c0, 1724a8a pushed) | Derecho, Izumi | Physics- and dynamics-side changes compile (Derecho). `sctc01` SCT regression job has ended; result not yet checked (the `fincl3` removal from its 3D `user_nl_cam` may have come too late). ne3 case `$CC` built; needs a CAMIOP file with `scm_clat/scm_clon/scm_area`. Izumi checkout has two uncommitted changes (skip `compute_adv_tends_xyz` in SCAM; `cam_init` timers). | 1) Check `$TD/TestStatus` / `TestStatus.log`. 2) Izumi: commit the two changes, rebase on `origin/scam_container`, push. 3) Remove `fincl3` from both `scm_prep_ERAnudge_*` testmods. 4) Rerun SCT, then the ne3 case; compare `TDIFF/QDIFF` and timings. | `handoffs/2026-11-04_scam_speedups.md` |
| **input-stash**: SCAM-friendly input files | workbench `scripts/` | Izumi (Derecho next) | Phase 1 done on Izumi: `/project/amp/jet/scam_stash/f2000_cyc2000/` (32 emission files time-subset, verified identical). | Measure phase 1 in a run; phase 2 (conservative regrid to ne30 + time cut for strataero, DMS, oxidants, ndep; reuse CTSM `finidat` interpolation). | `handoffs/2026-11-04_scam_speedups.md` |
| **stormspeed**: E3SM nonhydrostatic dycores in CAM | `CAM-1` StormSPEED branches | Derecho | Tracked in its own chat. | — | — |
| **housekeeping** | various | Derecho, Izumi | Derecho `$CAMROOT` has an uncommitted compset `FHISTC_LTso_SROF` in `config_compsets.xml`. Older Derecho checkout `collections/cam6_4_207_compass.100926` (at 8e0952a) holds untracked `scm_prep_ERAnudge_global`, `sct.py.manus`. Old Derecho `tools/ppe` copy at `collections/tools_ppe_old_derecho`. Upstream CICE issue for the single-column TLAT/TLON fix not yet filed. | Decide where the compset goes; retire or update the old checkout; delete the old `tools/ppe` copy; file the CICE issue. | — |

## Inbox

Notes left by one chat for another workstream. The receiving chat clears its items.

- **scam-container ← scam-ppe:** the SCT test on Izumi showed the 3D run failing when
  writing history tape 3 with `fincl3` (`Nudge_*`, `Target_*`, `PS`, `num_a*`). The cause
  is not known yet; the SCAM side writes the same fields without trouble.
- **scam-ppe ← scam-container:** production CAMIOP output cannot be global every step
  (~0.5 GB/step at ne30). Plan column-only IOP output for the chosen sites; SCAM's IOP
  reader must accept it.
