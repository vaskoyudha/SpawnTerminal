# SpawnTerminal (`st`)
> Spawn tmux grid layouts from a single command.

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)

SpawnTerminal (`st`) is a lightweight Bash utility that automates the creation of complex tmux grid layouts. Whether you need to monitor multiple services, run several instances of a development tool, or set up a multi-pane environment, `st` handles the tmux session management and window splitting with a single command.

## Features

- Grid layouts with any number of panes (up to 50)
- YAML preset configurations stored in `${XDG_CONFIG_HOME:-~/.config}/st/`
- 5 tmux layout options: tiled, even-horizontal, even-vertical, main-horizontal, main-vertical
- Session management: list, kill, and smart reattach
- Smart session reattach: re-running the same command reattaches to the existing session
- Custom session names for better organization
- Detach mode: create sessions without immediately attaching
- Zero dependencies beyond Bash and tmux

## Demo
[Demo GIF/screenshot placeholder]

## Quick Start

```bash
git clone https://github.com/vaskoyudha/SpawnTerminal.git
cd SpawnTerminal && ./install.sh
st 4 opencode
```

## Installation

### Prerequisites

- **Bash**: Most Linux distributions come with Bash installed by default.
- **tmux**: The terminal multiplexer. Install it via your package manager:
  ```bash
  # Debian/Ubuntu
  sudo apt install tmux

  # Fedora
  sudo dnf install tmux

  # Arch Linux
  sudo pacman -S tmux
  ```

### Install

Run the included installation script to create a symlink in your `~/.local/bin` directory:

```bash
./install.sh
```

Ensure `~/.local/bin` is in your `PATH`. If not, add it to your shell configuration:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Basic Usage

The simplest way to use `st` is to specify the number of panes and the command to run in each:

```bash
st <panes> <command> [options]
```

Example: `st 4 opencode` creates a 2x2 grid where each pane runs `opencode`.

### Flags / Options

| Flag | Short | Description |
|------|-------|-------------|
| `--help` | `-h` | Show help message |
| `--detach` | `-d` | Create session without attaching |
| `--fresh` | `-f` | Kill existing session and create a fresh one |
| `--force` | `-F` | Allow creating more than 16 panes (up to 50) |
| `--name <name>` | `-n` | Set a custom session name (prefixed with `st-`) |
| `--layout <layout>` | `-l` | Pane layout (default: `tiled`) |
| `--preset <name>` | `-p` | Load preset from config directory |

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `st list` | List all active `st` sessions |
| `st kill <session>` | Kill a specific `st` session |
| `st kill --all` | Kill all `st` sessions |
| `st init` | Create config directory and copy example presets |
| `st help` | Show help message |

### Preset Configuration

Presets allow you to define complex environments in YAML files. They are stored in `${XDG_CONFIG_HOME:-~/.config}/st/`.

To load a preset:
```bash
st --preset dev
```

You can also override preset values with inline arguments:
```bash
st --preset dev 8 "echo hi"
```

### Layout Options

`st` supports standard tmux layouts:

| Layout | Description |
|--------|-------------|
| `tiled` | Equal-size grid (default) |
| `even-horizontal` | Panes stacked side by side |
| `even-vertical` | Panes stacked top to bottom |
| `main-horizontal` | One large pane on top, rest below |
| `main-vertical` | One large pane on left, rest on right |

## Configuration

### YAML Preset Format

The preset file is a simple flat YAML:

```yaml
name: dev         # Session name (st- prefix added automatically)
panes: 4          # Number of panes
command: opencode  # Command to run in each pane
layout: tiled     # Layout (optional, default: tiled)
directory: ~/projects/myapp  # Working directory (optional, default: CWD)
```

### Example Presets

Run `st init` to copy the following examples to your config directory:

**dev.yaml**:
```yaml
name: dev
panes: 4
command: opencode
layout: tiled
```

**monitor.yaml**:
```yaml
name: monitor
panes: 6
command: htop
layout: even-horizontal
```

## Examples

```bash
# Start 4 opencode instances in a 2x2 grid
st 4 opencode

# Monitor 6 services side by side
st 6 htop

# Named development session
st --name backend 3 "npm run dev"

# Use a saved preset
st --preset dev

# Force 20 panes for log monitoring
st --force 20 "tail -f /var/log/syslog"
```

## Troubleshooting / FAQ

- **"tmux: command not found"**: Ensure `tmux` is installed on your system using your package manager.
- **Nested tmux warning**: If you run `st` from within an existing tmux session, it will warn you that you're creating a nested session. This is normal behavior but can sometimes lead to keybinding conflicts.
- **Pane limit**: By default, `st` limits you to 16 panes to prevent overcrowding. Use the `--force` flag to go up to the hard limit of 50 panes.
- **Session already exists**: If you run a command that matches an existing session name, `st` will reattach to it. Use the `--fresh` flag if you want to kill the old session and start a new one.
- **Terminal too small**: If your terminal window is too small to accommodate the requested number of panes, `st` will fail with an error. Try maximizing your window or reducing the pane count.

## Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue on GitHub. Pull requests are also appreciated, and there is no CLA required for small contributions.

## License

Distributed under the MIT License. See `LICENSE` for more information.

