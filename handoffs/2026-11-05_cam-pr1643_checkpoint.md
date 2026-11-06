# cam-pr1643 checkpoint, 2026-11-05 (evening)

Supersedes the plan in `2026-11-05_cam-pr1643.md` (sections 2-4): the SHM test is dropped and the
PR route changed. That handoff also named the fork `jtruesdal/CAM`; it is **`jtruesdal/CAM-1`**.

## Where it stands

Work branch `jtruesdal/CAM-1` `pr1643_shmem` = `ceb71700`:

| Commit | What |
|---|---|
| `948c578c` | PR #1643 head (`sjsprecious/CAM` `fix_ne1024_init_oom`, unchanged) |
| `3410e688` | cherry-pick of StormSPEED `44cb2d12`: init probe of MPI-3 shared windows; if any rank cannot see the leader's window, every rank becomes its own "node" (private copies, callers unchanged). `cam_shmem_nl` / `cam_shmem_force_private` (default `.false.`). `cam_shmem_init` after `read_namelist`. |
| `d55e63db` | merge of `cam6_4_218` (clean; 15 files vs the tag, nothing under `cime_config`) |
| `1ae0e111`, `ceb71700` | comments and namelist description: `force_private` is a fail-safe; description cut to its first sentence |

Checkouts (branch `fix_ne1024_init_oom` tracking the work branch; remotes `jt`, `jian`, `ss`):
Derecho `/glade/campaign/cgd/amp/jet/collections/cam_pr1643`, Izumi `/project/amp/jet/collections/cam_pr1643`.

## Decisions

- Node-shared memory stays **on by default**, as in Jian's PR (it is unconditional in `phys_prop`,
  `mo_jlong`, `soil_erod_mod`, `tracer_data`). `stream_ndep_mapalgo` (default `bilinear`, `redist` opt-in)
  is a separate PR feature, unrelated to `cam_shmem`.
- Keep `cam_shmem_force_private` as a fail-safe; it has no default entry, so it is not written to atm_in.
- **No new regression tests** (StormSPEED `87731ef2`, `af5051b1` dropped) and no testmod changes. Check
  by hand in the aux_cam logs: GNU and Derecho `probe PASSED` / `node-shared tables enabled`; NAG
  `probe FAILED` / `falling back to per-rank private memory`. BFB is left to the baseline compares.
- PR route: open a PR `jtruesdal/CAM-1:pr1643_shmem` -> `sjsprecious/CAM:fix_ne1024_init_oom` so Jian
  can review (he merged the user's previous PR there himself, Oct 14). The user has write access and
  can merge it if Jian does not respond.
- Izumi Intel is not a CAM regression platform.

## Evidence so far (Izumi, cam6_4_218 + branch, `SHM_D_Ln9.ne3pg3_ne3pg3_mt232.FHISTC_LTso.cam-outfrq9s`, before the SHM commits were dropped)

| Compiler | Probe | `COMPARE_base_private` |
|---|---|---|
| GNU | PASSED (24 ranks), node-shared | PASS (shared vs private BFB) |
| NAG | FAILED (peers got no address from `MPI_Win_shared_query`), fallback | PASS |
| Intel | FAILED, fallback; then SIGSEGV in init at the `ozone_strataero` read (no `-heap-arrays` in ESCOMP `ccs_config`) | not reached |

So the fallback is needed for plain CAM on Izumi's MVAPICH2 builds, not caused by StormSPEED (#106).
Cases are in `/scratch/cluster/jet/SHM_D_Ln9.*.pr1643shm`; job script `~/ss_tools/pr1643_shm.sh`.

## Running (see `checks/cam-pr1643.sh`)

- Izumi `aux_cam` GNU (job 820166) and NAG (820167) on `1ae0e111`, vs `/fs/cgd/csm/models/atm/cam/pretag_bl/cam6_4_218_{gnu,nag}` (25 / 16 tests).
- Derecho `aux_cam` Intel (8081882) and NVHPC (8081883) on `ceb71700`, vs
  `/glade/campaign/cesm/community.OLD/amwg/cam_baselines/cam6_4_218_{intel,nvhpc}` (56 / 1).
- Expected: BFB everywhere. NLCOMP differences only from `stream_ndep_mapalgo = 'bilinear'` (written by
  build-namelist for ndep-stream configurations). Derecho Intel `...outfrq9s_rttov` FAIL is expected
  (rttov library moved by CISL, ESCOMP/CAM#1745, listed in the cam6_4_219 ChangeLog).

## Open: cam6_4_219

`cam6_4_219` (`eb11a0b3`, PR #1743, PUMAS bug fixes, answer-changing for PUMAS runs; moves
`archive_baseline.sh` to `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`) was tagged after the suites
started. Merging it into `ceb71700` is clean in the sandbox. Options: keep the 218 results as the BFB
evidence and merge 219 before opening the PR; or merge 219 and rerun all four suites vs 219 baselines.

## PR description draft (fill in the TBDs)

```markdown
## Shared-memory probe and per-rank fallback; update to cam6_4_218

This updates the branch for ESCOMP/CAM#1643 with a fail-safe for platforms where
MPI-3 shared windows do not work, and merges `cam6_4_218`.

### Why
On Izumi with the MVAPICH2 builds used by NAG and Intel, `MPI_Win_allocate_shared`
succeeds but `MPI_Win_shared_query` gives non-leader ranks no address (size 0, null
pointer). The node-shared tables in `phys_prop`, `mo_jlong`, `soil_erod` and
`tracer_data` are then null on all but one rank per node. This was first seen in
StormSPEED (NCAR/StormSPEED#106) and reproduced here with plain cam6_4_218 + this PR.

### Changes
- `cam_shmem_mod`: at init, a small collective probe allocates a shared window and
  checks that every rank can see it. If any rank cannot, every rank becomes its own
  "node" (node_size 1, all ranks leaders), so callers hold private copies and their
  leader broadcasts reach every rank. Callers are unchanged; answers are unchanged.
  The atm log reports `probe PASSED` / `probe FAILED` and which mode is used.
- New namelist `cam_shmem_nl` / `cam_shmem_force_private` (default `.false.`) as a
  fail-safe to turn sharing off. It has no default entry, so it is not written to
  atm_in unless set in user_nl_cam.
- `cam_shmem_init` is called after `read_namelist` (so the switch is known).
- Merge of `cam6_4_218`.

Node-shared memory stays on by default, as before.

### Testing
Probe on Izumi (cam6_4_218 + this branch). Each case was built once and run twice,
default vs `cam_shmem_force_private=.true.`, with history compared; this used a
temporary test (StormSPEED's SHM test type) that is not part of this PR.
Test: `ne3pg3_ne3pg3_mt232.FHISTC_LTso`, `outfrq9s`, debug.

| Platform | Probe | Mode | Default vs private |
|---|---|---|---|
| Izumi GNU (MVAPICH2) | PASSED | node-shared | BFB |
| Izumi NAG (MVAPICH2) | FAILED | per-rank fallback | BFB |
| Izumi Intel (MVAPICH2) | FAILED | per-rank fallback | run stops later in init without `-heap-arrays` (known Izumi Intel limitation; not a CAM test platform) |

Regression tests vs cam6_4_218:
- Izumi `aux_cam` GNU: TBD
- Izumi `aux_cam` NAG: TBD
- Derecho `aux_cam` Intel: TBD
- Derecho `aux_cam` NVHPC: TBD

Expected: all BFB. Namelist differences only from `stream_ndep_mapalgo = 'bilinear'`
(already part of this PR) for configurations with the ndep stream.

### Commits
- `3410e688` cam_shmem_mod: verify MPI-3 shared windows; fall back to per-rank memory
  (cherry-picked from NCAR/StormSPEED `44cb2d12`)
- `d55e63db` Merge tag 'cam6_4_218'
- `1ae0e111`, `ceb71700` comment and namelist-description cleanups
```
