# scam-container handoff, 2026-11-10

## Where it stands

SCAM reproduces its 3D column **bit for bit with land, ocean and sea ice, with and without nudging,
and without a domain file**:

| Configuration | Result |
|---|---|
| ne30 container, nudged: Manus (ocean) | BFB (`sctc05`, and the earlier `SCT`s) |
| ne30 container: **Barrow** (land 0.35, sea ice 0.62 of the cell), nudged and not nudged | **BFB**: `TDIFF`/`QDIFF` 0 at all 8 steps, every atmosphere coupler field identical (hand-made pair, job 8133433) |
| ne3 classic path, no nudging: ocean, land (Sahara), coast (Gulf of Guinea), E Greenland and Canadian Arctic (land + ocean + sea ice) | **all BFB** (`sctn02`) |
| `PTS_DOMAINFILE=mesh` | fractions computed by the coupler are exactly the 3D run's (debug against debug) |

`compassdev` = `scam_container` = **`61f4cc3fc`** on GitHub. Izumi checkout
`/project/amp/jet/collections/cam6_4_207_compass.100926` pulled to it (CMEPS at `376b05d1`, verified).

## What changed since 2026-11-06

**CAM (`jtruesdal/CAM-1`, all pushed):**

| Commit | What |
|---|---|
| `be1f8bd14` | **Container fix**: the IOP-column read filled every GLL point of every element; `read_inidat` and `set_phis` then sum shared points over element edges, so state and `PHIS` were doubled (or more) at edge/corner points. Fill only `elem%idxP` unique points, as a normal read does. Manus and SGP are interior points in ne3, which is why nothing showed before; Darwin/Barrow are edge points (`TDIFF` ~273 K, `PHIS` x2 before the fix). |
| `5a2aa1e2a` `e0dd640cf` `401c0a4f2` | testmods `scm_prep_ERAnudge_derecho_{mesh,dom}_{manus,darwin,barrow,sgp}` (each includes `scm_prep_ERAnudge_derecho` and sets its column; `mesh_*` also `PTS_DOMAINFILE=mesh`) |
| `ba194747c` `aaf93122f` | testmods `scm_prep_F_ne3[_ocean,_land,_coast,_ice_greenland,_ice_canada]`: tiny ne3 `F2000climo_SROF` `SCT`, no nudging, mesh; base sets `ncdata` |
| `61f4cc3fc` | `components/cmeps` from `jtruesdal/CMEPS` tag `cmeps1.1.58_scammesh` |

**CMEPS (`jtruesdal/CMEPS` branch `scam_mesh_column`, tag `cmeps1.1.58_scammesh` = `376b05d1`, on `cmeps1.1.58`):**

| Commit | What |
|---|---|
| `98afb1ce` | `PTS_DOMAINFILE=mesh`: column = nearest element of `mesh_atm`; land/ocean fraction mapped from `mesh_mask` with DOCN's/CTSM's exact ESMF settings and thresholds (`esm_scol_fractions_from_mesh`) |
| `dd59b205` | `buildnml`/`namelist_definition_drv.xml`: pass `mesh_mask` in single-column mode when `PTS_DOMAINFILE=mesh` (it is `null` otherwise) |
| `376b05d1` | write the real `scol_*` attributes with `es24.16e3`: list-directed output kept ~15 digits, so CTSM/CICE got rounded lat/lon/area/fractions |

## Findings worth remembering

- **ESMF build matters**: the fraction mapping is decomposition-independent (ESMPy on 1 process = the
  3D run), but debug builds load `esmf-mpi/8.9.1-debug` and optimized builds `esmf-mpi/8.9.1`; their
  weights differ in the last bits. A SCAM run reproduces the fractions of a 3D run of the same build type.
- **The ne30 domain file is not exact everywhere**: Barrow `frac` 0.35071941973255427 vs 3D 0.35071941973255405.
  Mesh mode gives the 3D value. A domain-file `SCT` at Barrow is expected to fail.
- **`SCT` relies on matching `ncdata` defaults for SE**: at ne3 the 3D half gets
  `cam6_QPC6_topo_ne3pg3_mg37_L32_01-01-31_c221214.nc`, the `-scam` half
  `CESM2.F2000climo.ne3np4.cam.i.0003-06-01-00000.nc`. Fixed in the ne3 testmod; `sct.py` should copy
  case one's `ncdata` to the SCAM half for every dycore.
- **Nudging was never the problem**: the nudged Barrow `QDIFF` (1e-18 from step 1) was measured before
  the CMEPS digits fix; with all fixes the nudged pair is BFB.
- **Remaining last-bit residues, surface side only** (do not reach the atmosphere in these runs):
  CICE's own fluxes (`iceImp_Faii_*`, from the first coupling step; CICE area factors are 1 in both runs)
  and the coupler's atm->land mapping of rain/snow/deposition (`lndExp_*`).
- CAM tape 4 in the 3D Barrow case is single precision (only tapes 1-2 set to double): its comparisons
  in `cmp_pair.py` are not meaningful; the coupler history is double in both.

## Open

1. Recreate the ne30 column `SCT` set with all fixes (`scripts/scam_container/sct_columns.sh`, new ID;
   `sctx01` was deleted unrun because it predated the CMEPS digits fix).
2. Izumi: `SCT_D_Ln7.ne3_ne3_mg37.QPC6.izumi_gnu.cam-scm_prep_c6` vs the Izumi baseline; the same with
   NAG; one ne3 `F2000climo` test with GNU (needs the user's Izumi batch template for `create_test`).
3. `sct.py`: SCAM half takes case one's `ncdata` for every dycore.
4. CICE single column: `tarea = scol_area` (steradians) where the 3D path uses `mesh_area*R^2` (m^2);
   `ULAT = TLAT + pi`; the last-bit flux residue. CMEPS: atm->land mapping residue. Possibly issues upstream.
5. Older items: column-only CAMIOP extract; nudging-read timer; stash phase 2; scratch cleanup.

## Cases and test directories (Derecho)

- `BFB.barrow.3d.01`, `BFB.barrow.scam.01` (`/glade/campaign/cgd/amp/jet/cases`), nudging currently ON,
  coupler history every step, no archiving.
- `SCAM.ne30nudge.mesh.{01,manus.*,darwin.*,barrow.*}`: optimized mesh/domain comparison cases (superseded).
- Test IDs in `/glade/derecho/scratch/jet`: `sctn02` (ne3, all PASS, keep); `sctm01`, `sctd01`, `sctl01`,
  `sctn01`, `sctx01` (pre-fix or superseded, delete).
