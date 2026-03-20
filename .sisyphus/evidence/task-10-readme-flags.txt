| `--detach` | `-d` | Create session without attaching |
| `--fresh` | `-f` | Kill existing session and create a fresh one |
| `--force` | `-F` | Allow creating more than 16 panes (up to 50) |
| `--name <name>` | `-n` | Set a custom session name (prefixed with `st-`) |
| `--layout <layout>` | `-l` | Pane layout (default: `tiled`) |
| `--preset <name>` | `-p` | Load preset from config directory |
st --preset dev
st --preset dev 8 "echo hi"
st --name backend 3 "npm run dev"
st --preset dev
st --force 20 "tail -f /var/log/syslog"
- **Pane limit**: By default, `st` limits you to 16 panes to prevent overcrowding. Use the `--force` flag to go up to the hard limit of 50 panes.
- **Session already exists**: If you run a command that matches an existing session name, `st` will reattach to it. Use the `--fresh` flag if you want to kill the old session and start a new one.
