# Helpers for checks/<workstream>.sh (sourced; not run on its own).
# cs <path-to-cs.status.*> <what to expect>: one-line counts per status plus every non-PASS test.
cs() {
  local f=$1; shift
  echo "$(basename "$(dirname "$f")")/$(basename "$f")   [expect: $*]"
  if [ ! -x "$f" ]; then echo "    (not created yet)"; return; fi
  "$f" -s 2>/dev/null | awk 'NF==2 {n[$1]++; if ($1 != "PASS") print "    " $1, $2}
       END {s=""; for (k in n) s = s n[k] " " k "  "; print "    counts: " s}'
}
# jobs: my queued/running batch jobs on this machine.
jobs_here() {
  local q c
  for c in "$(command -v qstat)" /opt/pbs/bin/qstat /cluster/torque/bin/qstat; do [ -x "$c" ] && { q=$c; break; }; done
  [ -z "$q" ] && { echo "batch jobs: (qstat not found)"; return; }
  echo "batch jobs: $("$q" -u "$USER" 2>/dev/null | grep -c " $USER ")"
}
