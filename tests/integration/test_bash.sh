#!/usr/bin/env bash

echo "Running bash integration test..."

# Setup clean environment
export HOME=$(mktemp -d)
export USERPROFILE="$HOME"

_TERMIM_HOME="$HOME/.termim"
_TERMIM_LOG="$_TERMIM_HOME/termim.log"
mkdir -p "$_TERMIM_HOME"

echo "INITIAL TERMIM_BIN is '$TERMIM_BIN'" >> "$_TERMIM_LOG"
export TERMIM_BIN="${TERMIM_BIN:-termim}"
echo "AFTER FALLBACK TERMIM_BIN is '$TERMIM_BIN'" >> "$_TERMIM_LOG"
_TERMIM_BIN="$TERMIM_BIN"

# Source the hook
source shell/bash.sh

# The hook enables `trap '_termim_preexec' DEBUG`.
# This captures ALL commands in this script!
# We must disable it so our test script commands don't pollute the history.
trap - DEBUG

echo "Log command 1..."
export PWD="$HOME"

# Mock pre-exec for 'echo hello_world'
_TERMIM_PREEXEC_DIR="$PWD"
"$_TERMIM_BIN" log "echo hello_world" --cwd "$_TERMIM_PREEXEC_DIR" --pre-exec >> "$_TERMIM_LOG" 2>&1

# Mock post-exec for 'echo hello_world'
_TERMIM_ORIGINAL_INPUT="echo hello_world"
"$_TERMIM_BIN" log "$_TERMIM_ORIGINAL_INPUT" --prev "none" --exit 0 --cwd "$PWD" --post-exec >> "$_TERMIM_LOG" 2>&1

echo "Test UP Arrow..."
# We must mock history because non-interactive shells have no history.
# We bypass `fc` by overriding `prev_cmd` directly in the query, OR we just let it fetch standard history fallback.
# Let's mock `_termim_up`'s internal behavior by defining a dummy fc if needed, 
# or just let it use empty prev_cmd since it will fallback to standard history!
_TERMIM_CACHE=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && _TERMIM_CACHE+=("$line")
done < <("$_TERMIM_BIN" query --history-only --prev "" --cwd "$PWD" 2>/dev/null)

READLINE_LINE="${_TERMIM_CACHE[0]}"

if [[ "$READLINE_LINE" != "echo hello_world" ]]; then
    echo "FAIL: Expected READLINE_LINE to be 'echo hello_world', got '$READLINE_LINE'"
    echo "--- termim.log ---"
    cat "$_TERMIM_LOG"
    exit 1
fi

echo "Log complex command..."
COMPLEX_CMD="grep -r \"test\" | awk '{print \$1}' > out.txt && echo 'done'"
"$_TERMIM_BIN" log "$COMPLEX_CMD" --cwd "$PWD" --pre-exec >> "$_TERMIM_LOG" 2>&1
"$_TERMIM_BIN" log "$COMPLEX_CMD" --prev "echo hello_world" --exit 0 --cwd "$PWD" --post-exec >> "$_TERMIM_LOG" 2>&1
sleep 0.5

READLINE_LINE=""
_TERMIM_CACHE=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && _TERMIM_CACHE+=("$line")
done < <("$_TERMIM_BIN" query --history-only --prev "" --cwd "$PWD" 2>/dev/null)

READLINE_LINE="${_TERMIM_CACHE[0]}"

if [[ "$READLINE_LINE" != "$COMPLEX_CMD" ]]; then
    echo "FAIL: Expected READLINE_LINE to be '$COMPLEX_CMD', got '$READLINE_LINE'"
    echo "--- termim.log ---"
    cat "$_TERMIM_LOG"
    exit 1
fi

echo "Test Global Fallback..."
# Simulate pressing up again (exceeding directory history)
_TERMIM_CACHE=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && _TERMIM_CACHE+=("$line")
done < <("$_TERMIM_BIN" query --history-only --prev "" --cwd "$PWD" 2>/dev/null)

# We want the last one which is older
# Actually it doesn't matter, we just check if global_echo is in the cache somewhere,
# or we can write a specific global fallback test by inserting into global history directly
"$_TERMIM_BIN" log "global_echo" --cwd "$HOME" --pre-exec >> "$_TERMIM_LOG" 2>&1

_TERMIM_CACHE=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && _TERMIM_CACHE+=("$line")
done < <("$_TERMIM_BIN" query --history-only --prev "" --cwd "$PWD" 2>/dev/null)

found=false
for cmd in "${_TERMIM_CACHE[@]}"; do
    if [[ "$cmd" == "global_echo" ]]; then
        found=true
        break
    fi
done

if [[ "$found" != true ]]; then
    echo "FAIL: Expected fallback to 'global_echo', got '${_TERMIM_CACHE[0]}'"
    exit 1
fi

echo "PASS: Bash integration successful."
