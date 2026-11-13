# Handoff: stormspeed, shared-memory decision, cam6_4_221, HOMME PR, Izumi initialization (2026-11-13)

## Done since 2026-11-07
- **ss.07** tagged earlier (`cam6_4_219_ss.07` = 407e0f79, PR #116). **ss.08** branch `cam6_4_220_update` (0a791fb6,
  cam6_4_220 merged) in test: rounds started (Derecho qcmd 8157689-92, Izumi 821111-115); results not yet collected.
- **Shared-memory code (CAM #1643 = cam6_4_220, CTSM `shr_mpishmem_mod` since ctsm5.4.052): decision made.**
  Review found ~a dozen unhandled failure modes (silent wrong data, startup aborts, hangs, path asymmetries); email sent to
  the CAM and CTSM maintainers. **CAM maintainers agreed to revert** (CTSM's decision still open). StormSPEED keeps the
  code, with fixes, for its PIs (ss.09 plan below).
- **cam6_4_221** (revert of #1643, `git revert -m 1 00e7349f`): ESCOMP/CAM PR #1754 from `jtruesdal/CAM-1`
  `revert_pr1643` (b0d3a22a revert + 9674882e ChangeLog; reviewers cacraigucar, peverwhee). Code tree identical to
  cam6_4_219 (git diff and `diff -r` of the working trees). No regression tests rerun (approved). Baselines: `cam6_4_221_*`
  are **links** to `cam6_4_219_*` (Derecho soft_eng intel/nvhpc, Izumi pretag_bl gnu/nag; done). Cheryl merges with
  "bypass requirements" (two CI checks misnamed); then tag with `cam221_tag.sh` (checks parents 00e7349f/9674882e, code ==
  219, ChangeLog; tag message = merge commit message; `DRY=1` first). Checkout: Derecho
  `collections/cam6_4_220_revert_pr1643` (original 220 checkout kept as `cam6_4_220_ESCOMP` + `cam6_4_220.tar`).
- **TM error / Izumi shared windows** (investigation, root cause not found): inside cesm.exe on Izumi Intel/NAG
  (MVAPICH2 2.3.3) windows come back non-shared (`alloc_ierr=0 query_ierr=0 segsize=0 base_assoc=F`); small programs on
  the same stack share fine. Ruled out: library version alone, env vars, communicator type, window count (200), thread
  level, /dev/shm, communicator count (128), window size, prior node communicators. **Reproduced** in a small program:
  the second module's probe (CTSM after CAM's, CAM's table window live) fails at 24 ranks, passes at 12. Live-window test
  `win_test5.tar.gz` prepared (not run). The #106 comment's explanation ("bad address, fixed in 2.3.4") is NOT supported:
  correct it. Model runs tm_orig/tm_fixed/tm_soil (821129/30/32): outputs in ~/ss_tools/tm_model/*.out, not reviewed.
- **HOMME / E3SM**: PR E3SM-Project/E3SM#9154 has 0aab3626 + **7a890a59** (GPTL args `integer(c_long_long)` + zeroing;
  METIS weights `c_float`; author jet@ucar.edu). Tested in StormSPEED via SourceMods: Derecho Intel SMS_D/ERS(+restart),
  GNU SMS_D; Izumi NAG/Intel/GNU SMS_D: all BFB with gate baselines. Kind audit of all CAM-built HOMME Fortran done
  (149 bind(c) routines / 619 args all C kinds; LAPACK externals OK). Copilot's 2nd comment (FrameWeight kind) is moot:
  **E3SM will remove METIS (#9161)**; PR **paused**, user forks until **round 2**. Round-2 branch
  `jtruesdal/E3SM` `stormspeed/homme_round2` = 6e089864 (adds preqx `print_software_statistics` GPTL fix, same as
  compose_test_mod). StormSPEED stays on `stormspeed_homme.01`.
- **Izumi initialization (the Izumi bottleneck)**: Derecho ne3pg3 FHISTC_LTso thetal Intel: init 182 s debug / 118-128 s
  optimized; CAM init (`[ATM] IPDv03p3`) 79 s + first physics pass 20 s + CTSM `init_interp` 12 s; debug adds little.
  Izumi: emission setup ~100 s per file. **Cause**: CMIP6 emission files are classic netCDF with an UNLIMITED time
  dimension, so reading the time coordinate touches the whole file (707 MB: 107 s cold, 0.2 s cached); nfs-fs RTT 100-240 ms
  (nfs-amp 3-4 ms), ~30 MB/s, our two jobs took a large share. `nccopy -u` copy: identical data (checked), time read
  0.016 s. Also: `tracer_data` opens every emission file twice (to investigate). Test run times vary 1000-8200 s
  (NAG SMS_D) with cache/load.

## In progress on Izumi (as of this handoff)
- **Mirror** `/project/amp/jet/inputdata_fast` (mk_fastroot.sh, serial, job 821224): links to /fs/cgd/csm/inputdata except
  the 47 classic files with UNLIMITED dims from the case's atm_in (60 GB, 40 CMIP6 emission files 55 GB) as `nccopy -u`
  copies. Use: `./xmlchange DIN_LOC_ROOT=/project/amp/jet/inputdata_fast`. Check: 47 files, `~/ss_tools/fastroot/mk.out`.
- **Inventory** (inv_inputdata.sh, read-only version, job 821223) of /project/amp/jet/inputdata (60 GB: 169 unique, 1 dup)
  and inputdata.sav (248 GB, mostly dup so far) vs /fs/cgd/csm/inputdata; lists in ~/ss_tools/fastroot/inv/. Then
  **del_dups.sh** (guarded: refuses links, linked directories, files resolving into the central tree, same inode, size
  change; dry run unless DELETE=1). Then check the `unique` lists against /glade inputdata (checksums, script to write).
- After the mirror: rerun the built Izumi Intel hfx case against the mirror (command in chat: `intel_mirror` job, ESMF
  profile on) vs 4124 s before; then `itim.tar.gz` (optimized GNU, 2 runs, ESMF profile) with and without the mirror.
- `preqx_nag.sh` (two NAG builds of `cam-outfrq9s_preqx`, with/without the preqx fix): preqx never built in StormSPEED,
  failures elsewhere possible; informative only.

## Next
1. Tag **cam6_4_221** after Cheryl's merge (`env DRY=1 bash ~/ss_tools/cam221_tag.sh <clone>`, then without DRY).
2. Finish Izumi speed-up: mirror, before/after timing, then use the mirror for Izumi test rounds; report nfs-fs
   (RTT 100-240 ms) to CGD IS; note to CESM inputdata maintainers (convert classic UNLIMITED files); `tracer_data` double opens.
3. ss.08: collect results (Derecho + Izumi), ChangeLog, PR, review summary, merge, tag `cam6_4_220_ss.08`, rename gate
   baselines. **When StormSPEED later merges cam6_4_221, keep StormSPEED's shared-memory code** (the merge deletes it).
4. **ss.09**: replace `src/utils/cam_shmem_mod.F90` with the fixed module (shmem_fix.tar.gz, md5 f947344076a0ddb7181fcfbd049765d7;
   diag versions in tm_diag.tar.gz) and CTSM fork tag `ctsm5.4.057_nh.02` with fixed `shr_mpishmem_mod.F90` (first
   understand the 24-rank CTSM probe failure) + a CTSM env-var escape hatch; gate BFB vs ss.08; add shared-vs-private
   (`cam_shmem_force_private`) BFB test on Derecho; wiki section for PIs.
5. MPI test suite for the shmem modules (per-behaviour cases, fault injection, timeouts, per-machine scripts; no pFUnit:
   CESM's pFUnit on Derecho/Izumi is Intel-only, noMPI).
6. Correct the #106 comment; close #106 after ss.09. Wiki: ss.07/ss.08 Tag Notes, Known Issues (Izumi init, MVAPICH2).
7. HOMME round 2 after E3SM's METIS removal: rebase `stormspeed/homme_round2`, drop metis_mod hunks, retest, new PR.

## Tools (~/ss_tools on both machines unless noted)
cam221_revert.sh, c221_changelog.sh, cam221_tag.sh (e9eb90837b6aae52) | hfx_test/ (HOMME follow-up tests; ONLY=, rerun)
| fastroot/ (mk_fastroot.sh f73a43b8... parallel version unused; serial e5f7c938 running; inv_inputdata.sh;
del_dups.sh 8590992f) | itim/ | preqx_test/ | tm_test/, tm_model/, win_test/ (shmem investigation)
