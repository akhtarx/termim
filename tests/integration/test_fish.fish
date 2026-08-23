#!/usr/bin/env fish

echo "Running fish integration test..."

set -x HOME (mktemp -d)
if not set -q TERMIM_BIN
    set -x TERMIM_BIN "termim"
end

# Source the hook
source shell/fish.fish

set -g _TERMIM_BIN "$TERMIM_BIN"
set -g _TERMIM_HOME "$HOME/.termim"
set -g _TERMIM_LOG "$_TERMIM_HOME/termim.log"
mkdir -p "$_TERMIM_HOME"

echo "Log command 1..."
set -x PWD "$HOME"

# Mock pre-exec
set -g _TERMIM_PREEXEC_DIR "$PWD"
eval "$_TERMIM_BIN log 'echo fish_world' --cwd '$_TERMIM_PREEXEC_DIR' --pre-exec 2>>'$_TERMIM_LOG'"

# Mock post-exec
eval "$_TERMIM_BIN log 'echo fish_world' --prev 'none' --exit 0 --cwd '$_TERMIM_PREEXEC_DIR' --post-exec 2>>'$_TERMIM_LOG'"

echo "Test UP Arrow..."
# Simulate Up arrow by calling the function directly
_termim_up

set current_cmd (commandline)
if test "$current_cmd" != "echo fish_world"
    echo "FAIL: Expected commandline to be 'echo fish_world', got '$current_cmd'"
    exit 1
end

echo "PASS: Fish integration successful."
