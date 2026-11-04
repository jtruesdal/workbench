# local_env.sh -- laptop (macOS, zsh or bash) side of the workbench.
# The laptop is the middle man for file transfers between the AI chats
# (downloads) and Derecho / Izumi.
#
# Use:  source ~/workbench/local_env.sh      (add that line to ~/.zshrc and ~/.bashrc)
#
# Commands defined here:
#   fixpaste              turn off a stuck "bracketed paste" mode (pastes arrive
#                         wrapped in 00~ ... 01~ or ^[[200~ ... ^[[201~)
#   to_derecho FILE... [-d DIR]   copy files to Derecho  (default DIR: ~/inbox)
#   to_izumi   FILE... [-d DIR]   copy files to Izumi    (default DIR: ~/inbox)
#   from_derecho PATH [LOCALDIR]  copy a file back from Derecho (default: $WB_DL)
#   from_izumi   PATH [LOCALDIR]  copy a file back from Izumi
#   latest [N]            list the N newest files in the download folder
#   chk FILE...           md5 checksums, same format as md5sum on Linux

export WB_DL="${WB_DL:-$HOME/Downloads}"
export WB_DERECHO="${WB_DERECHO:-derecho}"   # ssh host alias (see ssh_config.example)
export WB_IZUMI="${WB_IZUMI:-izumi}"

fixpaste() { printf '\033[?2004l'; }

_wb_send() {
    local host="$1"; shift
    local dest="inbox" files=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -d) dest="$2"; shift 2 ;;
            *)  files+=("$1"); shift ;;
        esac
    done
    if [ ${#files[@]} -eq 0 ]; then echo "usage: to_$host FILE... [-d DIR]"; return 1; fi
    ssh "$host" "mkdir -p $dest" && scp "${files[@]}" "$host:$dest/" && chk "${files[@]}"
}
to_derecho() { _wb_send "$WB_DERECHO" "$@"; }
to_izumi()   { _wb_send "$WB_IZUMI" "$@"; }

from_derecho() { scp "$WB_DERECHO:$1" "${2:-$WB_DL}/"; }
from_izumi()   { scp "$WB_IZUMI:$1" "${2:-$WB_DL}/"; }

latest() { ls -t "$WB_DL" | head -"${1:-10}"; }

chk() {
    local f
    for f in "$@"; do
        if command -v md5sum >/dev/null 2>&1; then md5sum "$f"
        else printf '%s  %s\n' "$(md5 -q "$f")" "$f"; fi
    done
}
