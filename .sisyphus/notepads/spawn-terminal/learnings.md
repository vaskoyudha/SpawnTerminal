# Learnings — spawn-terminal

## Session: ses_2f4db8085ffebVmWb3fGEP53JF (2026-03-20)
### Initial Setup
- OS: Ubuntu 24.04, Bash 5.2
- tmux 3.4 available via apt (not yet installed as of T1 start)
- shellcheck available via apt
- Node.js v20 available, Python 3 available, no Go
- No existing .tmux.conf
- Shell: bash (has .bashrc and .zshrc)
- `st` command name — no conflicts on system

### Conventions Established
- All tmux sessions MUST be prefixed with `st-`
- Session auto-name: `st-{first_word_of_command}-{pane_count}` (e.g., st-opencode-4)
- Session names must NOT contain colons or periods
- Config dir: `${XDG_CONFIG_HOME:-$HOME/.config}/st/`
- Install dir: prefer `~/.local/bin` (no sudo) over `/usr/local/bin`
- QA MUST use `< /dev/null` or `--detach` to avoid blocking on tmux attach
- Evidence saved to `.sisyphus/evidence/task-N-*.txt`

### tmux Pattern (core algorithm)
```bash
tmux new-session -d -s "$session_name" -c "$PWD"
tmux send-keys -t "$session_name" "$command" Enter
for i in $(seq 2 $N); do
  tmux split-window -t "$session_name" -c "$PWD"
  tmux send-keys -t "$session_name:0" "$command" Enter
done
tmux select-layout -t "$session_name" tiled
# Attach only if stdin is a TTY: [[ -t 0 ]]
```

## [Task 2 complete] Core st script
- Session naming pattern: st-{first_word}-{N}
- Attach gate: [[ -t 0 ]] && tmux attach-session
- split-window loop: seq 2 $N (skips for N=1)
- send-keys after EACH split (not after all splits)
