# Handoff: SCAM speed-ups and SCAM-friendly input files (from the StormSPEED chat, 2026-11-03/04)

This continues the `scam_container` work (jtruesdal/CAM-1, branch `scam_container`, on top of `compassdev`).
Work below was done in a StormSPEED chat and must be folded into the scam_container effort.

## 1. Code changes made on Izumi — NOT yet committed

Checkout: `/project/amp/jet/collections/cam6_4_207_compass.100926` (branch `scam_container`).

| File | Change | Effect |
|---|---|---|
| `src/dynamics/se/stepon.F90` (lines 268, 280) | `call compute_adv_tends_xyz(...)` → `if (.not. single_column) call compute_adv_tends_xyz(...)` | skips the advection-tendency diagnostics in SCAM (they loop over all elements; ~75 s of a 149 s SCAM run). 3-D runs and `compute_write_iop_fields` (IOP output incl. `scm_clat/clon/area`) unchanged |
| `src/control/cam_comp.F90` (cam_init) | 7 GPTL timer pairs: `cam_init_files`, `cam_init_dyn_grid`, `cam_init_phys_register`, `cam_init_dyn_init`, `cam_init_phys_init`, `cam_init_stepon_init`, `cam_init_history` | breaks down CAM init, which is ~182 s and otherwise untimed |

Not yet verified that SCAM stays BFB with the adv-tend skip.
Note (added in the scam-container chat): the Izumi branch is behind `origin/scam_container`
(d4b65c0, 1724a8a were pushed from Derecho), so rebase before pushing.

## 2. Where SCAM time goes (101a case on Derecho, debug, ne30 dyn grid, job 8052868)

- Init 211 s, of which `[ATM] IPDv03p3` (CAM init) 182 s — almost all untimed → hence the new cam_init timers.
- Run 149 s for 6 steps (~1430 s/model day), almost all whole-ne30-grid dycore work on one task:
  - `comp_adv_tends1/2` 36 + 39 s (skipped in SCAM by change 1)
  - `p_d_coupling` 27.5 s (`bndry_exchange` 17.8, `putUniquePoints` 9.3)
  - `d_p_coupling` 23.4 s (`UniquePoints`)
  - `cam_write_restart` 6.3 s
- These scale with the number of elements (5400 at ne30) → the ne3 container (54 elements) should cut them ~100×.
- Profile column tip: in ESMF_Profile.summary the Mean is field `$(NF-4)` (names contain spaces).

## 3. SCT test on Izumi (stopped)

- 3-D run failed at the first history write after step 0: `_FillValue type mismatch`, then
  `Index exceeds dimension bound` while writing h2 = tape 3 (`fincl3`: Nudge_T, Nudge_Q, Target_T,
  Target_Q, PS, num_a1..4; no nhtfrq/mfilt/ndens for tape 3 → defaults; `write_nstep0=.true.`).
- With `fincl3` commented out in the case (not the testmod) the rerun passed step 0 but was too slow
  (~3–4 min/step; global CAMIOP `h1i` ~0.5 GB per step at ~8–9 MB/s) → cancelled; SCT moves to Derecho.
- SCT runs case 1 (3-D) in `run/`, case 2 (SCAM) in `run/case2run`, built separately; submit with
  `./case.submit` (a hand-made `qsub nodes=1` oversubscribed 96 tasks → MVAPICH2 affinity failure).
- Production: global every-step CAMIOP output is infeasible for 2002–2008; restrict IOP output to the
  ARM-site columns (needs SCAM's IOP reader to accept column-only files).

## 4. Input-data findings

- `scripts/bcinventory.py`: 49 files ≥ 50 MB, 48.5 GB. All big CAM files are classic/64-bit offset.
- ERA5 nudging files are netCDF-4, contiguous, uncompressed; one column of T,Q,U,V,PS reads in 0.33 s cold → not the bottleneck.
- F2000climo cycle years: srf_emis/ext_frc 2000, csw (DMS) 2000, prescribed_ozone 2000,
  prescribed_strataero 1990, tracer_cnst 1850 (12-month file).

## 5. SCAM-friendly stash

**Phase 1 — done (Izumi):** `/project/amp/jet/scam_stash/f2000_cyc2000/` (185 MB vs ~30 GB): 32 native-ne30
emission files time-subset to 1999-11-16..2001-02-15, CDF5, verified identical; `user_nl_cam.stash` holds the
rewritten `srf_emis_specifier`/`ext_frc_specifier` lists (Izumi paths). 5 contvolcano files skipped.
Script: `scripts/stash_tsubset.py CASEDIR STASH BEG END [--dry-run]`. Not yet measured in a run.

**Phase 2 — to do (conservative regrid to ne30 + time cut):**
- `prescribed_strataero_file` (zm192, 12060 samples): window 1989-12..1991-01.
- `csw_specifier` DMS (f09, 4212 monthly 1750–2100): window 1999-12..2001-01.
- `tracer_cnst_file` oxid_1.9x2.5 1850clim: regrid only.
- `stream_ndep_data_filename` (f09, CDEPS stream): separate (stream mesh/mapalgo).
- ESMF conservative weights to `ne30np4_091226_pentagons.nc`, applied in Python, CDF5 with ncol/lat/lon/date/datesec.
  3-D CAMIOP runs and SCAM must both use the stash.
- CTSM: stash `init_generated_files/finidat_interp_dest.nc` once; set `finidat` to it with `use_init_interp=.false.`.

## 6. Environment notes (Izumi)

- Don't mix `module load lang/python/3.11.5` with conda (`unsetenv PYTHONHOME PYTHONPATH`).
- Izumi network/login instability: run long work as batch jobs.

## 7. Scripts

`bcinventory.py`, `stash_tsubset.py` (in `scripts/`); `readbench.py`, `skip_advtend_scam.py`,
`time_cam_init.py` are in `~/ss_tools` on Izumi/Derecho and should be added to `scripts/`.
