#!/usr/bin/env bash
set -e

echo "Running bash integration test..."

# Setup clean environment
export HOME=$(mktemp -d)
export TERMIM_BIN="${TERMIM_BIN:-termim}"

# Source the hook
source shell/bash.sh

# Override the binary path so it uses our compiled debug binary
_TERMIM_BIN="$TERMIM_BIN"
_TERMIM_HOME="$HOME/.termim"
_TERMIM_LOG="$_TERMIM_HOME/termim.log"
mkdir -p "$_TERMIM_HOME"

echo "Log command 1..."
export PWD="$HOME"
BASH_COMMAND="echo hello_world"
_termim_preexec

# Add to Bash global history so that global fallback can fetch it
history -s "echo hello_world"

# Simulate execution log
_termim_log

# wait a moment for the background process to log
sleep 0.5

echo "Test UP Arrow..."
# Simulate Up arrow
READLINE_LINE=""
_termim_up

if [[ "$READLINE_LINE" != "echo hello_world" ]]; then
    echo "FAIL: Expected READLINE_LINE to be 'echo hello_world', got '$READLINE_LINE'"
    exit 1
fi

echo "Log complex command..."
BASH_COMMAND="grep -r \"test\" | awk '{print \$1}' > out.txt && echo 'done'"
_termim_preexec
history -s "$BASH_COMMAND"
_termim_log
sleep 0.5

READLINE_LINE=""
_termim_up
if [[ "$READLINE_LINE" != "$BASH_COMMAND" ]]; then
    echo "FAIL: Expected READLINE_LINE to be '$BASH_COMMAND', got '$READLINE_LINE'"
    exit 1
fi

echo "Test Global Fallback..."
history -s "global_echo"
# Simulate pressing up again (exceeding directory history)
_termim_up

if [[ "$READLINE_LINE" != "global_echo" ]]; then
    echo "FAIL: Expected fallback to 'global_echo', got '$READLINE_LINE'"
    exit 1
fi

echo "PASS: Bash integration successful."
