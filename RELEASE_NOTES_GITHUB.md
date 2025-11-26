# 🎉 Rz Clipboard v1.0.0 - Initial Release

A lightweight macOS menu bar utility that keeps your clipboard history just a click away. Never lose important snippets again!

## ✨ Key Features

### 📋 Text Clipboard
- Live clipboard monitoring with configurable polling
- Pin important snippets to keep them forever
- One-click copy with visual feedback
- Smart duplicate prevention
- Time tracking with relative timestamps
- Individual deletion and clear all recent

### 🖼️ Image Support
- Capture images from clipboard (optional)
- 3-column grid thumbnail view
- Pin/unpin images for persistence
- Hover actions for quick access
- Supports TIFF and PNG formats

### ⚙️ Settings
- Configurable history limit (10-100)
- Adjustable poll interval (0.3-2.0s)
- Duplicate prevention toggle
- Image saving toggle
- Auto-start on login
- Reset to defaults

### 🔒 Reliability
- Atomic file writes prevent corruption
- Single instance enforcement
- Automatic data migration
- Persistent storage for pinned items

## 📦 Installation

1. Download `Rz Clipboard-v1.0.0.dmg`
2. Open the DMG and drag the app to Applications
3. Launch from Applications or Spotlight

## 📊 Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.4 (Swift 6) for building from source

## 🗑️ Uninstall

Run `./uninstall.sh` or manually remove:
- App bundle
- `~/Library/Application Support/rzclipboard`
- `~/Library/Preferences/com.robin.rzclipboard.plist`
- `~/Library/LaunchAgents/com.robin.rzclipboard.plist`

---

**Note:** Menu bar apps don't appear in the dock but will show in the menu bar.

