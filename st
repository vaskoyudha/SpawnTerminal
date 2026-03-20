#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "Error: $*" >&2
  exit 1
}

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
  -F, --force            Allow creating more than 16 panes
  -n, --name <name>      Set a custom session name (prefixed with st-)
EOF
}

command -v tmux >/dev/null 2>&1 || die "tmux is not installed. Install with: sudo apt install tmux"

FRESH=false
FORCE=false
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
    -F|--force)
      FORCE=true
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

# Validate N is a positive integer
if ! [[ "$N" =~ ^[0-9]+$ ]] || [[ "$N" -eq 0 ]]; then
  die "Pane count must be a positive integer, got: '$N'"
fi

# Soft cap: block >16 without --force, hard cap at 50
if [[ "$N" -gt 50 ]]; then
  die "Pane count $N exceeds absolute maximum of 50."
elif [[ "$N" -gt 16 ]]; then
  if [[ "$FORCE" != true ]]; then
    die "Pane count $N exceeds recommended maximum of 16. Use --force to override."
  else
    echo "Warning: Creating $N panes (exceeds recommended maximum of 16)" >&2
  fi
fi

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

# Nested tmux warning
if [[ -n "${TMUX:-}" ]]; then
  echo "Warning: Running inside an existing tmux session. This will create a nested session." >&2
fi

tmux new-session -d -s "$session_name" -c "$PWD"
tmux send-keys -t "$session_name" "$command" Enter
for i in $(seq 2 "$N"); do
  if ! tmux split-window -t "$session_name" -c "$PWD" 2>/dev/null; then
    tmux kill-session -t "$session_name" 2>/dev/null || true
    die "Terminal too small for $N panes. Try reducing pane count or maximizing your terminal."
  fi
  tmux send-keys -t "$session_name" "$command" Enter
done
tmux select-layout -t "$session_name" tiled

if [[ -t 0 ]]; then
  tmux attach-session -t "$session_name"
fi
