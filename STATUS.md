# Status of workstreams

*Last updated 2026-11-04. Each chat updates its own row at the end of a session.*

| Workstream | Repo / branch | Machine | State | Next step | Latest handoff |
|---|---|---|---|---|---|
| **scam-ppe**: nudged-SCAM PPE workflow and science | `CAM-1` `compassdev` (`tools/ppe`, fb8444a) | Derecho | PPE scripts committed; `tools/ppe/PPE_GUIDE.md` is a draft under review. Derecho tests from 2026-11-03 not yet reviewed: `test2` (1-day `m0000`/`m0001` in `$PR`) and `spin5` (5-day `m0000` in `$P2`). | Review `test2` (`ppe_analyze.py`) and `spin5` (`ppe_spinup.py`); then noise floor with `pertlim`, failure handling, full-node scale test. | `tools/ppe/PPE_GUIDE.md` |
| **scam-container**: SCAM speed and memory (run the exact ne30 column on an ne3 grid) | `CAM-1` `scam_container` (b268622; synced on GitHub, Derecho, Izumi) | Derecho, Izumi | Branch has the physics side (677da86), dynamics side (1724a8a), Derecho testmod (d4b65c0), `fincl3` dropped from both nudging testmods (e5382d5), and the SCAM skip of `compute_adv_tends_xyz` + `cam_init` timers (b268622). Code compiles. SCT regression `sctc01` (built before b268622) failed at the 3D tape-3 write (`fincl3`), resubmitted without it as job 8070657 (premium, 1:30). ne3 case `$CC` built (before b268622). | 1) When 8070657 finishes: `RUN`/`COMPARE_base_default` PASS, `scm_clat/scm_clon/scm_area` in the CAMIOP file. 2) Submit `$CC`; check `TDIFF/QDIFF = 0`, geometry log lines, memory and time vs ne30 SCAM. 3) Rebuild with b268622 and confirm the adv-tend skip keeps BFB; read the new `cam_init` timers. | `handoffs/2026-11-04_scam_speedups.md` |
| **input-stash**: SCAM-friendly input files | workbench `scripts/` | Izumi (Derecho next) | Phase 1 done on Izumi: `/project/amp/jet/scam_stash/f2000_cyc2000/` (32 emission files time-subset, verified identical). | Measure phase 1 in a run; phase 2 (conservative regrid to ne30 + time cut for strataero, DMS, oxidants, ndep; reuse CTSM `finidat` interpolation). | `handoffs/2026-11-04_scam_speedups.md` |
| **stormspeed**: E3SM nonhydrostatic dycores in CAM | `CAM-1` StormSPEED branches | Derecho | Tracked in its own chat. | — | — |
| **housekeeping** | various | Derecho, Izumi, laptop | Derecho `$CAMROOT` has an uncommitted compset `FHISTC_LTso_SROF` in `config_compsets.xml`. Older Derecho checkout `collections/cam6_4_207_compass.100926` (at 8e0952a) holds untracked `scm_prep_ERAnudge_global`, `sct.py.manus`. Old Derecho `tools/ppe` copy at `collections/tools_ppe_old_derecho`. Upstream CICE issue for the single-column TLAT/TLON fix not yet filed. Izumi `ndgiz01` SCT test superseded by Derecho. tmux session `scam` is on derecho2 (laptop alias `dtmux`). | Decide where the compset goes; retire or update the old checkout; delete the old `tools/ppe` copy; file the CICE issue. | — |

## Inbox

Notes left by one chat for another workstream. The receiving chat clears its items.

- **scam-ppe ← scam-container:** the 3D (global) run fails at the first tape-3 write when
  `fincl3` holds `Nudge_*`, `Target_*`, `PS`, `num_a*` (PIO "NetCDF: Index exceeds dimension
  bound", `pio_getput_int.c`; seen on Izumi and Derecho). `fincl3` was dropped from the
  `scm_prep_ERAnudge_*` testmods; SCAM writes the same fields without trouble. Root cause
  still unknown; matters if the PPE wants nudging diagnostics from 3D runs.
- **scam-ppe ← scam-container:** production CAMIOP output cannot be global every step
  (~0.5 GB/step at ne30). Plan column-only IOP output for the chosen sites; SCAM's IOP
  reader must accept it.
