#!/usr/bin/env zsh
set -e

echo "Running zsh integration test..."

export HOME=$(mktemp -d)
export TERMIM_BIN="${TERMIM_BIN:-termim}"

# Source the hook
source shell/zsh.sh

_TERMIM_BIN="$TERMIM_BIN"
_TERMIM_HOME="$HOME/.termim"
_TERMIM_LOG="$_TERMIM_HOME/termim.log"
mkdir -p "$_TERMIM_HOME"

echo "Log command 1..."
export PWD="$HOME"

# Mock pre-exec
_TERMIM_PREEXEC_DIR="$PWD"
"$_TERMIM_BIN" log "echo zsh_world" --cwd "$_TERMIM_PREEXEC_DIR" --pre-exec 2>>"$_TERMIM_LOG"

# Mock post-exec
"$_TERMIM_BIN" log "echo zsh_world" --prev "none" --exit 0 --cwd "$_TERMIM_PREEXEC_DIR" --post-exec 2>>"$_TERMIM_LOG"

echo "Test UP Arrow..."
BUFFER=""
_termim_up

if [[ "$BUFFER" != "echo zsh_world" ]]; then
    echo "FAIL: Expected BUFFER to be 'echo zsh_world', got '$BUFFER'"
    exit 1
fi

echo "PASS: Zsh integration successful."
