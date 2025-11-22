#!/bin/bash

# Watch script for R-ClipHistory - auto-rebuilds and restarts on file changes
# Usage: ./watch.sh
# Note: Requires fswatch. Install with: brew install fswatch

echo "Watching for changes in R-ClipHistory..."
echo "Press Ctrl+C to stop"
echo ""
echo "To install fswatch: brew install fswatch"

# Check if fswatch is installed
if ! command -v fswatch &> /dev/null; then
    echo "Error: fswatch not found. Install with: brew install fswatch"
    exit 1
fi

# Kill any existing R-ClipHistory processes
pkill -f R-ClipHistory 2>/dev/null

# Initial build and run
cd "$(dirname "$0")"
swift build && swift run &
APP_PID=$!

# Watch for changes in Sources directory
fswatch -o Sources/ | while read f; do
    echo "Change detected, rebuilding..."
    # Kill the running app
    pkill -f R-ClipHistory 2>/dev/null
    wait $APP_PID 2>/dev/null
    
    # Rebuild and run
    swift build && swift run &
    APP_PID=$!
done

