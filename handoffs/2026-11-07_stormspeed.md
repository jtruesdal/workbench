# Handoff: stormspeed, ss.07 (cam6_4_219 update) ready for its ChangeLog (2026-11-07)

## Done since 2026-11-06
- **ss.06** tagged: `cam6_4_211_ss.06` = merge 4638ab06 of PR #115 (NAG/portability). HOMME fixes live in the fork
  `jtruesdal/E3SM` tag `stormspeed_homme.01` (commit 0aab3626 on E3SM b70b675a7b); SENH fixes; `ccs_config` nh.05.
  Gate on Derecho BFB vs ss.04 (Intel 35, GNU 16; NLCOMP only CTSM's `for_testing_options`). #102 closed.
- **ccs_config nh.06**: `ccs_config_cesm1.0.93_nh.06` (54df156) = upstream 1.0.93 merged into `ccs_config_nh`;
  fork changes identical line for line.
- **ss.07 branch** `cam6_4_219_update` on NCAR/StormSPEED: f1e7fd2e merge of `cam6_4_219` (conflicts only
  `.gitmodules`/`ccs_config`; atmos_phys0_34_001; clubb submodule removed) + 3cb84acb testlist (Izumi in the gate:
  gnu 8, nag 1 SMS_D thetal, intel 1 SMS_D thetal; `aux_cam_e3sm_izumi` keeps the 4 ERS_Ln9 #110 tests).
  Clones: Derecho and Izumi `collections/stormspeed_ss07`. **No PR opened yet.**
- **Wiki** published (NCAR/StormSPEED wiki, commit 6da8c12): Home (NSF award 2332468, acknowledgment), Quick Start,
  Supported Machines and Compilers, StormSPEED SE Workflows, Tag Notes, Forks and Externals, Known Issues, Roadmap,
  Grids and Topography, sidebar; old pages kept as pointers. CI label is `ready_for_ci` (Cirrus ARC runners
  gha-runner-stormspeed / gha-runner-gpu-stormspeed; Jian's PAT expired; user getting a new one from CISL).
- Conventions decided: tags `<CAM tag>_ss.NN` (ss number keeps counting; next `cam6_4_219_ss.07`); Derecho baseline
  root `/glade/campaign/cesm/community/StormSPEED/<tag>_e3sm_<compiler>` (Izumi shared area still to choose);
  CAM baselines: Derecho `/glade/campaign/cesm/amwg/soft_eng/cam_baselines`, Izumi `/fs/cgd/csm/models/atm/cam/pretag_bl`
  (219 NAG not there yet: `/scratch/cluster/cacraig/aux_cam_nag_20261103160711/baselines`).

## ss.07 test results (all finished results explained; `classify_tests.py` in ~/ss_tools)
- aux_cam vs cam6_4_219: answers identical to CAM everywhere checked. NLFAIL = `+stream_ndep_mapalgo` (StormSPEED's
  memory-reduction commit f005cbbe, from the PR #1643 line). Missing baselines (expected): FKESSLER thetal ERP/ERS,
  SHM tests. `ERC_D...QPC7...rttov` MODEL_BUILD FAIL: CAM hard-codes `/glade/campaign/cesm/community/amwg/rttov/RTTOV`
  (cime_config/buildlib:267 and the outfrq9s_rttov testmod), removed by the community reorganization -> tell CAM SEs.
  Izumi NAG 17/17 BASELINE PASS (except SHM: no CAM baseline); Izumi GNU likewise.
- Gate vs ss.06 (stormspeed_70f8354b_e3sm_*): FHISTC_LTso DIFF 332/333 fields = cam6_4_219 PUMAS + cam6_4_213 F-compset
  changes; NL `-clubb_do_icesuper,-clubb_do_liqsupersat` (cam6_4_216); QPC6 BFB; FKESSLER BFB (only DGLC's new history
  file lacks a baseline: "some baseline files were missing"). Izumi gate: all 10 pass (first baselines generated).
- Izumi lessons: (1) NAG crashes ("Internal error") when create_test --no-batch builds many tests at once on one node:
  clean sequential rebuilds pass (iz_nag_rebuild.sh, CLEAN=1); (2) running a test inside a generic job (--no-batch)
  can end with `tm_poll(obit_event) failed with TM error 17002` although the model finished; letting CIME submit the
  case (./case.submit) passed. Future Izumi rounds: create_test WITHOUT --no-batch (as test_driver.sh does).
- Baselines generated: Derecho gate `stormspeed_3cb84acb_e3sm_{intel,gnu}`, Izumi gate `stormspeed_3cb84acb_e3sm_{gnu,nag,intel}`
  (in the old jet areas).

## Next
1. Confirm the remaining Derecho Intel tests (wbcheck; classify_tests.py) match the patterns above.
2. ss.07 ChangeLog entry (answer changes attributed to CAM tags 213/216/219), open the PR (`cam6_4_219_update` ->
   `stormspeed`), `ready_for_ci` once CI works, review summary, merge, tag `cam6_4_219_ss.07`.
3. Copy gate baselines to `/glade/campaign/cesm/community/StormSPEED` under tag names (ss.04, ss.06, ss.07); choose
   Izumi's shared baseline area.
4. Wiki: ss.07 Tag Notes; Known Issues (NAG parallel-build crashes, --no-batch TM error, RTTOV path); change the
   Izumi round script to submit tests through CIME.
5. Still open: file the E3SM issue (HOMME fixes); report the RTTOV path to CAM; NAG theta-l_kokkos non-debug failure;
   CIRRUS PAT.
