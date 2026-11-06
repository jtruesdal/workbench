# Morning checks

Each workstream keeps `checks/<workstream>.sh`: read-only commands showing the status of everything that
workstream is waiting on, per machine (`case "$1" in derecho) ... ;; izumi) ... ;; esac`), each with the
expected result. The chat updates it in its evening checkpoint patch. `lib.sh.inc` has two helpers:
`cs <cs.status path> <expectation>` (counts plus every non-PASS test) and `jobs_here`.

From the laptop, `wbcheck` (in `local_env.sh`) runs `checks/run.sh` on Derecho and Izumi: it pulls the
workbench there, then runs every workstream's checks for that machine. Paste each workstream's section
into its chat to resume.
