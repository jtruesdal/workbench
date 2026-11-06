# Helpers for checks/<workstream>.sh (sourced; not run on its own).
# Non-interactive ssh shells have no module/conda setup; CIME's cs.status needs Python >= 3.7.
for _p in "$HOME/.conda/envs/scamppe/bin" "$HOME/miniforge3/envs/scamppe/bin" /cluster/anaconda-3.11.5/bin; do
  [ -x "$_p/python3" ] && { PATH="$_p:$PATH"; break; }
done
unset PYTHONHOME PYTHONPATH
# cs <path-to-cs.status.*> <what to expect>: one-line counts per status plus every non-PASS test.
cs() {
  local f=$1; shift
  echo "$(basename "$(dirname "$f")")/$(basename "$f")   [expect: $*]"
  if [ ! -x "$f" ]; then echo "    (not created yet)"; return; fi
  local out; out=$("$f" -s 2>&1)
  if ! printf '%s\n' "$out" | awk 'NF==2 && $1 ~ /^(PASS|FAIL|PEND|DIFF|NLFAIL)$/' | grep -q .; then
    echo "    cs.status gave no test lines: $(printf '%s\n' "$out" | grep -v '^ *$' | tail -1 | cut -c1-120)"; return; fi
  printf '%s\n' "$out" | awk 'NF==2 && $1 ~ /^(PASS|FAIL|PEND|DIFF|NLFAIL)$/ {n[$1]++; if ($1 != "PASS") print "    " $1, $2}
       END {s=""; for (k in n) s = s n[k] " " k "  "; print "    counts: " s}'
}
# jobs: my queued/running batch jobs on this machine.
jobs_here() {
  local q c
  for c in "$(command -v qstat)" /opt/pbs/bin/qstat /cluster/torque/bin/qstat; do [ -x "$c" ] && { q=$c; break; }; done
  [ -z "$q" ] && { echo "batch jobs: (qstat not found)"; return; }
  echo "batch jobs: $("$q" -u "$USER" 2>/dev/null | grep -c " $USER ")"
}
