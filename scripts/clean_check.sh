#!/bin/bash
# clean_check.sh PATH... : read-only check before removing directories or files.
# For each path: size; for Git checkouts also uncommitted changes, commits on no remote and no tag
# ("local-only"), and stashes. Paths with nothing local-only are listed as SAFE; the SAFE list is
# written to the file named by $OUT (default ~/ss_tools/clean_safe.txt), one absolute path per line.
# For checkouts marked KEEP?, run keep_inspect.sh on them, then save local-only work with
# archive_local.sh before removing. Nothing is changed by this script.
OUT=${OUT:-$HOME/ss_tools/clean_safe.txt}; mkdir -p "$(dirname "$OUT")"; : > "$OUT"
tot=0; printf "%-60s %8s  %s\n" PATH SIZE STATE
for c in "$@"; do
  c=$(readlink -m -- "$c")
  [ -e "$c" ] || [ -L "$c" ] || { printf "%-60s %8s  %s\n" "$c" - "not present"; continue; }
  s=$(du -sk -- "$c" 2>/dev/null | cut -f1); state=ok
  if [ -d "$c/.git" ] || [ -f "$c/.git" ]; then
    d=$(git -C "$c" status --porcelain --untracked-files=no --ignore-submodules=all 2>/dev/null | wc -l)
    u=$(git -C "$c" for-each-ref --format='%(refname)' refs/heads 2>/dev/null | while read b; do git -C "$c" rev-list --count "$b" --not --remotes --tags 2>/dev/null; done | awk '{s+=$1} END {print s+0}')
    st=$(git -C "$c" stash list 2>/dev/null | wc -l)
    state="git: changed=$d local-only-commits=$u stashes=$st"
    if [ $d -eq 0 ] && [ $u -eq 0 ] && [ $st -eq 0 ]; then state="$state  SAFE"; else state="$state  KEEP?"; fi
  fi
  case $state in *KEEP*) ;; *) echo "$c" >> "$OUT"; tot=$((tot+s)) ;; esac
  printf "%-60s %7.1fG  %s\n" "$c" $(echo "$s/1048576" | bc -l) "$state"
done
echo "== safe to remove: $(wc -l < "$OUT") items, $(echo "$tot/1048576" | bc -l | cut -c1-6) GB (list in $OUT)"
