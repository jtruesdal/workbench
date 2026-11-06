# Handoff: stormspeed, ss.06 in progress (2026-11-06)

## Done since 2026-11-04
- **ss.04** (#112, merge 8cfdd3eb): ne30pg2 ERS gate tests, ERS_Ld62 climate tests, GPU tests; `shm.py` fix (run two
  copies run one's `Buildconf/camconf`; with a user chemistry mechanism the chem preprocessor silently failed in case
  two, nadv 3 vs 106 -> no chemistry namelists). Gate baselines `cam6_4_211_ss.04_e3sm_intel` (35, incl. 2 new ne30pg2)
  and `_gnu` (16), BFB vs ss.03 (`stormspeed_d3d38547_e3sm_*`).
- **ss.05** (#114, merge 1fee24e3): CTSM -> `jtruesdal/ctsm` `ctsm5.4.057_nh.01`. BFB: Derecho intel aux_cam 58 vs ss.02
  (`stormspeed_1649dbd8_intel`), nvhpc 1/1, Izumi gnu 31/31, nag 17/17 (3 rebuilt clean after an Izumi outage).
- Issues: #103 #104 #106 closed; #102 #107 #110 #111 #113 updated. Pushes to NCAR repos need an active NCAR SSO session
  (symptom: `remote: fatal error in commit_refs_rules`).

## ss.06: NAG/portability (branch `nag_portability`, 70f8354b, no PR yet)
1. c2ace441 `ccs_config` -> `ccs_config_cesm1.0.91_nh.05` (jtruesdal fork, branch `ccs_config_nh`, c84756b): `nag.cmake`
   `string(APPEND CXXFLAGS " -std=c++17")` (Kokkos 4; NAG builds use g++ 9.3 without -std).
2. 5afff397 SENH: `namelist_mod_cam.F90` implicit none + imports `SFCURVE`, `nnodes`, `nmpi_per_node` (METIS/Zoltan options
   got undefined values; default SFCURVE unaffected); `restart_dynamics.F90` local `m` in write_elem/write_unstruct.
3. 70f8354b `dycore` -> `https://github.com/jtruesdal/E3SM.git` tag `stormspeed_homme.01` = E3SM b70b675a7b + commit 0aab3626
   (branch `stormspeed/homme_nag_portability`): prim_driver_base TARGET on MetaVertex (dangling pointer), compose_test_mod
   GPTLget_memusage int args, sort_mod (#102) + theta-l/share/prim_state_mod declaration order, kinds/parallel_mod/metis_mod
   portable kinds, global_norms_mod real literal, parallel_mod/prim_state_mod `flush` statement. Chosen over whole-file
   overrides in senh/cam_mods (drift risk); the old overrides version is the local backup branch `nag_portability_overrides`
   (eba02b95) in the Derecho clone. When E3SM has the fixes, `dycore` returns to E3SM-Project/E3SM.
- Note: `theta-l_kokkos/share` is a symlink to `theta-l/share` (both targets compile the same files).

## Test state (when this was written)
- NAG theta-l `SMS_D_Ln9.ne3pg3_ne3pg3_mt232.FHISTC_LTso` PASS (overrides version = same code).
- NAG theta-l_kokkos: builds; debug run aborts in `init_elements_states_c` on IEEE invalid: HOMME's `ElementsState.cpp`
  fills pack padding with quiet NaNs and compares with `<` (NAG `-ieee=stop` traps process-wide). Not a bug. Non-debug
  `SMS_Ln9` (job ss06nag3, `/scratch/cluster/jet/stormspeed_07aebdd2.nag/cs.status.ss06nag3`) pending.
- Izumi GNU `aux_cam_e3sm_izumi` (12) + Intel debug probe `SMS_D_Ln9...izumi_intel...thetal`:
  `/scratch/cluster/jet/stormspeed_eba02b95.izumi/cs.status.ss06gnu`, `cs.status.ss06intel` (created after the gnu tests).
  Expected: GNU ERS_Ln9 thetal (and _hy) = known #110; Intel optimized = #107 (debug may pass).
- Derecho gate on 70f8354b vs ss.04, generating `stormspeed_70f8354b_e3sm_*` (qcmd 8084786/8084787):
  `/glade/derecho/scratch/jet/tests/stormspeed_70f8354b.aux_cam_e3sm.{intel,gnu}/cs.status.ss06_{intel,gnu} -s`. Expect all PASS.

## Next
1. After the Izumi jobs end: Izumi clone -> 70f8354b (`git fetch`, `git reset --hard origin/nag_portability`; `dycore` URL
   changed, so `git-fleximod update` or fetch the fork tag into `src/dynamics/senh/dycore`); use the `scamppe` env (or the
   python module, never both).
2. testlist commit: Izumi theta-l tests into `aux_cam_e3sm` (gnu: the passing aux_cam_e3sm_izumi tests; nag: SMS_D_Ln9 thetal
   + SMS_Ln9 thetal_kokkos if it passes; intel: SMS_D_Ln9 thetal if it passes). Keep #110/#107 failures out of the gate.
3. Izumi gate run from the final branch (generates the first ss.06 Izumi baselines); ChangeLog entry; PR + review summary;
   merge; tag `cam6_4_211_ss.06`; close #102.
4. File the E3SM issue (below) on E3SM-Project/E3SM, pointing at jtruesdal/E3SM `stormspeed_homme.01`; E3SM team members
   on StormSPEED may turn it into a PR. Check first for duplicates; Jian (sjsprecious) has filed HOMME issues before.

## E3SM issue draft (summary)
Title: "HOMME: two real bugs and several portability problems found with NAG Fortran 7.0 (theta-l, theta-l_kokkos)".
Bugs: (1) dangling `gm%mv` (scalable_grid_init_mod 76/109/222; caller prim_driver_base line 55 lacks TARGET);
(2) compose_test_mod line 161 integer(8) passed to GPTL's int*. Portability: declaration order (sort_mod 42-43,
theta-l/share/prim_state_mod 1021-1022), literal kinds (parallel_mod 39/63/64, metis_mod 42-54/319, kinds longdouble_kind),
integer literal with real kind (global_norms_mod 195-197), `call flush` (parallel_mod 277, prim_state_mod 816). Note on the
Kokkos NaN padding vs `-ieee=stop`. Full text was given in the stormspeed chat (E3SM_issue_homme_nag.md); confirm the
non-debug NAG kokkos run and the BFB gate before filing.
