# stormspeed-unify handoff, 2026-11-20

Covers 2026-11-18 evening to 2026-11-20: the GPU ladder (Check, Use, Resident) run and diagnosed, the Friday
talk, and the first look at the xDSL CAM-SIMA fork. Previous: `2026-11-18_stormspeed-unify.md`.

## Where the code is

- Derecho worktree `collections/stormspeed_sima.111626` (`$SIMA`), branch `stormspeed_sima`, local commits on top of
  `aae0aa2f` (GitHub), in order: GPU build path; localrc fix; shadow check (dyn->phys); drop NVHPC Kokkos-only test;
  shadow check (phys->dyn); 2b-1 device coupling ("Use"); 2b-2 resident mode ("Resident"); E1/E2 diagnostics;
  **one macro per device-coupling mode (fix lost -cppdefs)**; **E1b (compare remap inputs)**.
- Pushed for reading (WIP, not merged): `NCAR/StormSPEED` `stormspeed_sima_gpu_wip` (up to the E1/E2 diagnostics;
  re-push `git -C $SIMA push -f origin stormspeed_sima:stormspeed_sima_gpu_wip` to include the modes fix and E1b).
- `$SIMA/src/dynamics/se/homme`: branch `stormspeed_homme_02_wip` (pushed to `jtruesdal/E3SM`): on `stormspeed_homme.01`,
  `sort_mod` (qsort comparator as `c_funptr`), `cam_device_coupling`, `cam_skip_forcing_push` / `cam_skip_state_pull`.
- `$SIMA/ccs_config`: branch `nvhpc_kokkos_gpu` (pushed to `jtruesdal/ccs_config_cesm`).

## Device-coupling modes (testmods `cam/outfrq9s_thetal_kokkos_gpu_acc*`)

| Mode | Testmod suffix | Macro (in `se/cam_mods/gfr_device_modes.h`) | What it does |
|---|---|---|---|
| Ref | `_acc` | none | Fortran remap on the CPU, HOMME push/pull |
| Check | `_gfrcheck` | `SE_GFR_DEVICE_CHECK` | GPU remap alongside, compared every step; answers unchanged |
| Use | `_gfrdev` | `SE_GFR_DEVICE_COUPLING` | model uses the GPU remap; forcing copied back to Fortran and pushed |
| Resident | `_gfrres` | `SE_GFR_DEVICE_RESIDENT` (implies COUPLING) | GPU remap; HOMME push/pull off (pull kept on diagnostics steps); restart write endruns |
| diag | `_gfrres_keeppull` | `SE_GFR_DEVICE_RESIDENT_KEEP_PULL` | Resident with the pull on |
| diag | `_gfrdev_skippull` | `SE_GFR_DEVICE_USE_SKIP_PULL` | Use with the pull off |

**Lesson:** CAM's `bld/configure` keeps only the last `-cppdefs` (Getopt `cppdefs=s`). The chained testmods each
appended one, so `res1` (Resident) was built without `SE_GFR_DEVICE_COUPLING` (no device remap at all; tracers
zeroed by the ftype=2 adjustment with an unfilled FQ) and E2 (`e1`) keeppull built as the plain reference. Found
because keeppull was bit-for-bit identical to Ref. Each mode is now a single macro; check `env_build.xml`.

## Results (FKESSLER ne30pg2, NVHPC 25.9, 16 nodes x 4 A100, 64 ranks; all compared with cprnc)

| Test id | Case | Result |
|---|---|---|
| `nvgpu1` | FHISTC_LTso `_acc` | RUN FAIL: NaN in `Faxa_lwdn` at init (cam7 radiation with `-acc`; CAM's GPU test uses `-rad rrtmgp_gpu -microphys mg3`). Hypothesis. |
| `gfr2` | FHISTC_LTso `_gfrcheck` | same failure before the check ran |
| `dev1` | FKESSLER `_acc` (Ref) | RUN PASS |
| `dev1` | FKESSLER `_gfrdev` (Use) | RUN PASS; vs Ref: T 1.3 K RMS, CLDLIQ very different (explained by the forward T difference) |
| `chk1`, `e1` | FKESSLER `_gfrcheck` (Check) | physics->dynamics FT/FM/FQ roundoff; ps, phis, u, v, omega, q roundoff; **T max 1.62 K, rel 6.1e-3, same each step**. E1: not virtual temperature (vs Tf(1+zvir q) 1.74 K, reverse 4.99 K); worst at level 58, q = 0.0168, no condensate, ratio 1.0053 |
| `res1` | `_gfrres` | INVALID (lost -cppdefs) |
| `res2` | `_gfrres` (Resident) | RUN PASS; **IDENTICAL to Use (dev1 `_gfrdev`)** |
| `res2` | `_gfrres_keeppull` | RUN PASS; vs Resident differs at roundoff (PS 2e-14, T 3e-10 normalized). GPU runs are reproducible (tested earlier), so likely a side effect of the pull on GPU data; confirm with the rerun below |
| `res2` | `_gfrdev_skippull` | RUN FAIL step 3 `EOS bad state`. The push's extra components (FM 3rd, FVTheta, FPHI) are not computed from the state in CAM's Fortran, and Hommexx recomputes theta/phi forcing from `ft`, so the first explanation doesn't hold; cause open |
| rerun | `_gfrres.res2` again (job 8267191) | pending: compare with `~/res2_run1` copy, expect IDENTICAL |
| `e1b` | `_gfrcheck` + E1b | building/running: compares Hommexx's dp3d, vtheta_dp, phinh_i, Q (at its n0) with the Fortran state (at Fortran n0) and both sides' use_moisture / theta_hydrostatic_mode. Code reading shows both remaps use the same T formula (Rgas vtheta_dp exner / (R* dp), R* = Rgas + (Rv-Rgas) Q), the same hydrostatic p, the same dp-weighted remap, so the inputs are the next suspect |

## Friday talk (given)

Deck https://claude.ai/artifact/NdgyLFD6UxLCwTro21G3ov (20 slides; N = notes, F = full screen, P or `#presenter` =
synced presenter window). Speaker notes `friday_speaker_notes_v1.md`. Gemini tutor handoff `gpu_tutorial_handoff_for_gemini_v4.md`.
Learned at the meeting: the cam4 suite on GPUs with xdsl-ccpp managing data is one to two weeks away, cam5 about a week
after; MPAS will work toward the same with its convection-permitting suite.

## xDSL CAM-SIMA fork (read 2026-11-20)

- `johnmauff/CAM-SIMA` `xdsl-ccpp-adapter` (`ca30e9a`, base ESCOMP development `b942a2d`; #577 not in it); generator
  `johnmauff/xdsl-ccpp` (`d0e2f86`; the CONTINENTS-project original lacks the GPU support).
- `CCPP_GENERATOR=xdsl_ccpp` by default; GPU builds run it with `--directive acc`; device args from `memory_space = device`
  or inferred from the scheme's own OpenACC (`present`/`default(present)`); copies hoisted to each variable's lifetime;
  host vars with `model_var_memory_space = device` get `present()` (host owns the allocation).
- No CAM-SIMA state is declared device-resident yet: as read, the caps copy state to the GPU per step.
- Their changelog flags the hazard for us: hoisted `update self`/`update device` assume no host GPU code (a dycore)
  touches the device copy between suite calls.
- `GPU_SCHEME_STATUS.md` (Nov 19): bit-for-bit GPU vs CPU for 96/106 cam4, 80/96 cam5, 63/87 cam7 schemes. GPU tests
  compare with the nvhpc CPU build at zero tolerance (one node, 24 ranks).
- Design note for John Mauff: https://claude.ai/artifact/BCBjCvHa7CbYEBXbAG74zL (`gpu_dycore_xdsl_design_note_v1.md`):
  host-owned device-resident state, `phys` pointing at it, a dycore-boundary rule for hoisting, 7 questions, first joint
  milestone (theta-l_kokkos + cam4 on one GPU node).

## Next

1. E1b result; fix the T difference (needed for zero-tolerance GPU-vs-CPU tests in CAM-SIMA).
2. Rerun comparison (job 8267191).
3. Send the design note; inspect generated GPU caps from a fork build.
4. CAM-SIMA plan: one-day map of the ~60 CAM service modules the HOMME backend uses; then A1 on the fork.
5. Resident restarts (pull before writing) and dynamics-grid history.
6. Re-push WIP branches; later push/tag ccs_config `nh.07`, E3SM `stormspeed_homme.02`; PR #577 review; collections cleanup.

## Patches and scripts (md5)

`homme_cam_device_coupling.v1.patch` 392a97969fd179072535c4011f145c0a; `gpu_step2b2_resident.v1.patch` 78c2482143114ebfd3ef69a3b56f5227;
`homme_cam_skip_push_pull.v1.patch` 7565e845ffa6da7af3c1014081efd5db; `gpu_diag_e1_e2.v1.patch` 372c990d07a9aea2a0f2b5ae9df7f2a1;
`gpu_modes_cppdefs_fix.v1.patch` 86dcb9ecf779dbf2e2a159876403b8d1; `gpu_diag_e1b.v1.patch` a27ce26c08ed021f3bd1cc1c65b1c0dd;
`gfrres_test.v1.sh` d52580b254be624b3ad38da4bbe639cc; `diag_e1_e2.v1.sh` 41da16d775a33ce6bab367712e6b016e;
`resident_rerun.v1.sh` 787789006d532c77368bc0dcd18a9a02; `e1b_test.v1.sh` 3500145e5aa05171a42bb2492ae600bd.
