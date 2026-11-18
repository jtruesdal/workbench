# stormspeed-unify handoff, 2026-11-18

Workstream: one SE interface for CAM-SE and E3SM HOMME, CAM-SIMA readiness, and GPU residency.
Machine: Derecho. Worktree `/glade/campaign/cgd/amp/jet/collections/stormspeed_sima.111626` (`$SIMA`), branch `stormspeed_sima`.

## State of the branches

| Repo / branch | GitHub | Local (Derecho) |
|---|---|---|
| `NCAR/StormSPEED` `stormspeed_unify` | `d24da8cf` | same |
| `NCAR/StormSPEED` `stormspeed_sima` | `aae0aa2f` (steps 1-5) | `dea696cc` = + 5 GPU commits, **not pushed** (see below) |
| `$SIMA/ccs_config` (fork `jtruesdal/ccs_config_cesm`) | tag `ccs_config_cesm1.0.93_nh.06` | branch `nvhpc_kokkos_gpu` = `1197d92`, **not pushed** |
| `jtruesdal/E3SM` | `stormspeed_homme.01` (0aab3626) | `sort_mod` fix as a patch only (`homme_sort_mod_nvhpc.v1.patch`, md5 d78964aa1109c7b17900919175c16e94) |
| `jtruesdal/atmospheric_physics` `kessler_gpu` | `6d04a46` | same |

Local GPU commits on `stormspeed_sima` (oldest first): `b9fe78a5` GPU build path (NVHPC Fortran + Kokkos/CUDA);
`d59543dd` find NVHPC's localrc past compiler wrappers; `ff2eb483` device remap shadow check (dyn->phys);
`a3baa056` drop the NVHPC Kokkos-only GPU test; `dea696cc` shadow check phys->dyn.

## stormspeed_sima: dp_coupling taken apart (steps 1-5, all BFB, pushed)

Tests per step: `ERS_Ln9.ne3pg3_ne3pg3_mt232.FHISTC_LTso.derecho_intel.cam-outfrq9s_thetal` vs `cam6_4_219_ss.07_e3sm_intel`
and `ERC_D_Ln9.ne3pg3_ne3pg3_mt233.FHISTC_LTso.derecho_intel.cam-outfrq9s_mcsp` vs `cam6_4_219_intel` (NLCOMP fails by design).
Test ids sima1a/b ... sima6a/b; reusable script `sima_tests.v2.sh <id>` (create --no-build, premium, build, submit).

1. dycore fills `phys` (`phys_cols_t`); 2. pbuf + `check_energy_timestep_init` to CAM (`d_p_coupling_cam_finish`);
3. labels `vcoord`, `q_is_wet(:)`; 4a. `physics_state` copy, `derived_phys_dry` / `derived_phys_moist` (chosen by `phys%vcoord`),
aerosols, preqx `omega_over_p` into new CAM-side `se/dp_coupling_cam.F90`; debug hook `debug_phys_state`;
4b. return path through `phys` (`dtdt`, `dudt`, `dvdt`, `q_out`, `pdeldry_out`; CAM's `phys_tend_to_backend`), hook `debug_phys_tend`,
backend `stepon_run2/3` without CAM types; 5. abstract `atm_dynamics_t` (`src/utils/atm_dynamics_mod.F90`: `phys` +
deferred `dyn_to_phys`, `phys_to_dyn`, `run`), `phys_cols_mod.F90` moved to `src/utils`, `se_backend_t` -> `se_dynamics_t`
(module still `se_backend_mod`). Left in backends: the two debug hooks (Peter's test) and `register_pbuf`.

## GPU toolchain (spike, 2026-11-18)

`toolchain_spike.v1.tar.gz` (scratch `toolchain_spike/`): stage 1 GNU OpenACC offload FAIL (Derecho gcc 14.3 built without nvptx);
stage 2 Kokkos CUDA build PASS; stage 4 nvfortran + Kokkos PASS only with Kokkos built by nvcc using **NVHPC's own g++ 12.4**
(`localrc` GCCDIR); GCC 14-built Kokkos fails the nvfortran link (`__cxa_call_terminate`). 6 transfer events total, none at the
Kokkos call. nvc++ is not needed (Kokkos CUDA backend uses nvcc); the 30 Oct nvc++ failure (088ab323) is CPU-only.

## NVHPC GPU build path in StormSPEED

- `cime_config/buildlib`: `_nvhpc_gpu_host_cxx` (COMPILER=nvhpc and Kokkos_ENABLE_CUDA only) sets `NVCC_WRAPPER_DEFAULT_COMPILER`
  to NVHPC's g++ for the Kokkos build and HOMME's C++; finds `localrc` past the ncarcompilers wrapper (PATH, resolved paths,
  `NVHPC_ROOT`/`NCAR_ROOT_NVHPC`).
- ccs_config `machines/derecho/nvhpc_derecho.cmake` (branch `nvhpc_kokkos_gpu`): in the KOKKOS_GPU_OFFLOAD branch, CXXFLAGS
  replaced with nvcc/g++ flags + `-I$CRAY_MPICH_DIR/include`.
- HOMME `share/sort_mod.F90`: nvfortran rejects passing `cmp_ints` (bind(c, name='')) to the bind(c) dummy (NVFORTRAN-S-1009);
  fix passes `c_funloc(cmp_ints)` as `type(c_funptr), value`. Used as a case SourceMod (`~/inbox/sort_mod.F90`) until the fork is tagged.
- Tests (category `aux_cam_e3sm_gpu_nvhpc`, not in the gate): `SMS_Ln9.ne30pg2_ne30pg2_mt232.FHISTC_LTso.derecho_nvhpc.cam-outfrq9s_thetal_kokkos_gpu_acc`
  (`nvgpu1`: MODEL_BUILD PASS, 2371 s; run = job 8230212) and `..._gpu_acc_gfrcheck` (`gfr2`, job 8230960).
  The Kokkos-only NVHPC GPU test was dropped: it links with ccs_config's `-noacc` while objects carry OpenACC code.
- Practical: rerunning a failed test's build needs `./case.build --clean-all` (CIME resets the case); `create_test` outside a suite
  submits with 12 h walltime: `qalter -l walltime=01:00:00 <job>`; scripts for qcmd go in files (tcsh inside qcmd can't take
  multi-line quoted commands). Scripts: `nvgpu_rebuild.v3.sh <id> [suffix]`, `gfrcheck_test.v2.sh <id>` (copies the SourceMod).

## GPU step 1 + 2a: device remap shadow check (opt-in `-DSE_GFR_DEVICE_CHECK`, answers unchanged)

- `se/cam_mods/gfr_device_bridge.cpp` (`#ifdef KOKKOS_TARGET`): `gfr_device_init_c` creates GllFvRemap after `prim_init2` with its
  own FunctorsBuffersManager (the shared one is already allocated and can't grow), allocates `tracers.fq` first (CAM mode allocates it
  lazily at the first push); `gfr_device_dyn_to_phys_c`, `gfr_device_phys_to_dyn_c` (+ DSS), `gfr_device_compare_forcing_c`
  (push_forcing_to_c's index mapping).
- `se/cam_mods/gfr_device_check_mod.F90`: OpenACC device arrays in GllFvRemap layout; device gather to physics-column order and
  device scatter back (map from `get_dyn_col_p`); explicit-shape helpers for `host_data use_device` (gfortran rejects allocatables).
  Logs `gfr_device_check` (ps, phis, T, u, v, omega, q) and `gfr_device_check_return` (FT, FM, FQ) in `atm.log`.
- Sandbox-verified with stubs: layout/order of gather and scatter exact. Expect roundoff-level differences (C++ vs Fortran remap).

## Next: GPU step 2b (resident dycore)

HOMME fork: runtime switch read by `is_push_to_c_required` / `is_push_to_f_required` (`theta-l_kokkos/prim_driver_mod.F90`) to skip
the forcing push and the per-step state pull (keep the pull for output/diagnostic steps). StormSPEED: resident branches in `d_p`/`p_d`
(device remap, gather/scatter, one host copy of `phys` each way for CAM's CPU physics). Test with FKESSLER on a pg grid (cam7's
frontogenesis reads `elem`, so FHISTC_LTso can't be resident yet); dycore budgets / DYN_* history off or pulled on output steps.

## Documents (claude.ai artifacts)

- Friday deck: https://claude.ai/artifact/NdgyLFD6UxLCwTro21G3ov (update slides 6/11/15 with results)
- Peter walkthrough: https://claude.ai/artifact/9drxfY1AMVEazm4J7EKzy1; talking points: https://claude.ai/artifact/NyH3NnAJu2Ge3r6XVTci6T
- Earlier: unify deck L3j1u8eT6VjmYbdj1wixoo; tutorial 3bHVSBr5cicpgrFBqtnP94.
