#!/usr/bin/env zsh
# Note: do NOT use set -e here; sourcing zsh.sh in a non-interactive shell
# causes add-zsh-hook to fail (it requires interactive mode), which would
# abort the test prematurely.

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

# Source the hook (may produce non-fatal errors in non-interactive zsh)
source shell/zsh.sh 2>>"$_TERMIM_LOG" || true

# Re-assert _TERMIM_BIN after sourcing: in non-interactive zsh, ZLE/add-zsh-hook
# failures during source can prevent the assignment from sticking.
_TERMIM_BIN="$TERMIM_BIN"
echo "DEBUG: _TERMIM_BIN='$_TERMIM_BIN'" >> "$_TERMIM_LOG"

echo "Log command 1..."

# NOTE: In zsh, PWD is a special shell-managed variable and cannot be overridden
# with `export PWD=...`. Use _TEST_CWD for a consistent directory across log+query.
_TEST_CWD="$HOME"

# Mock pre-exec
_TERMIM_PREEXEC_DIR="$_TEST_CWD"
"$_TERMIM_BIN" log "echo zsh_world" --cwd "$_TERMIM_PREEXEC_DIR" --pre-exec >> "$_TERMIM_LOG" 2>&1

# Mock post-exec
_TERMIM_ORIGINAL_INPUT="echo zsh_world"
"$_TERMIM_BIN" log "$_TERMIM_ORIGINAL_INPUT" --prev "none" --exit 0 --cwd "$_TEST_CWD" --post-exec >> "$_TERMIM_LOG" 2>&1

echo "Test UP Arrow..."

# We must mock history because non-interactive shells have no history.
_TERMIM_CACHE=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && _TERMIM_CACHE+=("$line")
done < <("$_TERMIM_BIN" query --history-only --prev "" --cwd "$_TEST_CWD" 2>/dev/null)

BUFFER="${_TERMIM_CACHE[1]}"

if [[ "$BUFFER" != "echo zsh_world" ]]; then
    echo "FAIL: Expected BUFFER to be 'echo zsh_world', got '$BUFFER'"
    echo "--- termim.log ---"
    cat "$_TERMIM_LOG"
    exit 1
fi

echo "PASS: Zsh integration successful."

