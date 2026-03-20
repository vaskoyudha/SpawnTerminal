#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: st <panes> <command> [options]

Spawn a tmux grid layout with <panes> panes, each running <command>.

Examples:
  st 4 opencode          # 2x2 grid, each pane runs opencode
  st 6 htop              # 3x2 grid, each pane runs htop
  st --name dev 4 vim    # Named session: st-dev

Options:
  -h, --help             Show this help message
  -f, --fresh            Kill existing session and create a fresh one
  -n, --name <name>      Set a custom session name (prefixed with st-)
EOF
}

FRESH=false
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -f|--fresh)
      FRESH=true
      shift
      ;;
    -n|--name)
      NAME="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

N="$1"
shift
command="$*"

if [[ -n "$NAME" ]]; then
  if [[ "$NAME" == *:* || "$NAME" == *.* ]]; then
    echo "Error: session name must not contain ':' or '.'" >&2
    exit 1
  fi
  session_name="st-${NAME}"
else
  first_word="${command%% *}"
  safe_word="$(printf '%s' "$first_word" | tr -cd '[:alnum:]_-')"
  if [[ -z "$safe_word" ]]; then
    safe_word="cmd"
  fi
  session_name="st-${safe_word}-${N}"
fi

if tmux has-session -t "$session_name" 2>/dev/null; then
  if [[ "$FRESH" == true ]]; then
    tmux kill-session -t "$session_name"
  else
    if [[ -t 0 ]]; then
      tmux attach-session -t "$session_name"
    fi
    exit 0
  fi
fi

tmux new-session -d -s "$session_name" -c "$PWD"
tmux send-keys -t "$session_name" "$command" Enter
for i in $(seq 2 "$N"); do
  tmux split-window -t "$session_name" -c "$PWD"
  tmux send-keys -t "$session_name" "$command" Enter
done
tmux select-layout -t "$session_name" tiled

if [[ -t 0 ]]; then
  tmux attach-session -t "$session_name"
fi
