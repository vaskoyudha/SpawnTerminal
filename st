#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: st <panes> <command> [options]

Spawn a tmux grid layout with <panes> panes, each running <command>.

Examples:
  st 4 opencode    # 2x2 grid, each pane runs opencode
  st 6 htop        # 3x2 grid, each pane runs htop

Options:
  -h, --help       Show this help message
EOF
}

if [[ ${1-} == "-h" || ${1-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

N="$1"
shift
command="$*"

first_word="${command%% *}"
safe_word="$(printf '%s' "$first_word" | tr -cd '[:alnum:]_-')"
if [[ -z "$safe_word" ]]; then
  safe_word="cmd"
fi
session_name="st-${safe_word}-${N}"

tmux new-session -d -s "$session_name" -c "$PWD"
tmux send-keys -t "$session_name" "$command" Enter
for i in $(seq 2 "$N"); do
  tmux split-window -t "$session_name" -c "$PWD"
  tmux send-keys -t "$session_name" "$command" Enter
done
tmux select-layout -t "$session_name" tiled

[[ -t 0 ]] && tmux attach-session -t "$session_name"
