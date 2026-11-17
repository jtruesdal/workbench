# Handoff: stormspeed-unify -> stormspeed, GPU restart failure (NCAR/StormSPEED#111), 2026-11-16

## What is known

The failing test is `ERS_Ln9.ne30pg2_ne30pg2_mt232.FHISTC_LTso.derecho_gnu.cam-outfrq9s_thetal_kokkos_gpu` (Derecho A100). The failure was reported in the stormspeed chat:

- `SMS_Ln9` PASS on the GPU.
- GPU runs are deterministic: two runs from the start gave identical total energy at every step.
- `ERS_Ln9` FAIL: the restarted state reaches the GPU exactly (identical energy at the first restarted step), but the first dynamics step after the restart differs slightly.
- CPU theta-l_kokkos `ERS_Ln9` PASSes (ne3pg3 and ne30pg2, Derecho Intel/GNU, in the gate).

Where it was analyzed: the stormspeed-unify chat read the HOMME pin `jtruesdal/E3SM stormspeed_homme.01` (0aab3626). File paths below are under `components/homme/src/`.

## Theory: first-step diagnostics write into memory the dynamics also uses

This is a hypothesis; it has not been confirmed.

1. **The restarted run computes diagnostics where the continuous run does not.**
   `share/cxx/prim_driver.cpp:90-95`:
   `compute_diagnostics = !disable_diagnostics && (nstep_end % state_frequency == 0 || tl.nstep <= tl.nstep0 + (nstep_end - tl.nstep))`.
   `nstep0` is reset at every (re)start. So the restarted run calls `Diagnostics::run_diagnostics` on its first steps after the restart. The continuous run does not at that step: it computes diagnostics only at its own start and every `statefreq` steps.
   The calls are in `prim_driver.cpp:97-99, 127-129, 143-145, 166-168` and inside the step in `theta-l_kokkos/cxx/prim_advance_exp.cpp:109-112, 127-130`, around the hyperviscosity call.
   This is also why the energy at the first restarted step can be printed and compared at all.

2. **The diagnostics write into shared scratch memory.**
   `theta-l_kokkos/cxx/Diagnostics.cpp:73-97` places `pnh`, `exner`, `phi`, `dp_ref`, `dpnh_dp_i` and `phi_i` in the shared pool (`fbm.get_memory()`). The dynamics functors use the same pool, for example `DirkFunctorImpl.hpp:133`. If any functor reads a buffer, or a borrowed derived field, expecting content it left there earlier, an intervening diagnostics call changes what it reads. The result would be a slightly different but converged answer: the observed symptom.
   A place to look: `DirkFunctor` stashes its Newton initial guess in `m_derived.m_divdp_proj` (`DirkFunctorImpl.hpp:226, 316-322`). That field is borrowed as scratch.

3. **Why it would be GPU-only.** The pool is cut into per-slot pieces, and the number of slots follows the hardware: concurrent teams on a GPU, threads on a CPU (1 here). The overlap between the diagnostics' arrays and the functors' arrays is therefore different on the GPU. That would explain the CPU ERS passing.

4. **Why the determinism check could not see it.** Two runs from the start execute identical diagnostics at identical steps.

## Proposed testing strategy (cheapest first)

**E0. Small reproduction (optional, saves 16 nodes).**
Run the same ERS at ne3pg3 (or ne16pg3) on a single GPU node: 4 ranks, `NGPUS_PER_NODE=4`, `KOKKOS_GPU_OFFLOAD=TRUE`. Note that with fewer than 64 tasks CIME picks `develop`, which has no GPUs, so also set `./xmlchange JOB_QUEUE=main --force`. If it reproduces small, use it for E1-E4.

**E1. Decisive: switch HOMME diagnostics off.**
`disable_diagnostics` is not in CAM's namelist. It is hard-coded in `src/dynamics/senh/cam_mods/namelist_mod.F90:474` (on `stormspeed_unify`: `src/dynamics/se/cam_mods/namelist_mod.F90:474`).
- Create the GPU ERS case with `create_test --no-build`.
- Copy that file to `SourceMods/src.cam/` with `disable_diagnostics = .true.`.
- Build through `qcmd` and submit.
- The energy printouts stop too, so judge by ERS's history comparison (`COMPARE_base_rest`).

Reading the result:
- **ERS PASS**: the first-step diagnostics are the trigger. Continue with E3.
- **ERS FAIL**: go to E2.

**E2. If E1 still fails: find the hidden state.**
- Add a debug call after the restart initialization and after the first step that pulls *all* C++ views to Fortran (`cxx_push_results_to_f90`, all time levels, not the `_tl` variant), and prints a per-array checksum. That covers state at every time level, `derived` fields and the forcing arrays.
- Do the same in the continuous run at the same model step.
- The first array that differs points at what the restart does not reproduce. The likely classes:
  - a non-`n0` time level used as an initial guess;
  - a `derived` field carried between steps;
  - data modified through a host mirror without a `deep_copy`. That class is GPU-only by construction, because on a CPU the Kokkos mirror *is* the device view.

**E3. If E1 passes: name the culprit.**
- Re-enable diagnostics, but turn off only the calls inside `prim_advance_exp.cpp` (positions 4 and 5) with a HOMME SourceMod. If ERS then passes, the reader is in the hyperviscosity step or right after it.
- Look for functors that read a pool buffer or a borrowed `m_derived` field before writing it in the same call.
- The fix belongs in the fork (`jtruesdal/E3SM`). It would be a candidate for HOMME round 2/3 and upstream E3SM: either give Diagnostics its own memory, or make the reader initialize its buffer.

**E4. Regression check for the fix.**
- GPU ERS passes;
- GPU SMS answers are unchanged;
- CPU theta-l_kokkos gate tests stay BFB.

## Not useful for this issue

The planned GPU Kessler demo (stormspeed-unify) has no dycore and no restart state, so it cannot reproduce #111. It stays in stormspeed-unify for the GPU-residency work.
