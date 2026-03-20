#!/usr/bin/env bash
set -euo pipefail

# Find the st script relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ST_SCRIPT="$SCRIPT_DIR/st"

# Check if st script exists and is executable
if [[ ! -f "$ST_SCRIPT" ]]; then
    echo "Error: st script not found at $ST_SCRIPT" >&2
    exit 1
fi

if [[ ! -x "$ST_SCRIPT" ]]; then
    echo "Error: st script is not executable at $ST_SCRIPT" >&2
    exit 1
fi

# Handle uninstall
if [[ "${1:-}" == "--uninstall" ]]; then
    if [[ -L "$HOME/.local/bin/st" ]]; then
        rm -f "$HOME/.local/bin/st"
        echo "st uninstalled from $HOME/.local/bin"
        exit 0
    elif [[ -L "/usr/local/bin/st" ]]; then
        rm -f "/usr/local/bin/st"
        echo "st uninstalled from /usr/local/bin"
        exit 0
    else
        echo "Warning: st is not installed" >&2
        exit 0
    fi
fi

# Determine install directory
install_dir=""

# Prefer ~/.local/bin
if [[ -d "$HOME/.local/bin" ]] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
    install_dir="$HOME/.local/bin"
elif [[ -w "/usr/local/bin" ]]; then
    install_dir="/usr/local/bin"
else
    echo "Error: Cannot determine install directory (no write access to ~/.local/bin or /usr/local/bin)" >&2
    exit 1
fi

# Install via symlink
ln -sf "$ST_SCRIPT" "$install_dir/st"

echo "st installed to $install_dir/st"

# Check if ~/.local/bin is in PATH
if [[ "$install_dir" == "$HOME/.local/bin" ]]; then
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo ""
        echo "Note: Add ~/.local/bin to your PATH:"
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
    fi
fi
