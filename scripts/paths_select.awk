# Usage: awk -v m=<derecho|izumi> -v sh=<csh|sh> -f paths_select.awk paths.list
# Prints "setenv NAME value" (csh) or "export NAME='value'" (sh) for this machine.
/^[ \t]*#/ || NF < 3 { next }
{
  v = (m == "derecho") ? $2 : (m == "izumi") ? $3 : "-"
  if (v == "-") next
  if (substr(v, 1, 1) == "~") v = ENVIRON["HOME"] substr(v, 2)
  if (sh == "csh") print "setenv " $1 " " v
  else             print "export " $1 "='" v "'"
}
