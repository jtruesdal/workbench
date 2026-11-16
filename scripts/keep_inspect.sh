#!/bin/bash
# keep_inspect.sh CHECKOUT... : for Git checkouts marked KEEP? by clean_check.sh, show what is local-only.
# Refreshes remote-tracking branches (git fetch --all; the working tree is untouched), then lists every
# commit on no remote and no tag, marked "same patch as <hash> on <branch>" if an identical change exists
# remotely under another hash, "same subject as ..." if only the message matches, or NOT ON ANY REMOTE.
# Also lists uncommitted changes. Read-only apart from the fetch.
for d in "$@"; do
  cd "$d" 2>/dev/null || { echo "######## $d: not found"; continue; }
  echo "######## $d   (HEAD: $(git rev-parse --abbrev-ref HEAD 2>/dev/null) $(git log -1 --format='%h %ad' --date=short 2>/dev/null))"
  echo "   remotes: $(git remote -v 2>/dev/null | awk '$3=="(fetch)" {print $1"="$2}' | tr '\n' ' ')"
  timeout 120 git fetch -q --all --no-recurse-submodules 2>&1 | head -2 | sed 's/^/   fetch: /'
  loc=$(git rev-list --reverse --all --not --remotes --tags 2>/dev/null)
  if [ -n "$loc" ]; then
    since=$(git log -1 --format=%ad --date=format:%Y-%m-%d $(echo "$loc" | head -1))
    pid=$(mktemp)
    git log -p --remotes --no-merges --since="$since - 90 days" 2>/dev/null | git patch-id --stable > $pid
  fi
  for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do
    n=$(git rev-list --count $b --not --remotes --tags 2>/dev/null)
    [ "$n" -gt 0 ] || continue
    echo "   branch $b: $n local-only commit(s)"
    for h in $(git rev-list --reverse $b --not --remotes --tags); do
      s=$(git log -1 --format=%s $h); p=$(git show $h 2>/dev/null | git patch-id --stable | cut -d' ' -f1)
      eq=""; kind=""
      [ -n "$(git rev-list --parents -n1 $h | awk 'NF>2')" ] && kind="(merge) "
      if [ -n "$p" ]; then r=$(awk -v p=$p '$1==p {print $2; exit}' $pid); [ -n "$r" ] && eq="same patch as $(git log -1 --format=%h $r) on $(git branch -r --contains $r | head -1 | tr -d ' ')"; fi
      if [ -z "$eq" ]; then m=$(git log --remotes --format='%h' -F --grep="$s" 2>/dev/null | head -1); [ -n "$m" ] && eq="same subject as $m on $(git branch -r --contains $m | head -1 | tr -d ' ')"; fi
      printf "      %s %s %s%-60s  -> %s\n" $(git log -1 --format='%h %ad' --date=short $h) "$kind" "$(echo "$s" | cut -c1-60)" "${eq:-NOT ON ANY REMOTE}"
    done
  done
  [ -n "$loc" ] && rm -f $pid
  c=$(git status --porcelain --untracked-files=no --ignore-submodules=all 2>/dev/null | wc -l)
  if [ $c -gt 0 ]; then
    echo "   uncommitted changes: $c file(s)"; git status --porcelain --untracked-files=no --ignore-submodules=all | head -6 | sed 's/^/      /'
    [ $c -le 6 ] && git diff --stat --ignore-submodules=all 2>/dev/null | tail -1 | sed 's/^/      /'
  fi
done
