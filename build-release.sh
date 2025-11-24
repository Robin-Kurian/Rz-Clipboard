#!/bin/bash

# Build script for Rz Clipboard - creates app bundle and DMG
# Usage: ./build-release.sh

set -e  # Exit on error

APP_NAME="Rz Clipboard"
BUNDLE_ID="com.robin.rzclipboard"
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

# Get the binary path (executable name is rzclipboard, not the display name)
BINARY_PATH=".build/release/rzclipboard"

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: Binary not found at $BINARY_PATH"
    exit 1
fi

# Create app bundle structure
echo "📱 Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary (executable name is rzclipboard)
echo "📋 Copying binary..."
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/rzclipboard"

# Make binary executable
chmod +x "$APP_BUNDLE/Contents/MacOS/rzclipboard"

# Generate app icon from clipboard.png
echo "🎨 Generating app icon..."
ICON_NAME="Appicon"
ICON_ICNS="Assets/${ICON_NAME}.icns"
ICON_PNG="Assets/clipboard.png"

# Check if we need to generate the .icns file
if [ ! -f "$ICON_ICNS" ] || [ "$ICON_PNG" -nt "$ICON_ICNS" ]; then
    if [ -f "$ICON_PNG" ]; then
        echo "   Converting $ICON_PNG to .icns format..."
        ICONSET_DIR="Assets/${ICON_NAME}.iconset"
        
        # Clean up old iconset if it exists
        rm -rf "$ICONSET_DIR"
        mkdir -p "$ICONSET_DIR"
        
        # Generate all required icon sizes for macOS
        # Standard sizes
        sips -z 16 16     "$ICON_PNG" --out "${ICONSET_DIR}/icon_16x16.png" > /dev/null 2>&1
        sips -z 32 32     "$ICON_PNG" --out "${ICONSET_DIR}/icon_16x16@2x.png" > /dev/null 2>&1
        sips -z 32 32     "$ICON_PNG" --out "${ICONSET_DIR}/icon_32x32.png" > /dev/null 2>&1
        sips -z 64 64     "$ICON_PNG" --out "${ICONSET_DIR}/icon_32x32@2x.png" > /dev/null 2>&1
        sips -z 128 128   "$ICON_PNG" --out "${ICONSET_DIR}/icon_128x128.png" > /dev/null 2>&1
        sips -z 256 256   "$ICON_PNG" --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null 2>&1
        sips -z 256 256   "$ICON_PNG" --out "${ICONSET_DIR}/icon_256x256.png" > /dev/null 2>&1
        sips -z 512 512   "$ICON_PNG" --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null 2>&1
        sips -z 512 512   "$ICON_PNG" --out "${ICONSET_DIR}/icon_512x512.png" > /dev/null 2>&1
        sips -z 1024 1024 "$ICON_PNG" --out "${ICONSET_DIR}/icon_512x512@2x.png" > /dev/null 2>&1
        
        # Convert iconset to .icns
        iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS" 2>/dev/null
        
        # Clean up iconset directory
        rm -rf "$ICONSET_DIR"
        
        if [ -f "$ICON_ICNS" ]; then
            echo "   ✅ Icon generated successfully: $ICON_ICNS"
        else
            echo "   ⚠️  Warning: Failed to generate icon, app will use default icon"
        fi
    else
        echo "   ⚠️  Warning: $ICON_PNG not found, app will use default icon"
    fi
else
    echo "   Using existing icon: $ICON_ICNS"
fi

# Copy app icon to app bundle
if [ -f "$ICON_ICNS" ]; then
    echo "   Copying icon to app bundle..."
    cp "$ICON_ICNS" "$APP_BUNDLE/Contents/Resources/${ICON_NAME}.icns"
else
    echo "   ⚠️  Warning: App icon not found, app will use default icon"
fi

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
    <string>rzclipboard</string>
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
    <key>CFBundleIconFile</key>
    <string>Appicon</string>
</dict>
</plist>
EOF

# Refresh icon cache so macOS recognizes the icon immediately
echo "🔄 Refreshing icon cache..."
touch "$APP_BUNDLE"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE" 2>/dev/null || true

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

