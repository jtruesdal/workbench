# Handoff: stormspeed -> stormspeed-unify (2026-11-16)

For the chat working on `NCAR/StormSPEED` branch **`stormspeed_unify`** (CAM's se dycore and the E3SM
dycores under one `src/dynamics/se` interface), newly brought into the CAM / SCAM Project.

## 1. How the Project's chats stay in sync (read `WORKFLOW.md` for the full rules)
- **Start of every chat**: read `STATUS.md` and the latest handoff for your workstream from
  https://raw.githubusercontent.com/jtruesdal/workbench/main/ ; confirm workstream, machine and branch with the user.
- **One workstream per chat.** Something belonging to another row goes into that row's **Inbox** (in `STATUS.md`)
  as a short note, not done here. Clear Inbox items addressed to you once handled.
- **End of a session**: propose the `STATUS.md` update (your row; plus Inbox notes) and, for larger transitions,
  a `handoffs/YYYY-MM-DD_<workstream>.md`, as a patch the user applies, commits and pushes.
- **Your first end-of-session patch should add your own row** (`stormspeed-unify`): repo/branch, checkouts by absolute
  path, machines, state, next steps, latest handoff.
- **Conventions**: tcsh login shell (`source ~/workbench/scam_env.csh`; wrap bash syntax in `bash -c '...'`, redirect
  with `>&`); absolute paths or `git -C`; `git --no-pager`; one command step per turn with the expected output; short
  command lines (long ones overflow the terminal; use a small script file instead); builds never on a login node
  (Derecho `qcmd`, 5 h for test suites; Izumi batch jobs, no extra interactive jobs); Derecho jobs at premium priority;
  the AI never pushes, tags or writes official baselines; it keeps its own sandbox clone and dry-runs everything there;
  **every downloaded file gets a new name and a checksum**; **clean up as you go** (`scripts/clean_check.sh`,
  `keep_inspect.sh`, `archive_local.sh`); every StormSPEED PR merge gets a review-summary comment.

## 2. StormSPEED state (as of this handoff)
- `stormspeed` = **`cam6_4_219_ss.07`** (407e0f79). Tags `<CAM tag>_ss.NN`, ss number continuing; each PR adds an
  entry to `doc/ChangeLog_stormspeed` (see the wiki's SE Workflows page for the tag procedure).
- **ss.08 in test**: branch `cam6_4_220_update` (0a791fb6) = ss.07 + CAM `cam6_4_220` (node-shared memory code:
  `src/utils/cam_shmem_mod.F90` and shared paths in `tracer_data`, `phys_prop`, `mo_jlong`, `soil_erod_mod`, plus
  finalize hooks, `runtime_opts`, namelist `cam_shmem_force_private`). Not yet PR'd or tagged.
- **CAM reverted that code in `cam6_4_221`** (2026-11-13). StormSPEED **keeps** it (ss.09 = fixed modules). So when
  StormSPEED (or unify) merges `cam6_4_221` or later, keep StormSPEED's shared-memory code: the merge tries to delete it.
- **Bringing unify up to the stormspeed head**: expect conflicts where ss.08 touched files (the list above) and wherever
  unify moved `senh` files to `se`; ss.08's 7 changed files vs ss.07 are the 5 shared-memory files, a namelist
  description and `doc/ChangeLog` (CAM's own entry for `cam6_4_220`; StormSPEED's entries are in `doc/ChangeLog_stormspeed`).
- **HOMME**: pinned submodule from the fork `jtruesdal/E3SM`, tag **`stormspeed_homme.01`** (0aab3626, NAG portability
  fixes). Upstream PR E3SM-Project/E3SM#9154 is **paused** until E3SM removes METIS (#9161); round 2 later from branch
  `stormspeed/homme_round2` (6e089864, adds a preqx GPTL fix). Keep the pin unless the unify work needs otherwise.
- **CTSM**: fork `jtruesdal/ctsm` tag `ctsm5.4.057_nh.01`; **ccs_config**: fork tag `nh.06`.

## 3. Testing and baselines
- **Gate** (E3SM-dycore theta-l tests): Derecho Intel and GNU; Izumi GNU, NAG and Intel (NAG is important).
  Representative test: `SMS_D_Ln9.ne3pg3_ne3pg3_mt232.FHISTC_LTso.<mach>_<comp>.cam-outfrq9s_thetal`.
- **Baselines**: Derecho shared area **`/glade/campaign/cesm/community/StormSPEED`** (`cam6_4_219_ss.07_e3sm_{intel,gnu}`
  = current; also `cam6_4_211_ss.04/.06_e3sm_*`); older ones in `/glade/campaign/cgd/amp/jet/baselines_stormspeed`.
  Izumi: `/project/amp/jet/baselines_stormspeed` (`stormspeed_3cb84acb_e3sm_{gnu,nag,intel}`, the ss.07 gate).
  CAM's own baselines (aux_cam): Derecho `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`, Izumi
  `/fs/cgd/csm/models/atm/cam/pretag_bl`.
- **Proving unify BFB**: compare unify's gate runs against the newest stormspeed baselines of the same CAM base
  (`--compare <name> --baseline-root <dir>`). For development commits a small BFB test (one Derecho or NAG ERS) suffices.
- **Faster tests**: use the converted input-data mirrors (`handoffs/2026-11-13_fast-inputdata.md`): Derecho
  `/glade/campaign/cgd/amp/jet/inputdata_fast`, Izumi `/project/amp/jet/inputdata_fast`, via `create_test --input-dir`
  or `DIN_LOC_ROOT`. Izumi NAG debug tests otherwise take 1-2 hours; identical answers.
- preqx is not supported in StormSPEED and has never been built there.

## 4. Things that touch the unify work
- **Directories to decide on** (Derecho `/glade/campaign/cgd/amp/jet/collections`, left by the 2026-11-16 cleanup for
  this workstream): `stormspeed_build`, `stormspeed_build.102226.tar`, `stormspeed_build_unify_se_dycore` (+ `.tar`,
  3.4 GB each), `e3sm_ref`, `check`, `unify_se_dycore.py`, `finish_unify_se.py`, `fetch_and_package.py`,
  `dycore_refactor_context.txt`, `cam_mods_context.txt`. Check with `scripts/clean_check.sh` / `keep_inspect.sh`, archive
  local-only work with `archive_local.sh`, then remove; compare tars with their directories using `tar -df`.
- Commit **7063cd73** ("senh: expose se_tom_sponge_start") exists **only on `stormspeed_unify`**: if that branch is ever
  rebased or deleted, tag it first.
- Known issues relevant to testing: Izumi TM error 17002 (intermittent, after the model finishes); Izumi Intel/NAG
  (MVAPICH2 2.3.3) shared windows come back non-shared inside cesm.exe (the code falls back correctly; root cause
  open); RTTOV test build failure in aux_cam (hard-coded path in CAM).
- Latest stormspeed handoff: `handoffs/2026-11-13_stormspeed.md`. Wiki: github.com/NCAR/StormSPEED/wiki.
