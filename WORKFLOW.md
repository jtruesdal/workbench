# Workflow for parallel chats

Several AI chats work on related parts of the CAM/SCAM effort at the same time.
This file is the shared set of conventions. Every chat follows it; the person
running the chats (the user) is the only one who runs commands, commits and pushes.

## 1. One chat per workstream

- Each workstream has exactly one row in `STATUS.md` and one chat (in the
  claude.ai Project for this work). Start a new chat for a workstream only when
  the old one is finished or too long, and hand off explicitly (section 4).
- **Routing rule.** If something comes up that belongs to another workstream,
  the current chat does not do it. It writes a short note for that workstream
  (what was found, where, why it matters) under that row's "Inbox" in
  `STATUS.md`, or as a comment on its GitHub issue, and returns to its own task.

## 2. Start of a chat

1. Read `STATUS.md` (and the latest handoff named there) from
   `https://raw.githubusercontent.com/jtruesdal/workbench/main/STATUS.md`.
2. Confirm with the user: workstream, machine (Derecho/Izumi), checkout and branch.
3. Clear that workstream's Inbox items or decide when to handle them.

## 3. Working conventions

- **Shell:** login shell is tcsh. Start every shell or tmux window with
  `source ~/workbench/scam_env.csh` (sets `CAMROOT`, `PP`, `TD`, `CC`, `PR`,
  `PBS_ACCOUNT`, ...). Commands use these variables and absolute paths, never
  "cd there first". In tcsh: `set` is shell-only, `setenv` is exported; `!` is
  special even in single quotes; heredocs use an unquoted `EOF` with no `$`,
  backslash or `!` in the body; redirect with `>&`.
- **One step at a time:** one command block per turn, with the expected output
  stated; wait for the result before the next step. Read-only investigation
  first, until a plan is agreed.
- **Git:** `git --no-pager -C $CAMROOT ...`. The AI never pushes, tags or writes
  official baselines; it may prepare commit messages and patches. Patches are
  checked with `git apply --check` against the pushed branch before handing over.
- **Builds:** never on a login node. Derecho: `qcmd` (in tmux, or backgrounded
  with `>& log &`; test suites get 5 h). Izumi: a batch job (`echo "cmd" | qsub ...`),
  no additional interactive jobs.
- **Jobs:** tests use `job_priority=premium` on Derecho (`./xmlchange JOB_PRIORITY=premium`).
  Keep walltimes realistic; long requests wait behind reservations.
- **AI sandbox:** the AI keeps its own clone of the relevant branches, dry-runs
  edits and scripts there, and answers code questions from it instead of asking
  the user to run lookups.

## 4. End of a chat, or a hand-off

- Update the workstream's row in `STATUS.md`: state, next step, open questions.
- For larger transitions write `handoffs/YYYY-MM-DD_<workstream>.md`: what was
  done, what is uncommitted where, what is running, decisions, next steps.
- The user commits and pushes; the next chat reads it from GitHub.

## 5. Persistent environment

- **tmux:** always log in to the same Derecho login node (e.g.
  `ssh derecho3.hpc.ucar.edu`) and run `scamtmux` (alias for
  `tmux new -A -s scam`: attach if it exists, else create). Sessions live on one
  login node only. To find a lost session:
  `foreach n (1 2 3 4 5 6 7 8)` / `ssh -o BatchMode=yes derecho$n tmux ls` / `end`.
  Useful keys: `Ctrl-b d` detach, `Ctrl-b c` new window, `Ctrl-b [` scroll (`q` exits).
  `~/.tmux.conf`: `set -g mouse on`, `set -g history-limit 50000`.
- **Python:** `conda env create -f ~/workbench/environment.yml` once per machine,
  then `scampy` (alias for `conda activate scamppe`). Do not mix with
  `module load python`; if conda fails with "No module named encodings",
  `unsetenv PYTHONHOME PYTHONPATH`.
- **Laptop (the middle man for file transfers):** macOS with zsh (bash works too).
  Add `source ~/workbench/local_env.sh` to `~/.zshrc` (and `~/.bashrc` if you use bash);
  copy `ssh_config.example` into `~/.ssh/config` (after `mkdir -p ~/.ssh/cm`) so one
  login with Duo per host is reused by every later `ssh`/`scp` for 8 hours. Then:
  `to_derecho FILE... [-d DIR]` / `to_izumi ...` (copy, then print md5 to compare),
  `from_derecho PATH`, `latest` (newest downloads), `chk FILE` (md5).
- **Stuck paste mode:** if pasted text arrives wrapped in `00~ ... 01~` (or
  `^[[200~ ... ^[[201~`), the terminal's bracketed-paste mode was left on, usually
  by a remote program that ended abruptly. Run `fixpaste` in that shell (defined
  on the laptop by `local_env.sh` and on Derecho/Izumi by `scam_env.csh`), or
  `printf '\033[?2004l'`, then paste again.
- **Shells:** zsh on the laptop and tcsh on Derecho/Izumi. Commands from the chats are
  written for tcsh on the HPC side and for zsh/bash on the laptop; no need to switch.
- **Machine notes:**
  - Izumi PIO is built without netCDF-4 type support: files with `int64`
    variables fail to open (error -45). The Izumi ERA5 nudging copy has
    `TimeStamp` removed (originals in `.../L32_orig`).
  - Izumi network/login is unstable since the router change: run long work as batch jobs.
