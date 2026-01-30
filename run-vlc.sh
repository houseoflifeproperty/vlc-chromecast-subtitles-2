#!/bin/bash
# run-vlc.sh - Run VLC from build directory with proper environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VLC_BUILD="$SCRIPT_DIR"

# Set library paths
export DYLD_LIBRARY_PATH="$VLC_BUILD/lib/.libs:$VLC_BUILD/src/.libs:$DYLD_LIBRARY_PATH"
export VLC_PLUGIN_PATH="$VLC_BUILD/modules/.libs"

# Run VLC
if [ -x "$VLC_BUILD/bin/vlc-osx-static" ]; then
    exec "$VLC_BUILD/bin/vlc-osx-static" "$@"
elif [ -x "$VLC_BUILD/bin/.libs/vlc" ]; then
    exec "$VLC_BUILD/bin/.libs/vlc" "$@"
else
    echo "VLC executable not found. Have you run 'make'?"
    exit 1
fi
