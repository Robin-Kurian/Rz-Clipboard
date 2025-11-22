#!/bin/bash

# Build script for R-ClipHistory - creates app bundle and DMG
# Usage: ./build-release.sh

set -e  # Exit on error

APP_NAME="R-ClipHistory"
BUNDLE_ID="com.robin.rcliphistory"
VERSION="1.0.0"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-v$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "🚀 Building $APP_NAME..."

# Clean previous build
echo "📦 Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build release binary
echo "🔨 Building release binary..."
swift build -c release

# Get the binary path
BINARY_PATH=".build/release/$APP_NAME"

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: Binary not found at $BINARY_PATH"
    exit 1
fi

# Create app bundle structure
echo "📱 Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
echo "📋 Copying binary..."
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Make binary executable
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Create DMG
echo "💿 Creating DMG..."
DMG_TEMP_DIR="$BUILD_DIR/dmg-temp"
mkdir -p "$DMG_TEMP_DIR"

# Copy app to temp directory
cp -R "$APP_BUNDLE" "$DMG_TEMP_DIR/"

# Create DMG using hdiutil
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP_DIR" -ov -format UDZO "$DMG_PATH"

# Clean up temp directory
rm -rf "$DMG_TEMP_DIR"

echo ""
echo "✅ Build complete!"
echo "📦 App bundle: $APP_BUNDLE"
echo "💿 DMG file: $DMG_PATH"
echo ""
echo "To install:"
echo "  1. Open $DMG_PATH"
echo "  2. Drag $APP_NAME.app to Applications folder"
echo ""

