# hpc_env.sh -- bash side of the workbench on Derecho and Izumi (tcsh uses scam_env.csh).
# Use: source ~/workbench/hpc_env.sh        (add that line to ~/.bashrc on both machines)
# Exports the shared variables from paths.list, the same names and values tcsh gets.
case "$(hostname)" in
  derecho*|dec*|deg*|crhtc*) export WB_MACHINE=derecho ;;
  izumi*|i0*)                export WB_MACHINE=izumi ;;
  *) echo "hpc_env.sh: unknown host $(hostname); nothing set"; return 0 2>/dev/null || exit 0 ;;
esac
if [ -r "$HOME/workbench/paths.list" ]; then
  eval "$(awk -v m="$WB_MACHINE" -v sh=sh -f "$HOME/workbench/scripts/paths_select.awk" "$HOME/workbench/paths.list")"
fi
alias fixpaste='printf "\033[?2004l"'
