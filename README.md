# workbench

Coordination repository for the CAM / SCAM work (SCAM PPE, SCAM speed-ups,
input-data stash, StormSPEED) and for the AI chats that help with it.

- `WORKFLOW.md` - how each chat starts, works and hands off; shell, tmux and Python setup.
- `STATUS.md`   - one row per active workstream: branch, machine, state, next step.
- `scam_env.csh` - `source ~/workbench/scam_env.csh` sets the standard variables on Derecho or Izumi.
- `environment.yml` - the `scamppe` conda environment used by the scripts.
- `local_env.sh`, `ssh_config.example` - laptop side (zsh/bash): transfer helpers, paste fix, SSH reuse.
- `handoffs/`   - dated handoff notes between chats.
- `scripts/`    - analysis and data-preparation scripts not tied to a CAM branch.

Model code lives in the CAM fork `jtruesdal/CAM-1` (branches `compassdev`,
`scam_container`, ...); this repository holds no model code and no data.
This repository is public: keep credentials, tokens and unpublished results out of it.
