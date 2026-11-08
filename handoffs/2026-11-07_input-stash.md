# Handoff: input-stash (SCAM-friendly input files) -> scam-container chat (2026-11-07)

From the stormspeed chat, which did this work on 2026-11-04. The work now continues in the scam-container
chat, which has an optimized, timed ne30 nudged SCAM case on Derecho to measure it with.

## Why

SCAM initialization was dominated by reading boundary/emission data: long time series (CMIP6 emissions 1750-2015,
monthly) and files interpolated at run time (zonal-mean and lat-lon files). Baseline from the scam-container chat
(ne3 container SCAM, debug, `bc992bf` timers): `cam_init_phys_init` 123 s, of which `pi_chem` 101 s
(chemistry/emission reader setup) and `pi_prescribed` 21 s (prescribed ozone, aerosols, volcanic and
stratospheric aerosols). `scripts/scam_container/profile_tree.py` prints these timers.

## Done (phase 1, Izumi)

- **Stash directory (Izumi):** `/project/amp/jet/scam_stash/f2000_cyc2000/` (185 MB, vs about 30 GB for the
  originals): 32 native-ne30 (`ncol48602`) CMIP6 emission files from the case's `srf_emis_specifier` and
  `ext_frc_specifier`, time-subset to 16 of ~3180 samples (1999-11-16 .. 2001-02-15), CDF5, named
  `<original>_t19991201-20010131.nc`.
- **Window:** 19991201-20010131, because F2000climo runs these emissions `CYCLICAL` with cycle year **2000**
  (`srf_emis_cycle_yr = ext_frc_cycle_yr = 2000`), not the calendar years of the nudged runs. One bracketing sample
  is kept on each side.
- **Verified:** every copy compared with its original by `stash_tsubset.py` (sample time slices of every
  time-dependent variable and all non-time variables, NaN-aware): **identical**. So results with the stash must be
  bit-for-bit with the originals.
- **`user_nl_cam.stash`** in the stash directory: the case's full `srf_emis_specifier` and `ext_frc_specifier`
  lists with the 32 stash paths substituted (**Izumi paths**). 6 entries still point to inputdata: the 5
  `contvolcano` files (108 samples each, skipped by design, `--min-times 200`) and one small file below the
  inventory cutoff.
- Generated from the Izumi test case `SCT_D_Ln48.ne30_ne30_mg17.F2000climo_SROF.izumi_intel.cam-scm_prep_ERAnudge_izumi.ndgiz01`
  (its `run/atm_in` and `Buildconf/cam.input_data_list`).

## Not done yet

1. **Measure phase 1** in a SCAM run (and its 3-D CAMIOP twin): append `user_nl_cam.stash` to both cases'
   `user_nl_cam`; expect bit-for-bit answers and a lower `pi_chem`. Not yet run anywhere.
2. **Derecho copy:** the stash and `user_nl_cam.stash` exist only on Izumi with Izumi paths. Easiest: rerun
   `stash_tsubset.py` against a Derecho case (writes Derecho paths); or copy the 185 MB and edit the paths.
   Where it should live on Derecho (and whether shared) is open.
3. **Phase 2, not started** (pre-interpolate to ne30 + time cut; values then differ slightly from CAM's runtime
   interpolation, so the 3-D CAMIOP runs and SCAM must both use the stash):
   - `prescribed_strataero_file` ozone_strataero_CAM6chem_1849-2014_zm_5day (zonal mean, 192 lat, 12060 5-day
     samples): **cycle year 1990** -> window 1989-12..1991-01; broadcast zonal mean to lat-lon, then conservative to ne30.
   - `csw_specifier` DMS (f09, 4212 monthly samples 1750-2100): cycle 2000 -> window 1999-12..2001-01.
   - `tracer_cnst_file` oxid_1.9x2.5 1850 climatology (12 months): regrid only.
   - `stream_ndep_data_filename` (f09, CDEPS stream): separate; stream mesh / `stream_ndep_mapalgo` instead of a
     CAM reader.
   - Method agreed with the user: **conservative** (mass-preserving; essential for aerosols/emissions) via ESMF
     weights (`ESMF_RegridWeightGen --method conserve`, or existing `cpl/gridmaps/*_TO_ne30np4_aave*` maps) to the
     ne30 dual grid **`ne30np4_091226_pentagons.nc`** (the user has it), applied in Python (scipy.sparse) together
     with the time cut, writing `ncol`, lat/lon, `date`/`datesec`, CDF5. Check each reader accepts `ncol` files.
4. **CTSM `finidat`** (f09 initial file on ne30 -> `init_interp` at every startup): stash
   `init_generated_files/finidat_interp_dest.nc` once (depends only on source finidat + grid/surface data) and set
   `finidat` to it with `use_init_interp = .false.` in `user_nl_clm`. The user notes CTSM may reuse an existing
   interpolated file automatically; an explicit path is safer with per-member run directories.

## Findings that rule things out

- All large CAM input files are classic / 64-bit offset: file format is not the problem.
- ERA5 nudging files (`/glade/campaign/cesm/stormspeed/ERA5_nudging_input_1h/2002-2008/ne30np4/L32/`, netCDF-4,
  contiguous, uncompressed): open 0.10 s, one column of T,Q,U,V,PS 0.33 s cold (`readbench.py`): not the bottleneck.
- Inventory (`bcinventory.py`, Izumi test case, files >= 50 MB): 49 files, 48.5 GB.

## Open questions

- Does phase 1 actually reduce `pi_chem`, or is the time in reader setup rather than the time axes?
- Should the PPE keep F2000climo's cycle-year-2000 emissions for 2002-2008 nudged runs (it does now)?
- Shared stash location on Derecho and Izumi (team use).

## Scripts

| Script | Where | What |
|---|---|---|
| `bcinventory.py` | workbench `scripts/` (also `~/ss_tools` on Izumi) | inventory of a case's input files: grid type, samples, dates, size, namelist variable |
| `stash_tsubset.py` | workbench `scripts/` (also `~/ss_tools`) | phase 1: time-subset ncol files, verify identical, write `user_nl_cam.stash`; `--dry-run` first |
| `readbench.py` | workbench `scripts/` (added with this handoff; the original lives in `~/ss_tools` on Derecho) | time open / one-column / whole-field reads of netCDF files |
| `time_cam_init.py`, `skip_advtend_scam.py` | `~/ss_tools` (Izumi) | one-off edits, already committed on `scam_container` (`b268622`); not needed again |

Environment: on Izumi use `lang/python/3.11.5` or a conda env (`datasci_sm`, `scamppe`), never both. Phase 2
needs `esmf` and `scipy` (`conda install -c conda-forge esmf scipy nco` into the env used).
