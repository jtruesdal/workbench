# stormspeed-unify handoff, 2026-11-16

## Where things are

| Repo / branch | Commit | Checkout (Derecho) | State |
|---|---|---|---|
| `NCAR/StormSPEED` `stormspeed_unify` | `d24da8cf` | `collections/stormspeed_unify.101626` | ss.07 merged; BFB |
| `NCAR/StormSPEED` `stormspeed_sima` | `b634df96` + "allocate phys_cols_t on the restart path too" | worktree `collections/stormspeed_sima.111626` (git dir in the unify checkout) | step 1 done, BFB |
| `jtruesdal/atmospheric_physics` `kessler_gpu` | `6d04a46` on ESCOMP `main` 592e2cc | `collections/atmos_phys_kessler_gpu.111626` | demo works on A100 |

All three were committed locally and the push commands were given. The check script (`checks/stormspeed-unify.sh`) shows whether each branch is still ahead of `origin`.

## Done this session

1. **Merged ss.07 (`407e0f79`) into `stormspeed_unify`.**
   - Three conflicts:
     - `.gitmodules`: `se/homme` now points at `jtruesdal/E3SM stormspeed_homme.01` (0aab3626);
     - `senh/dycore`: dropped;
     - `se/dyn_comp.F90`: kept unify's dispatcher, and moved the low-top sponge fix (`nu_scale_top(3)` 0.39) into `se/dycore/dyn_comp_impl.F90`.
   - Git's rename detection carried the hydrostatic-restart and `namelist_mod_cam` fixes into `se/cam_mods`.
   - Tests: ERS_Ln9 ne3pg3 FHISTC_LTso `thetal` and `thetal_hy` (derecho_intel), BFB against `stormspeed_3cb84acb_e3sm_intel` (`/glade/campaign/cgd/amp/jet/baselines_stormspeed`), restart PASS.
   - Removed the leftover `src/physics/clubb`.
2. **`stormspeed_sima` step 1.**
   - New `src/dynamics/se/phys_cols_mod.F90`: `phys_cols_t` holds the physics-column arrays (`ps`, `phis`, `t`, `u`, `v`, `omega`, `pdel`, `q`, `frontgf`, `frontga`, `vort4gw`) in CCPP order, in the host's physics-column order (`col_ind`). Intrinsic types only, so it carries no CAM dependency.
   - `se_backend_t%phys` is a pointer shared by `dyn_in` and `dyn_out`. It's allocated in `backend_init_model`, and in `backend_read_restart` too, since a restarted run initializes there.
   - Every wrapper hands `phys` to the impl containers (which got a `phys` pointer too).
   - `d_p_coupling` in both backends fills `phys` first; CAM's `phys_state` and pbuf copy then reads only from it.
   - Tests:
     - `sima1a`: ERS thetal vs `cam6_4_219_ss.07_e3sm_intel` (`/glade/campaign/cesm/community/StormSPEED`), all PASS.
     - `sima1b`: ERC_D `ne3pg3_mt233` FHISTC_LTso `cam-outfrq9s_mcsp` vs `cam6_4_219_intel`, BASELINE and restart PASS. NLCOMP fails as expected (the StormSPEED namelist difference).
3. **Kessler GPU demo** (`kessler_gpu` branch).
   - `kessler_run` is one `!$acc parallel loop gang vector default(present)` over columns. Its module constants are made available on the device with `declare create` and `update device`. The bad-time-split check became a reduction, reported after the loop.
   - Without `-acc` it is BFB with the original (checked with gfortran).
   - `test/gpu_resident_demo/`: the host driver owns device data (`enter data` once, `exit data` once), a stand-in dycore kernel runs on the device, then Kessler and an accumulation, all on the same device arrays.
   - A100 result (20,000 columns, 48 steps; nvhpc 25.9):
     - transfers: 12 at `enter data`, 7 at `exit data`, 3 for Kessler's constants, plus a 4-byte error count each way per step. **0 array transfers from `kessler.F90`.**
     - GPU vs CPU: roundoff (theta about 1e-15 relative, qc/qr up to about 1e-12 relative).
     - With `-gpu=nofma`: theta identical. FMA explains all of the theta differences; the GPU math library (`exp`, fractional powers) explains the rest.
   - GPU loop 0.16 s vs 35.6 s on one CPU core; not a benchmark.
4. **Design decisions agreed.**
   - **Option 2:** adopt EAMxx's design, not its code. CAM-SIMA's Fortran driver owns the device data; the dycore is two calls (`dyn_to_phys` through GllFvRemap `bind(C)`, `phys_to_dyn` through Hommexx forcing); `dp_coupling` disappears as a host stage. Importing EAMxx's C++ driver was rejected.
   - **Minimal backend:** each host computes its own derived quantities.
   - **Kessler first** for the all-on-device milestone (theta-l_kokkos + Kessler in CAM-SIMA). MPAS + Kessler is a possible shared milestone.
   - The earlier CAM-only "dycore on GPU, physics on CPU" stage (`stormspeed_gpu`) is dropped. The device path is CAM-SIMA only; CAM keeps `dp_coupling` for CPU physics.
5. **Documents** (claude.ai artifacts, private until shared):
   - unify deck (14 slides, incl. the CAM-SIMA plan): https://claude.ai/artifact/L3j1u8eT6VjmYbdj1wixoo
   - tutorial, "From CAM to GPU-resident CAM-SIMA" (stages 0-5, Gemini review points marked): https://claude.ai/artifact/3bHVSBr5cicpgrFBqtnP94
6. **Handed to stormspeed:** the #111 theory and test plan, in `handoffs/2026-11-16_unify-to-stormspeed_issue111.md`.

## Next

1. Push `stormspeed_unify`, `stormspeed_sima` and `kessler_gpu` if not done.
2. **`stormspeed_sima` steps**, each BFB with one small test per backend:
   - **step 2:** drop `pbuf2d` from the backend signatures; the gravity-wave fields reach CAM's pbuf from `phys` on the CAM side;
   - **step 3:** move the `phys_state`/`phys_tend` copy and the derived quantities (`derived_phys`, `derived_phys_dry`) into CAM's top-level `src/dynamics/se/dp_coupling.F90`. `physics_state` then leaves the backend; the tendencies come back through `phys` (`dtdt`, `dudt`, `dvdt` to add);
   - **step 4:** export metadata for the vertical coordinate (`vc_dry_pressure` or `vc_moist_pressure`) and whether `q` is wet or dry.
3. **Friday 2026-11-20 talk** (1 hour, about 30 minutes of talk). Audience: the cam4 GPU porters and the engineer porting MPAS to CAM-SIMA. A 14-slide outline exists in the chat. To do:
   - build the deck, with slide 12 using the Kessler results;
   - get the cam4 porters' programming model and compiler (OpenACC first? capgen-xdsl? Kokkos?) and whether data moves per scheme or at the cap level;
   - check whether CAM-SIMA builds MPAS with OpenACC. MPAS v8.4.0 has 1,032 `!$acc` in `mpas_atm_time_integration.F`, and CAM-SIMA's MPAS coupling already has argument-free `dynamics_to_physics_coupling()`.
4. **Toolchain spike:** nvfortran `-acc` plus nvcc/g++ Kokkos in one executable through ccs_config (HOMME C++ does not build with nvc++, 088ab323).
5. **Kessler demo v2:**
   - change `nvfortran --version` to `-V` (25.9 tries to link);
   - optionally keep the error count on the device;
   - add a small C++/Kokkos stand-in dycore through `bind(C)` (the Hommexx hand-off and layout question).
6. **Clean up** the `collections/` directories listed in `handoffs/2026-11-16_stormspeed-to-unify.md`.

## Gotchas learned (keep)

- **`git worktree` + `git-fleximod`.**
  - The sparse submodules came out as full checkouts. CAM-SIMA's `src/physics/utils/orbital_data.F90` then broke the build (`check_allocate`).
  - The `se/homme` clone hung with no git process.
  - Fix: a local `git clone --no-checkout` from the unify checkout's `se/homme`, plus `fix_sparse_submodules.v1.sh`, which installs each `fxsparse` pattern and runs `read-tree -mu HEAD`. Then delete `cam-sima`'s nested checkouts.
  - Next time, use a fresh clone.
- **Never `xmlchange` a case while `create_test` builds it** ("env_run.xml appears to have changed"). For premium, create with `--no-build`, `xmlchange JOB_PRIORITY=premium`, then build and submit.
- **Derecho GPU jobs:** `qcmd -q main -l job_priority=premium -l select=1:ncpus=4:ngpus=1:gpu_type=a100`. Use `bash -l` for `module`.
- **tcsh heredocs** with a quoted end word need the end line quoted too. Paste multi-line scripts in bash, or send them as files.
- **Baselines:**
  - current StormSPEED Derecho baselines: `/glade/campaign/cesm/community/StormSPEED/cam6_4_219_ss.07_e3sm_intel`;
  - older StormSPEED sets: `/glade/campaign/cgd/amp/jet/baselines_stormspeed`;
  - CAM: `/glade/campaign/cesm/amwg/soft_eng/cam_baselines/cam6_4_219_intel`.
