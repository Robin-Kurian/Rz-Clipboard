#!/bin/bash

# Uninstall script for R-ClipHistory
# Removes the app and all associated data

set -e

APP_NAME="R-ClipHistory"
BUNDLE_ID="com.robin.rcliphistory"

echo "🗑️  Uninstalling $APP_NAME..."

# Kill running instances
echo "🛑 Stopping running instances..."
pkill -f "$APP_NAME" 2>/dev/null || true
sleep 1

# Find and remove app bundle
echo "📱 Removing app bundle..."
APP_LOCATIONS=(
    "/Applications/$APP_NAME.app"
    "$HOME/Applications/$APP_NAME.app"
    "$HOME/Desktop/$APP_NAME.app"
    "$HOME/Downloads/$APP_NAME.app"
)

FOUND=false
for location in "${APP_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        echo "   Found at: $location"
        rm -rf "$location"
        FOUND=true
    fi
done

if [ "$FOUND" = false ]; then
    echo "   ⚠️  App bundle not found in standard locations"
    echo "   Searching system..."
    FOUND_APPS=$(mdfind "kMDItemCFBundleIdentifier == '$BUNDLE_ID'" 2>/dev/null || true)
    if [ -n "$FOUND_APPS" ]; then
        echo "$FOUND_APPS" | while read -r app_path; do
            if [ -d "$app_path" ]; then
                echo "   Found at: $app_path"
                rm -rf "$app_path"
            fi
        done
    else
        echo "   ℹ️  App bundle not found (may already be removed)"
    fi
fi

# Remove application support data
echo "📂 Removing application data..."
APP_SUPPORT="$HOME/Library/Application Support/$APP_NAME"
if [ -d "$APP_SUPPORT" ]; then
    echo "   Removing: $APP_SUPPORT"
    rm -rf "$APP_SUPPORT"
else
    echo "   ℹ️  No application data found"
fi

# Remove preferences
echo "⚙️  Removing preferences..."
PREFERENCES="$HOME/Library/Preferences/$BUNDLE_ID.plist"
if [ -f "$PREFERENCES" ]; then
    echo "   Removing: $PREFERENCES"
    rm -f "$PREFERENCES"
else
    echo "   ℹ️  No preferences found"
fi

# Remove any launch agents (if any)
echo "🚀 Checking for launch agents..."
LAUNCH_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
if [ -f "$LAUNCH_AGENT" ]; then
    echo "   Removing launch agent: $LAUNCH_AGENT"
    launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
    rm -f "$LAUNCH_AGENT"
else
    echo "   ℹ️  No launch agents found"
fi

# Clear caches
echo "🧹 Clearing caches..."
CACHE_DIR="$HOME/Library/Caches/$BUNDLE_ID"
if [ -d "$CACHE_DIR" ]; then
    echo "   Removing: $CACHE_DIR"
    rm -rf "$CACHE_DIR"
fi

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "Removed:"
echo "  • App bundle"
echo "  • Application data (~/Library/Application Support/$APP_NAME)"
echo "  • Preferences"
echo "  • Caches"
echo ""
echo "Note: If the app is still in your menu bar, log out and log back in, or restart your Mac."

