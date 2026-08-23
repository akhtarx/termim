#!/usr/bin/env zsh
set -e

echo "Running zsh integration test..."

export HOME=$(mktemp -d)
export USERPROFILE="$HOME"
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=1000
export SAVEHIST=1000
setopt inc_append_history
_TERMIM_HOME="$HOME/.termim"
_TERMIM_LOG="$_TERMIM_HOME/termim.log"
mkdir -p "$_TERMIM_HOME"

echo "INITIAL TERMIM_BIN is '$TERMIM_BIN'" >> "$_TERMIM_LOG"
export TERMIM_BIN="${TERMIM_BIN:-termim}"
echo "AFTER FALLBACK TERMIM_BIN is '$TERMIM_BIN'" >> "$_TERMIM_LOG"
_TERMIM_BIN="$TERMIM_BIN"

# Source the hook
source shell/zsh.sh

echo "Log command 1..."
export PWD="$HOME"

# Mock pre-exec
_TERMIM_PREEXEC_DIR="$PWD"
"$_TERMIM_BIN" log "echo zsh_world" --cwd "$_TERMIM_PREEXEC_DIR" --pre-exec >> "$_TERMIM_LOG" 2>&1

# Mock post-exec
_TERMIM_ORIGINAL_INPUT="echo zsh_world"
"$_TERMIM_BIN" log "$_TERMIM_ORIGINAL_INPUT" --prev "none" --exit 0 --cwd "$PWD" --post-exec >> "$_TERMIM_LOG" 2>&1

echo "Test UP Arrow..."

# We must mock history because non-interactive shells have no history.
_TERMIM_CACHE=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && _TERMIM_CACHE+=("$line")
done < <("$_TERMIM_BIN" query --history-only --prev "" --cwd "$PWD" 2>/dev/null)

BUFFER="${_TERMIM_CACHE[1]}"

if [[ "$BUFFER" != "echo zsh_world" ]]; then
    echo "FAIL: Expected BUFFER to be 'echo zsh_world', got '$BUFFER'"
    echo "--- termim.log ---"
    cat "$_TERMIM_LOG"
    exit 1
fi

echo "PASS: Zsh integration successful."
