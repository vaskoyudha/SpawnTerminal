#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: st <panes> <command> [options]
       st list
       st kill <session-name> | --all
       st help

Spawn a tmux grid layout with <panes> panes, each running <command>.

Examples:
  st 4 opencode          # 2x2 grid, each pane runs opencode
  st 6 htop              # 3x2 grid, each pane runs htop
  st --name dev 4 vim    # Named session: st-dev
  st --detach 4 opencode # Create without attaching
  st list                # List all st sessions
  st kill st-opencode-4  # Kill a session

Options:
  -h, --help             Show this help message
  -d, --detach           Create session without attaching
  -f, --fresh            Kill existing session and create a fresh one
  -F, --force            Allow creating more than 16 panes
  -n, --name <name>      Set a custom session name (prefixed with st-)
  -l, --layout <layout>  Pane layout (default: tiled)
                         Valid: tiled, even-horizontal, even-vertical,
                         main-horizontal, main-vertical
EOF
}

command -v tmux >/dev/null 2>&1 || die "tmux is not installed. Install with: sudo apt install tmux"

cmd_list() {
  local sessions
  sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^st-" || true)
  if [[ -z "$sessions" ]]; then
    echo "No active st sessions."
    return 0
  fi
  echo "Active st sessions:"
  while IFS= read -r name; do
    local info
    info=$(tmux list-sessions -F "#{session_name}: #{session_windows} window(s), #{?session_attached,attached,detached}" 2>/dev/null | grep "^${name}:" || echo "$name: unknown")
    echo "  $info"
  done <<< "$sessions"
}

cmd_kill() {
  local target="${1:-}"

  if [[ "$target" == "--all" ]]; then
    local sessions
    sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^st-" || true)
    if [[ -z "$sessions" ]]; then
      echo "No active st sessions to kill."
      return 0
    fi
    echo "Killing all st sessions:"
    while IFS= read -r name; do
      tmux kill-session -t "$name" 2>/dev/null && echo "  Killed: $name" || echo "  Failed: $name"
    done <<< "$sessions"
    return 0
  fi

  if [[ -z "$target" ]]; then
    die "Usage: st kill <session-name> or st kill --all"
  fi

  # Safety: refuse to kill non-st sessions
  if [[ "$target" != st-* ]]; then
    die "Refusing to kill '$target': not an st session (must start with 'st-')"
  fi

  if ! tmux has-session -t "$target" 2>/dev/null; then
    die "Session '$target' not found."
  fi

  tmux kill-session -t "$target"
  echo "Session '$target' killed."
}

FRESH=false
FORCE=false
DETACH=false
NAME=""
LAYOUT="tiled"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -d|--detach)
      DETACH=true
      shift
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
    -l|--layout)
      LAYOUT="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

# Subcommand dispatch
if [[ $# -gt 0 ]]; then
  case "$1" in
    list)
      cmd_list
      exit 0
      ;;
    kill)
      shift
      cmd_kill "$@"
      exit 0
      ;;
    help)
      usage
      exit 0
      ;;
  esac
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

N="$1"
shift
command="$*"

# Validate layout option
case "$LAYOUT" in
  tiled|even-horizontal|even-vertical|main-horizontal|main-vertical)
    ;;
  *)
    die "Invalid layout: '$LAYOUT'. Valid options: tiled, even-horizontal, even-vertical, main-horizontal, main-vertical"
    ;;
esac

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
    if [[ "$DETACH" == true ]] || ! [[ -t 0 ]]; then
      echo "Session '$session_name' already exists (detached). Attach with: tmux attach -t $session_name"
    else
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
tmux select-layout -t "$session_name" "$LAYOUT"

if [[ "$DETACH" == true ]] || ! [[ -t 0 ]]; then
  echo "Session '$session_name' created with $N panes (detached). Attach with: tmux attach -t $session_name"
else
  tmux attach-session -t "$session_name"
fi
