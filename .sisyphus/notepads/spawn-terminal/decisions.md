# Decisions — spawn-terminal

## Session: ses_2f4db8085ffebVmWb3fGEP53JF (2026-03-20)
### Architecture Decisions
- Single Bash script (`st`) — no module system, idiomatic Bash
- `set -euo pipefail` for script safety
- Subcommand dispatch: first arg checked for subcommand THEN falls through to N-panes mode
- YAML parsing: `yq` if available, pure Bash grep/sed fallback for flat YAML
- Layout default: `tiled` (tmux handles NxM math automatically)
- Pane soft cap: 16 (warn), hard cap bypass via `--force`
- Empty command (`st 4 ""`): opens empty shells (valid use case)
- Nested tmux: warn but continue (don't block)
- kill: refuse non-st-prefixed sessions (safety guardrail)
- License: MIT (copyright 2026 vaskoyudha)
- Git remote: https://github.com/vaskoyudha/SpawnTerminal.git
- Branch: main
