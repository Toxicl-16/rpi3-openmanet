#!/bin/sh
# Compatibility entry point used by OpenMANET build instructions.
exec "$(dirname "$0")/morse_setup.sh" "$@"
