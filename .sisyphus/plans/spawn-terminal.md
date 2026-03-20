# SpawnTerminal (`st`) — CLI Terminal Layout Launcher

## TL;DR

> **Quick Summary**: Build a Bash CLI tool called `st` that wraps tmux to spawn terminal grid layouts with a single command. Primary use: `st 4 opencode` opens a 2x2 grid with opencode in each pane.
> 
> **Deliverables**:
> - `st` — Main Bash script (CLI tool)
> - `install.sh` — Installation script (symlinks to PATH)
> - YAML preset configs (`~/.config/st/*.yaml`)
> - Example presets (`examples/dev.yaml`, `examples/monitor.yaml`)
> - Professional README with badges, usage examples, install guide
> - Git repo with incremental commits pushed to `https://github.com/vaskoyudha/SpawnTerminal.git`
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 8 waves (parallelism in waves 2, 8, and Final)
> **Critical Path**: T1 → T2 → T3 → T4 → T5 → T6 → T7 → T9 → Final

---

## Context

### Original Request
User wants a CLI tool to spawn terminal layouts from a single command. Primary use case: replicate the same command across multiple panes in a grid (e.g., `st 4 opencode` opens 2x2 grid with opencode in each pane). Also wants saved YAML presets, session management, and a professional OSS appearance.

### Interview Summary
**Key Discussions**:
- **Command name**: `st` (short, fast to type)
- **Language**: Pure Bash (no Python/Go/Ruby dependencies)
- **Primary use**: Same command replicated across N panes
- **Config**: Both CLI flags AND YAML presets in `~/.config/st/`
- **Session handling**: Default reattach, `--fresh` flag to recreate
- **Extra features**: Session management (`st list`, `st kill`), custom layout options, detach mode
- **Git**: Step-by-step commits pushed to GitHub remote
- **Docs**: Professional README like a popular OSS repo

**Research Findings**:
- tmux `tiled` layout auto-distributes panes evenly — perfect for NxM grids
- Key tmux pattern: `new-session -d` → `split-window` × N → `select-layout tiled` → `send-keys`
- Existing tools (tmuxinator, tmuxp, teamocil) all require Ruby/Python runtimes — Bash is lighter
- `send-keys` preferred over direct command passing (keeps shell alive after command exits)
- `tmux has-session` for idempotency, `-d` flag always for automation
- Session names must NOT contain colons or periods (conflict with tmux target syntax)

### Metis Review
**Identified Gaps** (all addressed in plan):
- Nested tmux detection (`$TMUX` env var check with warning)
- Maximum pane count soft cap (default 16, `--force` to override)
- tmux not-installed detection with helpful error
- Session naming convention (`st-` prefix to avoid namespace collisions)
- Default session name generation from command+count (`st-opencode-4`)
- `split-window` failure handling (terminal too small → clean up partial session)
- Working directory handling (default CWD, presets can specify per-pane dirs)
- XDG config path compliance (`${XDG_CONFIG_HOME:-$HOME/.config}/st/`)
- Command quoting edge cases with `send-keys`
- `yq` version detection (Go vs Python `yq`)

---

## Work Objectives

### Core Objective
Build `st` — a pure Bash CLI tool that wraps tmux to spawn grid terminal layouts with a single command, supporting both inline usage and YAML presets.

### Concrete Deliverables
- `st` executable script (~300-400 lines of Bash)
- `install.sh` for easy installation
- Example YAML presets in `examples/`
- Professional `README.md` with badges, usage examples, GIF placeholders, install guide
- `LICENSE` (MIT)
- `.gitignore`
- Git history with 10-11 atomic commits pushed to GitHub

### Definition of Done
- [ ] `st 4 opencode` creates a 2x2 tmux grid with opencode in each pane
- [ ] `st list` shows all st-managed sessions
- [ ] `st kill <name>` kills a specific session
- [ ] `st --preset dev` loads a YAML preset
- [ ] `st --help` shows complete usage
- [ ] `bash -n st` passes (no syntax errors)
- [ ] `shellcheck st` passes (no warnings)
- [ ] `./install.sh` makes `st` available system-wide
- [ ] README renders professionally on GitHub

### Must Have
- Grid layout via tmux `tiled` (auto-distribution)
- Session reattach (don't create duplicate sessions)
- `--fresh` flag to force-recreate sessions
- `--detach` flag to create session without attaching
- `--name` flag for custom session names
- Session management subcommands (`list`, `kill`, `help`)
- tmux installation check with helpful error
- Nested tmux detection with warning
- Input validation (positive integer pane count, ≤16 soft cap)
- YAML preset loading from `${XDG_CONFIG_HOME:-$HOME/.config}/st/`
- Layout options (`tiled`, `even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`)
- `set -euo pipefail` for script safety
- All sessions prefixed with `st-` to avoid namespace collisions
- Each feature committed and pushed incrementally

### Must NOT Have (Guardrails)
- No Ruby, Python, or Go dependencies (pure Bash only)
- No custom tmux themes or color schemes (use user's existing `.tmux.conf`)
- No interactive TUI or fzf/dialog pickers
- No shell completions (can be added in future, not this scope)
- No multi-window support per session (one window, multiple panes)
- No "smart layout" NxM grid calculator (rely on tmux `tiled`)
- No daemon or background process (script runs, sets up tmux, exits)
- No config file migration or schema versioning
- No auto-update mechanism
- No remote session management
- No modification of user's `.tmux.conf` or tmux global settings
- No `as any`, `@ts-ignore`, or other type-safety bypasses (N/A — Bash)
- No excessive comments or over-abstraction (AI slop)
- No hardcoded `~/.config/st/` — MUST use `${XDG_CONFIG_HOME:-$HOME/.config}/st/`

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.
> Acceptance criteria requiring "user manually tests/confirms" are FORBIDDEN.

### Test Decision
- **Infrastructure exists**: NO (Bash CLI tool — no test framework)
- **Automated tests**: NONE (verification via agent-executed QA scenarios)
- **Framework**: N/A
- **Linting**: `shellcheck` for static analysis, `bash -n` for syntax validation

### QA Policy
Every task MUST include agent-executed QA scenarios as the primary verification method.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **CLI Tool**: Use Bash — Run `st` commands in `--detach` mode, assert with `tmux has-session`, `tmux list-panes`, `tmux capture-pane`
- **Config Loading**: Use Bash — Create test YAML, run `st --preset`, verify session created correctly
- **Install**: Use Bash — Run `install.sh`, verify `which st`, verify `st --help`
- **README**: Use Bash — Verify file exists, check line count, grep for key sections

**CRITICAL QA RULES (from Metis)**:
- ALL QA must use `--detach` mode to avoid blocking the agent on `tmux attach`
- QA cleanup: `tmux kill-session -t "st-<name>" 2>/dev/null` after each test
- NEVER create QA that requires interactive terminal input
- NEVER create QA that calls `tmux attach` without `--detach` (blocks agent)

---

## Execution Strategy

### Parallel Execution Waves

> This is a single-file Bash project. True parallelism is limited to tasks on separate files.
> Sequential development of `st` is necessary since most tasks modify the same script.
> Parallelism achieved where possible: install.sh, README, verification.

```
Wave 1 (Foundation):
└── Task 1: Project scaffolding — git init, .gitignore, LICENSE, directory structure, README stub [quick]

Wave 2 (Core — 2 parallel, different files):
├── Task 2: Core st script — arg parsing + grid creation + basic usage [deep]
└── Task 8: install.sh script [quick]

Wave 3 (Session Features):
└── Task 3: Session handling — reattach, --fresh, --name flags [unspecified-high]

Wave 4 (Robustness):
└── Task 4: Error handling — tmux check, nested tmux, validation, graceful failures [unspecified-high]

Wave 5 (Management):
└── Task 5: --detach mode + session management (list, kill, help subcommands) [unspecified-high]

Wave 6 (Layout):
└── Task 6: Layout options — --layout flag with tmux preset layouts [quick]

Wave 7 (Config):
└── Task 7: YAML preset support + example config files [unspecified-high]

Wave 8 (Polish — 2 parallel, different files):
├── Task 9: Edge case hardening + shellcheck fixes [deep]
└── Task 10: Professional README with badges, examples, install guide [writing]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: T1 → T2 → T3 → T4 → T5 → T6 → T7 → T9 → F1-F4 → user okay
Parallel Speedup: ~25% faster than fully sequential (parallelism in waves 2, 8, Final)
Max Concurrent: 4 (Final wave)
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| T1 | — | T2, T8 | 1 |
| T2 | T1 | T3 | 2 |
| T8 | T1 | T9 | 2 |
| T3 | T2 | T4 | 3 |
| T4 | T3 | T5 | 4 |
| T5 | T4 | T6 | 5 |
| T6 | T5 | T7 | 6 |
| T7 | T6 | T9, T10 | 7 |
| T9 | T7, T8 | Final | 8 |
| T10 | T7 | Final | 8 |

### Agent Dispatch Summary

- **Wave 1**: **1** — T1 → `quick`
- **Wave 2**: **2** — T2 → `deep`, T8 → `quick`
- **Wave 3**: **1** — T3 → `unspecified-high`
- **Wave 4**: **1** — T4 → `unspecified-high`
- **Wave 5**: **1** — T5 → `unspecified-high`
- **Wave 6**: **1** — T6 → `quick`
- **Wave 7**: **1** — T7 → `unspecified-high`
- **Wave 8**: **2** — T9 → `deep`, T10 → `writing`
- **FINAL**: **4** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

> Implementation + Verification = ONE Task. Never separate.
> EVERY task MUST have: Recommended Agent Profile + Parallelization info + QA Scenarios.
> **A task WITHOUT QA Scenarios is INCOMPLETE. No exceptions.**

- [ ] 1. Project Scaffolding — Git Init, Structure, License

  **What to do**:
  - Initialize git repo (`git init`)
  - Set remote: `git remote add origin https://github.com/vaskoyudha/SpawnTerminal.git`
  - Set branch: `git branch -M main`
  - Create `.gitignore` with sensible defaults for Bash projects (`.DS_Store`, `*.swp`, `*.swo`, `*~`, `.env`, `node_modules/`)
  - Create `LICENSE` file (MIT license, copyright 2026 vaskoyudha)
  - Create `README.md` stub (just project title + one-liner description — full README in T10)
  - Create `examples/` directory (for future preset configs)
  - Create `.sisyphus/evidence/` directory for QA evidence
  - Install tmux: `sudo apt-get install -y tmux`
  - Install shellcheck: `sudo apt-get install -y shellcheck`
  - Commit all files and push to remote

  **Must NOT do**:
  - Do NOT write the `st` script yet (that's T2)
  - Do NOT write the full README (that's T10)
  - Do NOT install `yq` yet (that's T7's concern)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple file creation and git setup — no complex logic
  - **Skills**: []
    - No specialized skills needed for scaffolding
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (alone)
  - **Blocks**: Tasks 2, 8
  - **Blocked By**: None (first task)

  **References**:

  **Pattern References**:
  - None (empty repo, greenfield)

  **External References**:
  - MIT License text: Use standard MIT license template
  - `.gitignore` patterns: Standard Bash/shell project ignores

  **WHY Each Reference Matters**:
  - This is the foundation task — no existing patterns to follow

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Git repo initialized and remote configured
    Tool: Bash
    Preconditions: Empty directory, no .git
    Steps:
      1. Run `git rev-parse --is-inside-work-tree` → expect "true"
      2. Run `git remote -v` → expect output containing "https://github.com/vaskoyudha/SpawnTerminal.git"
      3. Run `git branch --show-current` → expect "main"
      4. Run `git log --oneline -1` → expect a commit message
    Expected Result: Git repo exists with remote and initial commit on main
    Failure Indicators: Any command returns error or unexpected output
    Evidence: .sisyphus/evidence/task-1-git-setup.txt

  Scenario: Required files exist
    Tool: Bash
    Preconditions: After initial commit
    Steps:
      1. Run `test -f .gitignore && echo PASS || echo FAIL`
      2. Run `test -f LICENSE && echo PASS || echo FAIL`
      3. Run `test -f README.md && echo PASS || echo FAIL`
      4. Run `test -d examples && echo PASS || echo FAIL`
      5. Run `grep -q "MIT" LICENSE && echo PASS || echo FAIL`
    Expected Result: All files exist, LICENSE contains "MIT"
    Failure Indicators: Any FAIL output
    Evidence: .sisyphus/evidence/task-1-files-exist.txt

  Scenario: tmux and shellcheck installed
    Tool: Bash
    Preconditions: apt packages available
    Steps:
      1. Run `tmux -V` → expect "tmux 3.4" or similar
      2. Run `shellcheck --version` → expect version output
    Expected Result: Both tools available on PATH
    Failure Indicators: "command not found" error
    Evidence: .sisyphus/evidence/task-1-tools-installed.txt
  ```

  **Evidence to Capture:**
  - [ ] task-1-git-setup.txt — git rev-parse, remote, branch output
  - [ ] task-1-files-exist.txt — file existence checks
  - [ ] task-1-tools-installed.txt — tmux and shellcheck versions

  **Commit**: YES
  - Message: `feat: initialize project structure with LICENSE and README`
  - Files: `.gitignore`, `LICENSE`, `README.md`, `examples/`
  - Pre-commit: `test -f LICENSE && test -f .gitignore && test -f README.md`

- [ ] 2. Core `st` Script — Basic Grid Creation

  **What to do**:
  - Create the `st` script (executable: `chmod +x st`)
  - Add shebang: `#!/usr/bin/env bash`
  - Add `set -euo pipefail` for safety
  - Implement basic argument parsing: `st <N> <command>`
    - `N` = number of panes (positive integer)
    - `command` = command to run in each pane
  - Implement core grid creation logic:
    1. Generate session name: `st-${command_basename}-${N}` (e.g., `st-opencode-4`)
    2. Create detached tmux session: `tmux new-session -d -s "$session_name" -c "$PWD"`
    3. Send command to first pane: `tmux send-keys -t "$session_name" "$command" Enter`
    4. Loop N-1 times: `tmux split-window -t "$session_name" -c "$PWD"` + `tmux send-keys ... "$command" Enter`
    5. Apply tiled layout: `tmux select-layout -t "$session_name" tiled`
    6. Attach to session: `tmux attach-session -t "$session_name"`
  - Implement basic `--help` / `-h` flag showing usage
  - Add a `usage()` function that prints:
    ```
    Usage: st <panes> <command> [options]
    
    Spawn a tmux grid layout with <panes> panes, each running <command>.
    
    Examples:
      st 4 opencode    # 2x2 grid, each pane runs opencode
      st 6 htop        # 3x2 grid, each pane runs htop
    
    Options:
      -h, --help       Show this help message
    ```

  **Must NOT do**:
  - Do NOT implement --fresh, --name, --detach yet (T3-T5)
  - Do NOT implement error handling/validation yet (T4)
  - Do NOT implement session management subcommands yet (T5)
  - Do NOT implement YAML preset loading yet (T7)
  - Do NOT use `tmux attach` in QA scenarios (blocks agent) — use `--detach` mode for testing by manually not attaching

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Core script logic with tmux integration — needs careful implementation of the main grid creation algorithm, proper quoting, and send-keys patterns
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable for Bash scripting

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 8)
  - **Parallel Group**: Wave 2 (with Task 8)
  - **Blocks**: Task 3
  - **Blocked By**: Task 1

  **References**:

  **Pattern References**:
  - tmux grid creation pattern (from research):
    ```bash
    tmux new-session -d -s "name" -c "$PWD"
    tmux send-keys -t "name" "command" Enter
    for i in $(seq 2 $N); do
      tmux split-window -t "name" -c "$PWD"
      tmux send-keys -t "name" "command" Enter
    done
    tmux select-layout -t "name" tiled
    tmux attach-session -t "name"
    ```

  **External References**:
  - tmux man page: `new-session`, `split-window`, `send-keys`, `select-layout`, `attach-session`
  - `send-keys` uses `Enter` (not `C-m`) for readability: `tmux send-keys -t target "cmd" Enter`

  **WHY Each Reference Matters**:
  - The tmux pattern is the ENTIRE core algorithm — follow it exactly
  - `send-keys` + `Enter` keeps the shell alive after command exits (critical UX)
  - `-c "$PWD"` ensures all panes open in the user's current directory
  - `select-layout tiled` handles grid math automatically (no manual NxM calculation)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Basic 4-pane grid creation
    Tool: Bash
    Preconditions: tmux installed, no session named st-echo-4 exists
    Steps:
      1. Run `tmux kill-session -t st-echo-4 2>/dev/null` (cleanup)
      2. Run `./st 4 "echo hello"` but modify test to NOT attach — instead test by running the script in a way that creates the session detached for testing:
         Create a temporary test: `tmux new-session -d -s st-echo-4 -c "$PWD" && tmux send-keys -t st-echo-4 "echo hello" Enter && for i in 2 3 4; do tmux split-window -t st-echo-4 -c "$PWD" && tmux send-keys -t st-echo-4 "echo hello" Enter; done && tmux select-layout -t st-echo-4 tiled`
         OR better: Invoke `./st 4 "echo hello"` with the environment set so it does NOT attach (task should support this — see note below)
      3. Run `tmux has-session -t st-echo-4 && echo PASS || echo FAIL`
      4. Run `tmux list-panes -t st-echo-4 | wc -l` → expect "4"
      5. Run `tmux kill-session -t st-echo-4` (cleanup)
    Expected Result: Session "st-echo-4" created with exactly 4 panes
    Failure Indicators: Session doesn't exist or pane count != 4
    Evidence: .sisyphus/evidence/task-2-basic-grid.txt

  NOTE FOR AGENT: To test without attaching (which would block), either:
  (a) The script's attach line should be skippable — check if stdout is a tty,
      or temporarily comment out the attach line for testing, or
  (b) Run the script and immediately Ctrl-C the attach (send SIGINT after a delay)
  (c) Best approach: Have the script check if STDIN is a TTY (`[[ -t 0 ]]`). If not
      (e.g., running in background or piped), skip the attach step. This makes testing
      natural: `./st 4 "echo hello" < /dev/null` will create session without attaching.
  The QA agent should use approach (c) by running: `./st 4 "echo hello" < /dev/null`

  Scenario: Help output works
    Tool: Bash
    Preconditions: st script exists and is executable
    Steps:
      1. Run `./st --help`
      2. Assert output contains "Usage"
      3. Assert output contains "panes"
      4. Assert output contains "Examples"
    Expected Result: Help text displayed with usage info
    Failure Indicators: No output or missing key sections
    Evidence: .sisyphus/evidence/task-2-help-output.txt

  Scenario: Single pane (edge case — no splits needed)
    Tool: Bash
    Preconditions: tmux installed, no session named st-echo-1
    Steps:
      1. Run `tmux kill-session -t st-echo-1 2>/dev/null`
      2. Run `./st 1 "echo hello" < /dev/null`
      3. Run `tmux has-session -t st-echo-1 && echo PASS || echo FAIL`
      4. Run `tmux list-panes -t st-echo-1 | wc -l` → expect "1"
      5. Run `tmux kill-session -t st-echo-1`
    Expected Result: Session created with 1 pane, no splits, command runs
    Failure Indicators: Split attempted on single pane or session doesn't exist
    Evidence: .sisyphus/evidence/task-2-single-pane.txt

  Scenario: Script is valid Bash
    Tool: Bash
    Preconditions: st script exists
    Steps:
      1. Run `bash -n st` → expect exit code 0
      2. Run `file st` → expect output containing "script" or "text"
      3. Run `head -1 st` → expect "#!/usr/bin/env bash"
    Expected Result: Valid Bash syntax with proper shebang
    Failure Indicators: bash -n returns non-zero or wrong shebang
    Evidence: .sisyphus/evidence/task-2-syntax-check.txt
  ```

  **Evidence to Capture:**
  - [ ] task-2-basic-grid.txt — 4-pane creation and verification
  - [ ] task-2-help-output.txt — help flag output
  - [ ] task-2-single-pane.txt — single pane edge case
  - [ ] task-2-syntax-check.txt — bash -n result

  **Commit**: YES
  - Message: `feat: add core st script with basic grid creation`
  - Files: `st`
  - Pre-commit: `bash -n st`

- [ ] 3. Session Handling — Reattach, --fresh, --name Flags

  **What to do**:
  - Add session reattach logic: before creating a new session, check `tmux has-session -t "$session_name" 2>/dev/null`
    - If session exists AND `--fresh` not passed: attach to existing session (`tmux attach-session -t "$session_name"`)
    - If session exists AND `--fresh` passed: kill existing (`tmux kill-session -t "$session_name"`) then create fresh
    - If session doesn't exist: create new (existing behavior)
  - Add `--fresh` / `-f` flag to argument parsing
  - Add `--name` / `-n` flag to override the auto-generated session name
    - When `--name` is provided, use `st-${user_provided_name}` as session name (always prefix with `st-`)
    - Validate: session names must NOT contain colons or periods (tmux target syntax conflict)
  - Update `usage()` function to document new flags
  - Ensure all session names always have `st-` prefix

  **Must NOT do**:
  - Do NOT implement --detach yet (T5)
  - Do NOT implement error handling for tmux-not-installed (T4)
  - Do NOT implement session management subcommands (T5)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Multiple interacting features (reattach logic, flag parsing, session naming) that need careful integration with existing code
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (alone)
  - **Blocks**: Task 4
  - **Blocked By**: Task 2

  **References**:

  **Pattern References**:
  - `st` script from Task 2 — the existing arg parsing and session creation logic to extend

  **External References**:
  - `tmux has-session -t "name" 2>/dev/null` — returns 0 if session exists, 1 if not
  - `tmux kill-session -t "name"` — destroys a session
  - tmux session name restrictions: no colons (`:`) or periods (`.`) in names

  **WHY Each Reference Matters**:
  - `has-session` is the idempotency check — prevents duplicate session creation
  - Session name validation prevents cryptic tmux errors when names contain `:` or `.`
  - `st-` prefix isolates our sessions from user's manually-created tmux sessions

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Reattach to existing session (no --fresh)
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-session -t st-echo-4 2>/dev/null`
      2. Run `./st 4 "echo hello" < /dev/null` (creates session)
      3. Verify: `tmux has-session -t st-echo-4 && echo PASS`
      4. Run `./st 4 "echo hello" < /dev/null` (should reattach, not error)
      5. Verify: `tmux list-panes -t st-echo-4 | wc -l` → still "4" (not 8)
      6. Run `tmux kill-session -t st-echo-4`
    Expected Result: Second invocation reattaches to existing session, doesn't create new panes
    Failure Indicators: Pane count doubled, or error on second invocation
    Evidence: .sisyphus/evidence/task-3-reattach.txt

  Scenario: --fresh recreates session
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-session -t st-echo-4 2>/dev/null`
      2. Run `./st 4 "echo first" < /dev/null` (creates session)
      3. Run `./st --fresh 4 "echo second" < /dev/null` (should recreate)
      4. Verify: `tmux has-session -t st-echo-4 && echo PASS`
      5. Verify: `tmux list-panes -t st-echo-4 | wc -l` → "4"
      6. Verify: `tmux capture-pane -t st-echo-4:0.0 -p | tail -5` → should contain "second" (not "first")
      7. Run `tmux kill-session -t st-echo-4`
    Expected Result: Old session killed, new session created with "echo second"
    Failure Indicators: Old session persists, or capture-pane shows "first"
    Evidence: .sisyphus/evidence/task-3-fresh-flag.txt

  Scenario: --name flag overrides session name
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-session -t st-myproject 2>/dev/null`
      2. Run `./st --name myproject 4 "echo hello" < /dev/null`
      3. Verify: `tmux has-session -t st-myproject && echo PASS`
      4. Verify: `tmux list-panes -t st-myproject | wc -l` → "4"
      5. Run `tmux kill-session -t st-myproject`
    Expected Result: Session named "st-myproject" instead of auto-generated name
    Failure Indicators: Session name doesn't match, or auto-generated name used instead
    Evidence: .sisyphus/evidence/task-3-name-flag.txt

  Scenario: Invalid session name rejected (contains colon)
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `./st --name "bad:name" 4 "echo hello" < /dev/null 2>&1`
      2. Assert output contains error about invalid name
      3. Verify: `tmux has-session -t "st-bad:name" 2>/dev/null && echo FAIL || echo PASS`
    Expected Result: Error message about invalid characters, no session created
    Failure Indicators: Session created with colon in name, or no error message
    Evidence: .sisyphus/evidence/task-3-invalid-name.txt
  ```

  **Evidence to Capture:**
  - [ ] task-3-reattach.txt — reattach behavior verification
  - [ ] task-3-fresh-flag.txt — --fresh recreation verification
  - [ ] task-3-name-flag.txt — --name override verification
  - [ ] task-3-invalid-name.txt — name validation error

  **Commit**: YES
  - Message: `feat: add session reattach, --fresh and --name flags`
  - Files: `st`
  - Pre-commit: `bash -n st`

- [ ] 4. Error Handling — tmux Check, Nested tmux, Input Validation

  **What to do**:
  - Add tmux installation check at script start:
    - `command -v tmux >/dev/null 2>&1 || die "tmux is not installed. Install with: sudo apt install tmux"`
  - Add nested tmux detection:
    - Check `$TMUX` environment variable
    - If set, print warning: `"Warning: Running inside an existing tmux session. This will create a nested session."`
    - Continue execution (don't block) — user may want nested sessions
  - Add input validation:
    - Pane count must be a positive integer (`[[ "$N" =~ ^[0-9]+$ ]] && [ "$N" -gt 0 ]`)
    - Pane count soft cap: warn if >16, block if >50 (unless `--force` flag passed)
    - Command argument must not be empty
    - Print clear error messages with usage hint on validation failure
  - Add `--force` flag to argument parsing (bypasses pane count limit)
  - Handle `split-window` failures gracefully:
    - Check exit code after each split
    - If split fails (terminal too small), kill the partial session and print error:
      `"Error: Terminal too small for $N panes. Try reducing pane count or maximizing your terminal."`
  - Add a `die()` helper function for error messages (prints to stderr, exits 1)
  - Update `usage()` to document `--force` flag

  **Must NOT do**:
  - Do NOT add --detach or session management (T5)
  - Do NOT add layout options (T6)
  - Do NOT add YAML preset support (T7)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Multiple validation paths with edge cases; needs careful error handling that doesn't break existing functionality
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (alone)
  - **Blocks**: Task 5
  - **Blocked By**: Task 3

  **References**:

  **Pattern References**:
  - `st` script from Task 3 — existing arg parsing to extend with new flags

  **External References**:
  - `$TMUX` env var: set by tmux when inside a session (contains socket path)
  - Bash pattern for integer validation: `[[ "$var" =~ ^[0-9]+$ ]]`
  - `command -v` preferred over `which` for portability

  **WHY Each Reference Matters**:
  - `$TMUX` check prevents the common "nested tmux" foot-gun
  - `command -v` is POSIX-compliant and more reliable than `which`
  - Integer regex prevents `st abc opencode` from silently failing

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: tmux not installed → helpful error
    Tool: Bash
    Preconditions: st script exists
    Steps:
      1. Run `PATH=/nonexistent ./st 4 "echo hello" 2>&1`
      2. Assert output contains "tmux" and "not installed" (case-insensitive)
      3. Assert exit code is non-zero: `echo $?` → not "0"
    Expected Result: Clear error message mentioning tmux installation
    Failure Indicators: No error, or cryptic error, or exit code 0
    Evidence: .sisyphus/evidence/task-4-no-tmux.txt

  Scenario: Invalid pane count (zero)
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `./st 0 "echo hello" 2>&1`
      2. Assert output contains "error" or "invalid" or "must be" (case-insensitive)
      3. Assert exit code is non-zero
    Expected Result: Error about invalid pane count
    Failure Indicators: No error, or session created with 0 panes
    Evidence: .sisyphus/evidence/task-4-zero-panes.txt

  Scenario: Invalid pane count (non-integer)
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `./st abc "echo hello" 2>&1`
      2. Assert output contains "error" or "invalid" or "integer" (case-insensitive)
      3. Assert exit code is non-zero
    Expected Result: Error about non-integer pane count
    Failure Indicators: No error, or attempt to create panes
    Evidence: .sisyphus/evidence/task-4-non-integer.txt

  Scenario: Pane count exceeds soft cap (>16)
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `./st 20 "echo hello" < /dev/null 2>&1`
      2. Assert output contains "warning" or "exceed" or "maximum" (case-insensitive)
      3. Assert exit code is non-zero (blocked without --force)
    Expected Result: Warning/error about exceeding pane limit
    Failure Indicators: 20 panes created silently
    Evidence: .sisyphus/evidence/task-4-pane-cap.txt

  Scenario: --force bypasses pane cap
    Tool: Bash
    Preconditions: tmux installed, large enough terminal
    Steps:
      1. Run `tmux kill-session -t st-echo-20 2>/dev/null`
      2. Run `./st --force 20 "echo hello" < /dev/null 2>&1`
      3. Verify: `tmux has-session -t st-echo-20 && echo PASS || echo FAIL`
      4. Run `tmux kill-session -t st-echo-20 2>/dev/null`
    Expected Result: Session created despite >16 panes (with --force)
    Failure Indicators: Still blocked even with --force
    Evidence: .sisyphus/evidence/task-4-force-flag.txt

  Scenario: No command specified → usage error
    Tool: Bash
    Preconditions: st script exists
    Steps:
      1. Run `./st 4 2>&1`
      2. Assert output contains "usage" or "command" (case-insensitive)
      3. Assert exit code is non-zero
    Expected Result: Usage message shown when command is missing
    Failure Indicators: No output, or attempt to create empty session
    Evidence: .sisyphus/evidence/task-4-no-command.txt

  Scenario: Nested tmux warning
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `TMUX="/tmp/tmux-fake/default,12345,0" ./st 4 "echo hello" < /dev/null 2>&1`
      2. Assert output contains "warning" or "nested" (case-insensitive)
      3. Verify session was still created (warning, not block):
         `tmux has-session -t st-echo-4 && echo PASS || echo FAIL`
      4. Run `tmux kill-session -t st-echo-4`
    Expected Result: Warning printed but session still created
    Failure Indicators: No warning, or execution blocked entirely
    Evidence: .sisyphus/evidence/task-4-nested-tmux.txt
  ```

  **Evidence to Capture:**
  - [ ] task-4-no-tmux.txt — tmux not installed error
  - [ ] task-4-zero-panes.txt — zero pane count error
  - [ ] task-4-non-integer.txt — non-integer pane count error
  - [ ] task-4-pane-cap.txt — pane count soft cap behavior
  - [ ] task-4-force-flag.txt — --force bypass verification
  - [ ] task-4-no-command.txt — missing command error
  - [ ] task-4-nested-tmux.txt — nested tmux warning

  **Commit**: YES
  - Message: `feat: add error handling, tmux detection, and input validation`
  - Files: `st`
  - Pre-commit: `bash -n st`

- [ ] 5. --detach Mode + Session Management (list, kill, help)

  **What to do**:
  - Add `--detach` / `-d` flag:
    - When passed, create the tmux session but do NOT attach
    - Script exits immediately after session creation
    - Print: `"Session 'st-xxx' created with N panes (detached). Attach with: tmux attach -t st-xxx"`
  - Refactor the attach logic:
    - Current behavior: always attach after creation
    - New behavior: attach only if `--detach` not passed AND stdin is a TTY (`[[ -t 0 ]]`)
    - If stdin is not a TTY (piped/background), behave like `--detach`
  - Add session management subcommands:
    - `st list` — List all `st-` prefixed tmux sessions
      - Use `tmux list-sessions -F "#{session_name} #{session_windows} windows, #{session_attached} attached" 2>/dev/null | grep "^st-"`
      - If no sessions: print "No active st sessions."
    - `st kill <session-name>` — Kill a specific st-managed session
      - Validate: session name must start with `st-` prefix (refuse to kill non-st sessions)
      - If session doesn't exist: print error "Session 'X' not found."
      - On success: print "Session 'X' killed."
    - `st kill --all` — Kill ALL `st-` prefixed sessions
      - Confirm by listing what will be killed, then kill
    - `st help` — Alias for `st --help`
  - Restructure argument parsing to handle subcommands:
    - First arg is either a subcommand (`list`, `kill`, `help`) or a number (pane count)
    - If first arg is a number → grid creation mode
    - If first arg is a subcommand → dispatch to subcommand handler

  **Must NOT do**:
  - Do NOT implement layout options (T6)
  - Do NOT implement YAML presets (T7)
  - Do NOT kill non-st sessions (safety guardrail)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Multiple interacting features (detach mode, subcommand routing, session management) with careful tmux integration
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 5 (alone)
  - **Blocks**: Task 6
  - **Blocked By**: Task 4

  **References**:

  **Pattern References**:
  - `st` script from Task 4 — existing arg parsing to restructure for subcommands

  **External References**:
  - `tmux list-sessions -F "FORMAT"` — custom format strings for machine-readable output
    - `#{session_name}` — session name
    - `#{session_windows}` — window count
    - `#{session_attached}` — whether attached (0/1)
  - `[[ -t 0 ]]` — Bash test for whether stdin is a terminal (TTY)

  **WHY Each Reference Matters**:
  - `-F` format strings make `st list` output clean and parseable
  - TTY detection enables non-blocking behavior when running in scripts/CI
  - Subcommand dispatch pattern must be clean — first check if arg is subcommand, then fall through to number-based grid creation

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: --detach creates session without attaching
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-session -t st-echo-4 2>/dev/null`
      2. Run `./st --detach 4 "echo hello"` (should return immediately, no attach)
      3. Assert script exited (didn't hang): `echo $?` → "0"
      4. Verify: `tmux has-session -t st-echo-4 && echo PASS || echo FAIL`
      5. Verify: `tmux list-panes -t st-echo-4 | wc -l` → "4"
      6. Run `tmux kill-session -t st-echo-4`
    Expected Result: Session created, script exits immediately, panes exist
    Failure Indicators: Script hangs (blocks on attach), or session not created
    Evidence: .sisyphus/evidence/task-5-detach-mode.txt

  Scenario: st list shows active sessions
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-server 2>/dev/null` (clean state)
      2. Run `./st --detach 4 "echo hello"` (create a session)
      3. Run `./st --detach --name testlist 2 "echo world"` (create another)
      4. Run `./st list`
      5. Assert output contains "st-echo-4"
      6. Assert output contains "st-testlist"
      7. Run `tmux kill-server 2>/dev/null` (cleanup)
    Expected Result: Both st-managed sessions listed
    Failure Indicators: Missing sessions, or non-st sessions shown
    Evidence: .sisyphus/evidence/task-5-list-sessions.txt

  Scenario: st list with no sessions
    Tool: Bash
    Preconditions: tmux installed, no active sessions
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Run `./st list`
      3. Assert output contains "No active" or "no sessions" (case-insensitive)
    Expected Result: Clean message indicating no sessions
    Failure Indicators: Error, or empty output with no message
    Evidence: .sisyphus/evidence/task-5-list-empty.txt

  Scenario: st kill specific session
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Run `./st --detach 4 "echo hello"`
      3. Run `./st kill st-echo-4`
      4. Assert output contains "killed" or "destroyed" (case-insensitive)
      5. Verify: `tmux has-session -t st-echo-4 2>/dev/null && echo FAIL || echo PASS`
    Expected Result: Session killed, confirmation message shown
    Failure Indicators: Session still exists, or error message
    Evidence: .sisyphus/evidence/task-5-kill-session.txt

  Scenario: st kill non-existent session
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Run `./st kill st-nonexistent 2>&1`
      3. Assert output contains "not found" or "does not exist" (case-insensitive)
      4. Assert exit code is non-zero
    Expected Result: Clear error message about non-existent session
    Failure Indicators: Silent failure or tmux stderr dump
    Evidence: .sisyphus/evidence/task-5-kill-nonexistent.txt

  Scenario: st kill refuses non-st sessions
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux new-session -d -s "user-manual-session"`
      2. Run `./st kill user-manual-session 2>&1`
      3. Assert output contains "not an st session" or "must start with st-" (case-insensitive)
      4. Verify manual session still exists: `tmux has-session -t user-manual-session && echo PASS`
      5. Run `tmux kill-session -t user-manual-session`
    Expected Result: Refuses to kill non-st-prefixed session
    Failure Indicators: Manual session killed, or no error message
    Evidence: .sisyphus/evidence/task-5-kill-safety.txt

  Scenario: st help subcommand
    Tool: Bash
    Preconditions: st script exists
    Steps:
      1. Run `./st help 2>&1`
      2. Assert output contains "Usage"
      3. Assert output matches `./st --help` output
    Expected Result: Same output as --help
    Failure Indicators: Different output or error
    Evidence: .sisyphus/evidence/task-5-help-subcommand.txt
  ```

  **Evidence to Capture:**
  - [ ] task-5-detach-mode.txt — detach flag verification
  - [ ] task-5-list-sessions.txt — list subcommand
  - [ ] task-5-list-empty.txt — list with no sessions
  - [ ] task-5-kill-session.txt — kill specific session
  - [ ] task-5-kill-nonexistent.txt — kill non-existent error
  - [ ] task-5-kill-safety.txt — kill safety guardrail
  - [ ] task-5-help-subcommand.txt — help subcommand

  **Commit**: YES
  - Message: `feat: add --detach mode and session management subcommands`
  - Files: `st`
  - Pre-commit: `bash -n st`

- [ ] 6. Layout Options — --layout Flag

  **What to do**:
  - Add `--layout` / `-l` flag to specify tmux layout instead of default `tiled`
  - Supported layouts (tmux built-in):
    - `tiled` (default) — even grid distribution
    - `even-horizontal` — all panes side by side horizontally
    - `even-vertical` — all panes stacked vertically
    - `main-horizontal` — one large pane on top, rest stacked below
    - `main-vertical` — one large pane on left, rest stacked on right
  - Validate layout name: if unknown layout provided, print error with list of valid options
  - Apply layout after all panes are created: `tmux select-layout -t "$session_name" "$layout"`
  - Update `usage()` to document layout options and available values

  **Must NOT do**:
  - Do NOT implement custom NxM grid calculations (rely on tmux's built-in layouts)
  - Do NOT implement custom pane size percentages (tmux handles this per layout)
  - Do NOT implement YAML presets (T7)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small, focused change — add one flag and replace a hardcoded string with a variable
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 6 (alone)
  - **Blocks**: Task 7
  - **Blocked By**: Task 5

  **References**:

  **Pattern References**:
  - `st` script from Task 5 — existing flag parsing pattern to follow for --layout

  **External References**:
  - tmux layouts: `tiled`, `even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`
  - `tmux select-layout -t target layout_name` — applies named layout

  **WHY Each Reference Matters**:
  - These are tmux's ONLY built-in named layouts — the validation list must match exactly
  - `select-layout` must be called AFTER all panes exist (order matters)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Default layout is tiled (unchanged behavior)
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-session -t st-echo-4 2>/dev/null`
      2. Run `./st --detach 4 "echo hello"`
      3. Run `tmux list-windows -t st-echo-4 -F "#{window_layout}"` → capture layout string
      4. Run `tmux kill-session -t st-echo-4`
    Expected Result: Session created with tiled layout (default, same as before)
    Failure Indicators: Layout not applied or error
    Evidence: .sisyphus/evidence/task-6-default-layout.txt

  Scenario: --layout main-vertical applies correct layout
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-session -t st-echo-4 2>/dev/null`
      2. Run `./st --detach --layout main-vertical 4 "echo hello"`
      3. Run `tmux has-session -t st-echo-4 && echo PASS || echo FAIL`
      4. Run `tmux list-panes -t st-echo-4 | wc -l` → "4"
      5. Run `tmux kill-session -t st-echo-4`
    Expected Result: 4 panes with main-vertical layout applied
    Failure Indicators: Session not created or wrong pane count
    Evidence: .sisyphus/evidence/task-6-main-vertical.txt

  Scenario: Invalid layout name → error with valid options
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `./st --detach --layout foobar 4 "echo hello" 2>&1`
      2. Assert output contains "invalid" or "unknown" layout (case-insensitive)
      3. Assert output lists valid options (contains "tiled" and "main-vertical")
      4. Assert exit code is non-zero
    Expected Result: Error message listing valid layout options
    Failure Indicators: Session created with invalid layout, or no helpful error
    Evidence: .sisyphus/evidence/task-6-invalid-layout.txt

  Scenario: --layout even-horizontal with 3 panes
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-session -t st-echo-3 2>/dev/null`
      2. Run `./st --detach --layout even-horizontal 3 "echo hello"`
      3. Run `tmux has-session -t st-echo-3 && echo PASS || echo FAIL`
      4. Run `tmux list-panes -t st-echo-3 | wc -l` → "3"
      5. Run `tmux kill-session -t st-echo-3`
    Expected Result: 3 side-by-side panes
    Failure Indicators: Wrong pane count or layout error
    Evidence: .sisyphus/evidence/task-6-even-horizontal.txt
  ```

  **Evidence to Capture:**
  - [ ] task-6-default-layout.txt — default tiled layout
  - [ ] task-6-main-vertical.txt — main-vertical layout
  - [ ] task-6-invalid-layout.txt — invalid layout error
  - [ ] task-6-even-horizontal.txt — even-horizontal layout

  **Commit**: YES
  - Message: `feat: add --layout flag with tmux preset layouts`
  - Files: `st`
  - Pre-commit: `bash -n st`

- [ ] 7. YAML Preset Support + Example Configs

  **What to do**:
  - Add `--preset` / `-p` flag to load a named preset from config directory
  - Config directory: `${XDG_CONFIG_HOME:-$HOME/.config}/st/`
  - Preset file lookup: `${config_dir}/${preset_name}.yaml`
  - YAML parsing strategy (MUST follow this order):
    1. Check if `yq` is available (`command -v yq`)
    2. If `yq` available: use `yq '.field' file.yaml` for parsing
    3. If `yq` NOT available: use simple Bash parsing for flat YAML:
       `grep "^key:" file.yaml | sed 's/^key:[[:space:]]*//'`
    4. For the simple parser, ONLY support flat key-value YAML (no nested structures)
  - YAML schema (keep it simple and flat for Bash parsing compatibility):
    ```yaml
    name: dev
    panes: 4
    command: opencode
    layout: tiled
    directory: /home/user/project
    ```
  - Supported preset fields:
    - `name` (required) — session name (will be prefixed with `st-`)
    - `panes` (required) — number of panes
    - `command` (required) — command to run in each pane
    - `layout` (optional, default: `tiled`) — tmux layout name
    - `directory` (optional, default: CWD) — working directory for panes
  - Create example preset files in `examples/` directory:
    - `examples/dev.yaml` — 4 panes running opencode
    - `examples/monitor.yaml` — 6 panes running htop
  - Add `st init` subcommand that creates the config directory and copies example presets:
    - `mkdir -p "${config_dir}"`
    - Copy `examples/*.yaml` to `${config_dir}/`
    - Print: "Config directory created at ${config_dir}. Example presets copied."
  - Error handling:
    - Missing preset file: `"Preset 'X' not found. Available presets: ..."` (list .yaml files in config dir)
    - Missing required field: `"Preset 'X' missing required field: name"`
    - Invalid field values: reuse existing validation (pane count, layout name)
  - If both `--preset` and inline args are provided, inline args override preset values
  - Update `usage()` to document --preset, preset file format, and `st init`

  **Must NOT do**:
  - Do NOT support nested YAML structures (arrays, maps) in pure Bash parser
  - Do NOT require `yq` as mandatory dependency
  - Do NOT support per-pane different commands (all panes run same command — v1 design)
  - Do NOT modify user's existing config files

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: File I/O, YAML parsing in Bash (tricky), config directory management, and integration with existing flag system
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 7 (alone)
  - **Blocks**: Tasks 9, 10
  - **Blocked By**: Task 6

  **References**:

  **Pattern References**:
  - `st` script from Task 6 — existing flag parsing and grid creation to integrate with

  **External References**:
  - `yq` (mikefarah/yq): `yq '.name' file.yaml` → outputs the value of "name" field
  - `yq --version` → Go yq prints `yq (https://github.com/mikefarah/yq/) version v4.x`
  - Bash YAML parsing: `grep "^key:" file | sed 's/^key:[[:space:]]*//'` for flat key:value pairs
  - XDG Base Directory: `${XDG_CONFIG_HOME:-$HOME/.config}` is the standard config path

  **WHY Each Reference Matters**:
  - `yq` is the robust path but not always installed — fallback is essential
  - Flat YAML keeps the Bash parser reliable — no nested structures
  - XDG compliance is expected for modern CLI tools on Linux
  - Example presets give users a starting point and serve as documentation

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Load preset from config directory
    Tool: Bash
    Preconditions: tmux installed, yq or Bash parser available
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Create test config:
         mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/st"
         cat > "${XDG_CONFIG_HOME:-$HOME/.config}/st/testpreset.yaml" << 'EOF'
         name: testpreset
         panes: 3
         command: echo hello
         layout: tiled
         EOF
      3. Run `./st --detach --preset testpreset`
      4. Verify: `tmux has-session -t st-testpreset && echo PASS || echo FAIL`
      5. Verify: `tmux list-panes -t st-testpreset | wc -l` → "3"
      6. Run `tmux kill-session -t st-testpreset`
      7. Run `rm "${XDG_CONFIG_HOME:-$HOME/.config}/st/testpreset.yaml"` (cleanup)
    Expected Result: Session created from preset with correct pane count and name
    Failure Indicators: Session not created, wrong pane count, or YAML parse error
    Evidence: .sisyphus/evidence/task-7-load-preset.txt

  Scenario: Missing preset → error with available presets
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `./st --detach --preset nonexistent 2>&1`
      2. Assert output contains "not found" (case-insensitive)
      3. Assert exit code is non-zero
    Expected Result: Error message indicating preset not found
    Failure Indicators: Silent failure or cryptic error
    Evidence: .sisyphus/evidence/task-7-missing-preset.txt

  Scenario: Preset with directory field
    Tool: Bash
    Preconditions: tmux installed, /tmp exists
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Create test config:
         mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/st"
         cat > "${XDG_CONFIG_HOME:-$HOME/.config}/st/dirtest.yaml" << 'EOF'
         name: dirtest
         panes: 2
         command: pwd
         layout: tiled
         directory: /tmp
         EOF
      3. Run `./st --detach --preset dirtest`
      4. Verify: `tmux has-session -t st-dirtest && echo PASS || echo FAIL`
      5. Verify panes are in /tmp: `tmux capture-pane -t st-dirtest:0.0 -p | grep -q "/tmp" && echo PASS || echo FAIL`
      6. Run `tmux kill-session -t st-dirtest`
      7. Run `rm "${XDG_CONFIG_HOME:-$HOME/.config}/st/dirtest.yaml"` (cleanup)
    Expected Result: Panes open in /tmp directory
    Failure Indicators: Panes in wrong directory
    Evidence: .sisyphus/evidence/task-7-preset-directory.txt

  Scenario: st init creates config directory with examples
    Tool: Bash
    Preconditions: Config directory may or may not exist
    Steps:
      1. Run `backup="${XDG_CONFIG_HOME:-$HOME/.config}/st.bak" && mv "${XDG_CONFIG_HOME:-$HOME/.config}/st" "$backup" 2>/dev/null`
      2. Run `./st init`
      3. Assert output contains "created" or "copied" (case-insensitive)
      4. Verify: `test -d "${XDG_CONFIG_HOME:-$HOME/.config}/st" && echo PASS || echo FAIL`
      5. Verify: `ls "${XDG_CONFIG_HOME:-$HOME/.config}/st/"*.yaml | wc -l` → at least "2"
      6. Restore: `rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/st" && mv "$backup" "${XDG_CONFIG_HOME:-$HOME/.config}/st" 2>/dev/null`
    Expected Result: Config directory created with example presets
    Failure Indicators: Directory not created or no preset files
    Evidence: .sisyphus/evidence/task-7-init-command.txt

  Scenario: Example preset files are valid YAML
    Tool: Bash
    Preconditions: examples/ directory exists
    Steps:
      1. Verify `test -f examples/dev.yaml && echo PASS || echo FAIL`
      2. Verify `test -f examples/monitor.yaml && echo PASS || echo FAIL`
      3. Verify dev.yaml has required fields: `grep -q "^name:" examples/dev.yaml && grep -q "^panes:" examples/dev.yaml && grep -q "^command:" examples/dev.yaml && echo PASS || echo FAIL`
      4. Verify monitor.yaml has required fields: same checks
    Expected Result: Both example presets exist with required fields
    Failure Indicators: Missing files or fields
    Evidence: .sisyphus/evidence/task-7-example-presets.txt

  Scenario: Inline args override preset values
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Create test preset with 3 panes:
         mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/st"
         cat > "${XDG_CONFIG_HOME:-$HOME/.config}/st/override.yaml" << 'EOF'
         name: override
         panes: 3
         command: echo preset
         layout: tiled
         EOF
      3. Run `./st --detach --preset override 5 "echo inline"` (override panes=5 and command)
      4. Verify: `tmux list-panes -t st-override | wc -l` → "5" (not 3)
      5. Run `tmux kill-session -t st-override`
      6. Run `rm "${XDG_CONFIG_HOME:-$HOME/.config}/st/override.yaml"` (cleanup)
    Expected Result: Inline args (5 panes, "echo inline") override preset values (3 panes, "echo preset")
    Failure Indicators: Pane count is 3 (preset value not overridden)
    Evidence: .sisyphus/evidence/task-7-inline-override.txt
  ```

  **Evidence to Capture:**
  - [ ] task-7-load-preset.txt — preset loading
  - [ ] task-7-missing-preset.txt — missing preset error
  - [ ] task-7-preset-directory.txt — preset with directory field
  - [ ] task-7-init-command.txt — st init subcommand
  - [ ] task-7-example-presets.txt — example file validation
  - [ ] task-7-inline-override.txt — inline override behavior

  **Commit**: YES
  - Message: `feat: add YAML preset support with example configs`
  - Files: `st`, `examples/dev.yaml`, `examples/monitor.yaml`
  - Pre-commit: `bash -n st`

- [ ] 8. install.sh Script

  **What to do**:
  - Create `install.sh` script (executable: `chmod +x install.sh`)
  - Installation logic:
    1. Determine install directory:
       - If `~/.local/bin` exists and is in PATH → use it (no sudo needed)
       - Else if user has write access to `/usr/local/bin` → use it
       - Else → ask to create `~/.local/bin` and add to PATH
    2. Create symlink: `ln -sf "$(readlink -f st)" "$install_dir/st"`
    3. Verify: `command -v st` works after installation
    4. Print success message with the install path
  - Add uninstall support: `./install.sh --uninstall`
    - Remove the symlink
    - Print confirmation
  - Check that `st` file exists and is executable before installing
  - Handle case where `st` symlink already exists (update it)
  - Print clear instructions if PATH needs modification

  **Must NOT do**:
  - Do NOT require sudo unless absolutely necessary
  - Do NOT modify shell rc files (.bashrc/.zshrc) automatically
  - Do NOT copy the script (symlink only — so updates are automatic)
  - Do NOT install tmux or shellcheck (that's the user's responsibility)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple script creating a symlink — straightforward logic
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 2)
  - **Parallel Group**: Wave 2 (with Task 2)
  - **Blocks**: Task 9
  - **Blocked By**: Task 1

  **References**:

  **Pattern References**:
  - None (independent script)

  **External References**:
  - `readlink -f` — resolve full absolute path of symlink target
  - `ln -sf` — create symlink, force overwrite if exists
  - `~/.local/bin` — XDG standard user-local binary directory

  **WHY Each Reference Matters**:
  - `readlink -f` ensures the symlink points to the correct absolute path regardless of where install.sh is run from
  - `-sf` makes reinstallation idempotent
  - `~/.local/bin` avoids needing sudo on most systems

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Install creates working symlink
    Tool: Bash
    Preconditions: st script exists and is executable
    Steps:
      1. Run `./install.sh 2>&1`
      2. Assert output contains "installed" or "symlink" (case-insensitive)
      3. Verify symlink exists: `ls -la $(which st 2>/dev/null) 2>&1`
      4. Verify st works: `st --help | grep -q "Usage" && echo PASS || echo FAIL`
    Expected Result: st is available on PATH and works
    Failure Indicators: st not found on PATH, or --help doesn't work
    Evidence: .sisyphus/evidence/task-8-install.txt

  Scenario: Uninstall removes symlink
    Tool: Bash
    Preconditions: st is installed
    Steps:
      1. Run `./install.sh --uninstall 2>&1`
      2. Assert output contains "removed" or "uninstalled" (case-insensitive)
      3. Verify: `which st 2>/dev/null && echo FAIL || echo PASS`
    Expected Result: st symlink removed, no longer on PATH
    Failure Indicators: st still available after uninstall
    Evidence: .sisyphus/evidence/task-8-uninstall.txt

  Scenario: Reinstall (idempotent)
    Tool: Bash
    Preconditions: st may or may not be installed
    Steps:
      1. Run `./install.sh` (first install)
      2. Run `./install.sh` (second install — should not error)
      3. Verify: `st --help | grep -q "Usage" && echo PASS || echo FAIL`
    Expected Result: Second install succeeds without error
    Failure Indicators: Error on second install
    Evidence: .sisyphus/evidence/task-8-reinstall.txt

  Scenario: install.sh validates st script exists
    Tool: Bash
    Preconditions: None
    Steps:
      1. Run `(cd /tmp && /home/vascosera/Documents/Github/SpawnTerminal/install.sh) 2>&1` from wrong directory
      2. Check behavior — script should either find st via its own directory or error helpfully
    Expected Result: Either works (finds st relative to install.sh) or gives clear error
    Failure Indicators: Cryptic error or installs non-existent file
    Evidence: .sisyphus/evidence/task-8-wrong-dir.txt
  ```

  **Evidence to Capture:**
  - [ ] task-8-install.txt — successful installation
  - [ ] task-8-uninstall.txt — uninstall verification
  - [ ] task-8-reinstall.txt — idempotent reinstall
  - [ ] task-8-wrong-dir.txt — running from wrong directory

  **Commit**: YES
  - Message: `feat: add install.sh script`
  - Files: `install.sh`
  - Pre-commit: `bash -n install.sh`

- [ ] 9. Edge Case Hardening + ShellCheck Compliance

  **What to do**:
  - Run `shellcheck st` and fix ALL warnings/errors:
    - Quote all variable expansions (`"$var"` not `$var`)
    - Use `[[ ]]` instead of `[ ]` where appropriate
    - Fix any word-splitting issues
    - Address SC2086 (double-quote to prevent globbing/word splitting)
    - Address SC2155 (declare and assign separately)
    - Address any other shellcheck findings
  - Run `shellcheck install.sh` and fix all findings
  - Handle edge cases:
    - **Single pane** (`st 1 command`): no `split-window` needed, just create session and send command
    - **Empty command** (`st 4 ""`): open 4 empty shells (valid use case, no send-keys needed)
    - **Command with spaces/quotes** (`st 4 "docker compose up --build"`): verify send-keys handles correctly
    - **Command with pipes** (`st 4 "tail -f log | grep error"`): verify send-keys handles correctly
    - **Very long command**: verify no truncation with send-keys
    - **Session name from complex command**: sanitize command names for session naming
      - e.g., `st 4 "docker compose up"` → session name `st-docker-4` (use first word only)
      - Strip special characters from auto-generated session names
    - **Concurrent invocations**: Two `st 4 opencode` at the same time should not conflict
      (if session exists, second one reattaches — already handled by T3)
    - **Kill session that doesn't exist**: clean error (already handled by T5, verify)
  - Verify `set -euo pipefail` doesn't cause unexpected exits:
    - `grep` returns 1 when no match — use `grep ... || true` where grep failure is expected
    - `tmux has-session` returns 1 when session doesn't exist — handle explicitly
  - Run full regression: execute ALL QA scenarios from T2-T8 to verify nothing broke
  - Final `bash -n st && shellcheck st` must both pass

  **Must NOT do**:
  - Do NOT add new features
  - Do NOT change any user-facing behavior
  - Do NOT remove the `set -euo pipefail`
  - Do NOT add excessive comments as "documentation" (AI slop)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Requires careful analysis of all code paths, shellcheck compliance, and regression testing across all features
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 10)
  - **Parallel Group**: Wave 8 (with Task 10)
  - **Blocks**: Final verification
  - **Blocked By**: Tasks 7, 8

  **References**:

  **Pattern References**:
  - `st` script — entire file needs review
  - `install.sh` — entire file needs review
  - All QA scenarios from Tasks 2-8 — run as regression suite

  **External References**:
  - ShellCheck wiki: https://www.shellcheck.net/wiki/ — explanations for each SC code
  - Common shellcheck fixes:
    - SC2086: `"$var"` instead of `$var`
    - SC2155: `local var; var=$(cmd)` instead of `local var=$(cmd)`
    - SC2181: Use `if cmd; then` instead of `cmd; if [ $? -eq 0 ]`

  **WHY Each Reference Matters**:
  - ShellCheck is the gold standard for Bash code quality
  - Edge cases like pipes in commands and empty commands are real user scenarios
  - Regression testing ensures hardening doesn't break existing features
  - `set -euo pipefail` interactions with grep/tmux exit codes are a common Bash pitfall

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: shellcheck passes with zero warnings
    Tool: Bash
    Preconditions: shellcheck installed, st and install.sh exist
    Steps:
      1. Run `shellcheck st 2>&1` → expect no output (or only info-level)
      2. Run `shellcheck install.sh 2>&1` → expect no output
      3. Assert exit codes are 0
    Expected Result: Both scripts pass shellcheck
    Failure Indicators: Any shellcheck warnings or errors
    Evidence: .sisyphus/evidence/task-9-shellcheck.txt

  Scenario: Command with spaces and quotes
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Run `./st --detach 2 "echo 'hello world'"`
      3. Verify: `tmux has-session -t st-echo-2 && echo PASS || echo FAIL`
      4. Verify: `tmux list-panes -t st-echo-2 | wc -l` → "2"
      5. Run `tmux capture-pane -t st-echo-2:0.0 -p | grep -q "hello world" && echo PASS || echo FAIL`
      6. Run `tmux kill-server 2>/dev/null`
    Expected Result: Command with quotes executes correctly in panes
    Failure Indicators: Command not sent, or quotes mangled
    Evidence: .sisyphus/evidence/task-9-command-spaces.txt

  Scenario: Command with pipes
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Run `./st --detach 2 "echo test | cat"`
      3. Verify: `tmux has-session -t st-echo-2 && echo PASS || echo FAIL`
      4. Run `tmux kill-server 2>/dev/null`
    Expected Result: Piped command handled correctly by send-keys
    Failure Indicators: Pipe interpreted by shell before reaching tmux
    Evidence: .sisyphus/evidence/task-9-command-pipes.txt

  Scenario: Empty command opens empty shells
    Tool: Bash
    Preconditions: tmux installed
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Run `./st --detach 3 ""` or `./st --detach 3` (if command is optional)
      3. If allowed: verify `tmux list-panes -t st-*` shows 3 panes
      4. If not allowed: verify clear error message
      5. Run `tmux kill-server 2>/dev/null`
    Expected Result: Either 3 empty shells created, or clear error
    Failure Indicators: Crash or cryptic error
    Evidence: .sisyphus/evidence/task-9-empty-command.txt

  Scenario: Full regression — all previous QA scenarios pass
    Tool: Bash
    Preconditions: tmux installed, all features implemented
    Steps:
      1. Run `tmux kill-server 2>/dev/null`
      2. Test basic grid: `./st --detach 4 "echo hello" && tmux has-session -t st-echo-4 && tmux list-panes -t st-echo-4 | wc -l | grep -q 4 && echo "grid: PASS" || echo "grid: FAIL"`
      3. Test --fresh: `./st --detach --fresh 4 "echo fresh" && echo "fresh: PASS" || echo "fresh: FAIL"`
      4. Test --name: `./st --detach --name regtest 2 "echo named" && tmux has-session -t st-regtest && echo "name: PASS" || echo "name: FAIL"`
      5. Test list: `./st list | grep -q "st-" && echo "list: PASS" || echo "list: FAIL"`
      6. Test kill: `./st kill st-regtest && ! tmux has-session -t st-regtest 2>/dev/null && echo "kill: PASS" || echo "kill: FAIL"`
      7. Test layout: `./st --detach --layout main-vertical 4 "echo layout" && echo "layout: PASS" || echo "layout: FAIL"`
      8. Test help: `./st --help | grep -q "Usage" && echo "help: PASS" || echo "help: FAIL"`
      9. Run `tmux kill-server 2>/dev/null`
    Expected Result: All tests pass
    Failure Indicators: Any FAIL output
    Evidence: .sisyphus/evidence/task-9-regression.txt
  ```

  **Evidence to Capture:**
  - [ ] task-9-shellcheck.txt — shellcheck results
  - [ ] task-9-command-spaces.txt — command with spaces/quotes
  - [ ] task-9-command-pipes.txt — command with pipes
  - [ ] task-9-empty-command.txt — empty command behavior
  - [ ] task-9-regression.txt — full regression results

  **Commit**: YES
  - Message: `fix: harden edge cases and achieve shellcheck compliance`
  - Files: `st`, `install.sh`
  - Pre-commit: `shellcheck st && shellcheck install.sh && bash -n st`

- [ ] 10. Professional README with Full Documentation

  **What to do**:
  - Replace the README stub with a comprehensive, professional README
  - Structure (follow popular OSS patterns):
    ```
    # 🖥️ SpawnTerminal (`st`)
    
    > One command to spawn terminal grid layouts. Built with tmux.
    
    [badges: License, Shell, tmux, GitHub stars placeholder]
    
    ## ✨ Features
    - Grid layouts with any number of panes
    - YAML presets for saved configurations
    - Session management (list, kill)
    - Multiple layout options (tiled, main-vertical, etc.)
    - Smart session reattach
    - Zero dependencies (just Bash + tmux)
    
    ## 📸 Demo
    [Placeholder for terminal recording / GIF]
    [Show: `st 4 opencode` creating a 2x2 grid]
    
    ## 🚀 Quick Start
    ```bash
    # Install
    git clone https://github.com/vaskoyudha/SpawnTerminal.git
    cd SpawnTerminal
    ./install.sh
    
    # Spawn a 2x2 grid running opencode
    st 4 opencode
    
    # Spawn 6 panes of htop
    st 6 htop
    ```
    
    ## 📖 Usage
    [Full usage documentation with all flags and subcommands]
    
    ## ⚙️ Configuration
    [YAML preset documentation with examples]
    
    ## 🔧 Installation
    [Detailed install instructions including prerequisites]
    
    ## 🤝 Contributing
    [Brief contribution guidelines]
    
    ## 📄 License
    MIT
    ```
  - Key sections to include:
    - **Features list**: All capabilities in bullet points
    - **Quick start**: 3 commands to get going
    - **Usage**: Complete CLI reference with ALL flags, subcommands, examples
    - **Preset configuration**: YAML format documentation with field reference
    - **Layouts**: Visual description of each layout option (tiled, main-vertical, etc.)
    - **Installation**: Prerequisites (tmux), clone + install.sh, manual install alternative
    - **Uninstallation**: `./install.sh --uninstall`
    - **Examples**: 5-6 real-world usage examples
    - **FAQ/Troubleshooting**: Nested tmux, pane limits, tmux not installed
  - Write in clear, concise English
  - Add GitHub repository description metadata where applicable
  - Include terminal-friendly formatting (proper code blocks, tables where useful)

  **Must NOT do**:
  - Do NOT use excessive emojis (keep it professional, 1 emoji per section header max)
  - Do NOT include auto-generated API docs or code documentation
  - Do NOT include a CHANGELOG (not needed for v1)
  - Do NOT include CI/CD badges (no CI configured)
  - Do NOT write marketing fluff — keep it technical and useful
  - Do NOT include screenshots that don't exist (use text placeholders for GIF/demo)

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation writing task — needs clear technical writing, good structure, professional OSS formatting
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None applicable

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 9)
  - **Parallel Group**: Wave 8 (with Task 9)
  - **Blocks**: Final verification
  - **Blocked By**: Task 7

  **References**:

  **Pattern References**:
  - `st` script — read `usage()` function output for accurate flag documentation
  - `examples/dev.yaml` — reference for preset documentation
  - `examples/monitor.yaml` — reference for preset documentation
  - `install.sh` — reference for installation documentation

  **External References**:
  - Popular Bash CLIs with good READMEs (for style reference):
    - https://github.com/tmuxinator/tmuxinator (similar tool, good README structure)
    - https://github.com/junegunn/fzf (excellent CLI README)
  - GitHub README best practices: badges, quick start, usage, examples

  **WHY Each Reference Matters**:
  - `usage()` output MUST match README documentation exactly (single source of truth)
  - Example presets should be documented with their exact YAML content
  - tmuxinator/fzf READMEs show the professional standard to match

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: README exists and has substantial content
    Tool: Bash
    Preconditions: README.md exists
    Steps:
      1. Run `test -f README.md && echo PASS || echo FAIL`
      2. Run `wc -l < README.md` → expect > 100 lines
      3. Run `wc -w < README.md` → expect > 500 words
    Expected Result: README has substantial content (>100 lines, >500 words)
    Failure Indicators: File missing or too short
    Evidence: .sisyphus/evidence/task-10-readme-size.txt

  Scenario: README has all required sections
    Tool: Bash
    Preconditions: README.md exists
    Steps:
      1. Run `grep -qi "features" README.md && echo "features: PASS" || echo "features: FAIL"`
      2. Run `grep -qi "quick start" README.md && echo "quickstart: PASS" || echo "quickstart: FAIL"`
      3. Run `grep -qi "usage" README.md && echo "usage: PASS" || echo "usage: FAIL"`
      4. Run `grep -qi "installation" README.md && echo "install: PASS" || echo "install: FAIL"`
      5. Run `grep -qi "configuration" README.md && echo "config: PASS" || echo "config: FAIL"`
      6. Run `grep -qi "license" README.md && echo "license: PASS" || echo "license: FAIL"`
      7. Run `grep -qi "preset" README.md && echo "preset: PASS" || echo "preset: FAIL"`
    Expected Result: All sections present
    Failure Indicators: Any section missing
    Evidence: .sisyphus/evidence/task-10-readme-sections.txt

  Scenario: README documents all flags
    Tool: Bash
    Preconditions: README.md exists
    Steps:
      1. Run `grep -q "\-\-fresh" README.md && echo "fresh: PASS" || echo "fresh: FAIL"`
      2. Run `grep -q "\-\-detach" README.md && echo "detach: PASS" || echo "detach: FAIL"`
      3. Run `grep -q "\-\-name" README.md && echo "name: PASS" || echo "name: FAIL"`
      4. Run `grep -q "\-\-layout" README.md && echo "layout: PASS" || echo "layout: FAIL"`
      5. Run `grep -q "\-\-preset" README.md && echo "preset: PASS" || echo "preset: FAIL"`
      6. Run `grep -q "\-\-force" README.md && echo "force: PASS" || echo "force: FAIL"`
    Expected Result: All flags documented
    Failure Indicators: Any flag missing from docs
    Evidence: .sisyphus/evidence/task-10-readme-flags.txt

  Scenario: README has code examples
    Tool: Bash
    Preconditions: README.md exists
    Steps:
      1. Run `grep -c '```' README.md` → expect at least 6 (3 code blocks minimum)
      2. Run `grep -q "st 4" README.md && echo "example: PASS" || echo "example: FAIL"`
    Expected Result: Multiple code examples with realistic usage
    Failure Indicators: No code blocks or examples
    Evidence: .sisyphus/evidence/task-10-readme-examples.txt
  ```

  **Evidence to Capture:**
  - [ ] task-10-readme-size.txt — size verification
  - [ ] task-10-readme-sections.txt — section completeness
  - [ ] task-10-readme-flags.txt — flag documentation
  - [ ] task-10-readme-examples.txt — code examples

  **Commit**: YES
  - Message: `docs: add comprehensive README with usage examples and badges`
  - Files: `README.md`
  - Pre-commit: `test -f README.md && test "$(wc -l < README.md)" -gt 100`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `bash -n st` + `shellcheck st`. Review all files for: hardcoded paths instead of XDG vars, missing error handling, missing `set -euo pipefail`, empty catch blocks, commented-out code, unused functions. Check AI slop: excessive comments, over-abstraction, generic variable names.
  Output: `Syntax [PASS/FAIL] | ShellCheck [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state (`tmux kill-server 2>/dev/null`). Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration (presets + session management together). Test edge cases: 0 panes, 1 pane, 17 panes, empty command, nested tmux. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git log --oneline`). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Detect unaccounted changes.
  Output: `Tasks [N/N compliant] | Scope [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

Each task creates exactly one commit, pushed immediately to remote.

| Task | Commit Message | Files | Pre-commit Check |
|------|---------------|-------|-----------------|
| T1 | `feat: initialize project structure` | .gitignore, LICENSE, README.md, examples/ | Files exist |
| T2 | `feat: add core st script with grid creation` | st | `bash -n st` |
| T3 | `feat: add session reattach, --fresh and --name flags` | st | `bash -n st` |
| T4 | `feat: add error handling, tmux detection, input validation` | st | `bash -n st` |
| T5 | `feat: add --detach mode and session management subcommands` | st | `bash -n st` |
| T6 | `feat: add --layout flag with tmux preset layouts` | st | `bash -n st` |
| T7 | `feat: add YAML preset support with example configs` | st, examples/*.yaml | `bash -n st` |
| T8 | `feat: add install.sh script` | install.sh | `bash -n install.sh` |
| T9 | `fix: harden edge cases and pass shellcheck` | st | `shellcheck st && bash -n st` |
| T10 | `docs: add professional README with full documentation` | README.md | `test -f README.md` |

**Git Setup (Task 1)**:
```bash
git init
git remote add origin https://github.com/vaskoyudha/SpawnTerminal.git
git branch -M main
# First commit + push in T1
```

---

## Success Criteria

### Verification Commands
```bash
# Core functionality
st --detach 4 "echo hello" && tmux has-session -t st-echo-4 && echo PASS
tmux list-panes -t st-echo-4 | wc -l  # Expected: 4

# Session management
st list | grep -q "st-echo-4" && echo PASS
st kill st-echo-4 && ! tmux has-session -t st-echo-4 2>/dev/null && echo PASS

# YAML preset
st --detach --preset dev && tmux has-session -t st-dev && echo PASS

# Help
st --help | grep -q "Usage" && echo PASS

# Code quality
bash -n st && echo PASS
shellcheck st && echo PASS
```

### Final Checklist
- [ ] All "Must Have" features present and working
- [ ] All "Must NOT Have" absent from codebase
- [ ] `bash -n st` passes
- [ ] `shellcheck st` passes (no errors/warnings)
- [ ] All 10 commits pushed to GitHub remote
- [ ] README renders professionally on GitHub
- [ ] `./install.sh` works and `st` is available in PATH
- [ ] All QA evidence files present in `.sisyphus/evidence/`
