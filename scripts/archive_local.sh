#!/bin/bash
# archive_local.sh ARCHIVE_DIR CHECKOUT... : save a checkout's local-only work as patch files before
# removing it. Local-only commits (on no remote, no tag) go to ARCHIVE_DIR/<name>/ via git format-patch,
# one subdirectory per branch; uncommitted changes go to ARCHIVE_DIR/<name>.uncommitted.diff.
# Restore with "git am" (commits) or "git apply" (diff) on a fresh clone. Writes only into ARCHIVE_DIR.
A=${1:?usage: archive_local.sh ARCHIVE_DIR CHECKOUT...}; shift; mkdir -p "$A"
for d in "$@"; do
  n=$(basename "$d"); [ -d "$d" ] || { echo "$d: not found"; continue; }
  for b in $(git -C "$d" for-each-ref --format='%(refname:short)' refs/heads); do
    [ "$(git -C "$d" rev-list --count $b --not --remotes --tags)" -gt 0 ] || continue
    git -C "$d" format-patch -q -o "$A/$n/${b//\//_}" $b --not --remotes --tags
  done
  [ -n "$(git -C "$d" status --porcelain --untracked-files=no --ignore-submodules=all)" ] && \
    git -C "$d" --no-pager diff HEAD --ignore-submodules=all > "$A/$n.uncommitted.diff"
  echo "$n: $(find "$A/$n" -name '*.patch' 2>/dev/null | wc -l) commit patch(es)$( [ -s "$A/$n.uncommitted.diff" ] && echo ", uncommitted diff $(stat -c %s "$A/$n.uncommitted.diff") bytes")"
done
