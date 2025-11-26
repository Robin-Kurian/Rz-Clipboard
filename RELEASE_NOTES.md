# Release Notes - v1.0.0

## 🎉 Initial Release

Rz Clipboard is a lightweight macOS menu bar utility that keeps your clipboard history just a click away. Never lose important snippets again!

---

## ✨ Features

### 📋 Text Clipboard Management
- **Live clipboard monitoring** - Automatically captures text you copy (configurable polling interval, default 800ms)
- **Pinned entries** - Mark important snippets to keep them forever, immune to history limits
- **Persistent storage** - Pinned items survive app restarts and system reboots
- **Smart duplicate prevention** - Optionally skip identical clipboard content
- **One-click copy** - Tap any entry to instantly copy it back to clipboard
- **Visual feedback** - "Copied" confirmation when you tap an entry
- **Time tracking** - See when each item was copied with relative timestamps (Today, Yesterday, weekday names)
- **Individual deletion** - Remove specific recent entries with a delete button
- **Clear all recent** - Quick button to clear all transient entries (pinned items remain safe)
- **Text truncation** - Long entries are neatly truncated to 3 lines for clean display
- **Hover effects** - Visual highlights when hovering over entries

### 🖼️ Image Support
- **Image capture** - Optionally save images copied to clipboard (enabled in Settings)
- **Dedicated Images tab** - Appears automatically when image saving is enabled
- **3-column grid layout** - Clean, organized thumbnail view
- **Square thumbnails** - Uniform 90x90 thumbnails with maintained aspect ratio
- **Pin/unpin images** - Keep important images permanently
- **Hover actions** - Copy, pin/unpin, and delete buttons appear on hover
- **Copy feedback** - Visual confirmation when copying images back to clipboard
- **Image limit** - Maximum 50 recent images (pinned images unlimited)
- **Format support** - Captures TIFF and PNG formats from clipboard
- **Efficient storage** - Images stored as PNG data for optimal size and compatibility

### ⚙️ Settings & Configuration
- **History limit** - Configure maximum recent entries (10-100, default 25)
- **Poll interval** - Adjust clipboard check frequency (0.3-2.0 seconds, default 0.8s)
- **Duplicate prevention toggle** - Enable/disable skipping identical content
- **Image saving toggle** - Enable/disable image capture from clipboard
- **Auto-start on login** - Automatically launch the app when you log in
- **Reset to defaults** - One-click button to restore all settings
- **Quit button** - Quick access to quit the app from Settings

### 🔒 Reliability & Safety
- **Atomic file writes** - Prevents data corruption if app crashes during save
- **Single instance enforcement** - Prevents multiple instances from running
- **Automatic migration** - Seamlessly migrates pinned entries from older builds
- **Data persistence** - All preferences and pinned items are automatically saved

---

## 📦 Installation

### From DMG
1. Download `Rz Clipboard-v1.0.0.dmg`
2. Open the DMG file
3. Drag `Rz Clipboard.app` to your Applications folder
4. Launch from Applications or Spotlight

### From Source
```bash
swift run
```

---

## 🗑️ Uninstall

Run the included uninstall script:
```bash
./uninstall.sh
```

Or manually remove:
- App bundle from Applications
- `~/Library/Application Support/rzclipboard`
- `~/Library/Preferences/com.robin.rzclipboard.plist`
- `~/Library/LaunchAgents/com.robin.rzclipboard.plist` (if auto-start was enabled)

---

## 📊 System Requirements

- **macOS 13.0** (Ventura) or later
- **Xcode 15.4** (Swift 6) or later for building from source

---

## 📝 Technical Details

### Data Storage
- **Preferences**: Stored in `UserDefaults` with automatic validation
- **Pinned text**: `~/Library/Application Support/rzclipboard/pinned.json`
- **Pinned images**: `~/Library/Application Support/rzclipboard/pinned-images.json`
- **Recent entries**: Stored in memory only (lost on app quit)

### Architecture
- Built with **SwiftUI** and **AppKit**
- Uses **Swift Package Manager** for dependencies
- Menu bar app (LSUIElement) - no dock icon
- Launch Agent integration for auto-start functionality

---

## 🐛 Known Issues

None at this time. Please report any issues on the [GitHub Issues](https://github.com/yourusername/rz-clipboard/issues) page.

---

## 🚀 What's Next?

Future roadmap includes:
- Search functionality
- Pin ordering/reordering
- Keyboard shortcuts
- iCloud sync
- Better filtering options

Suggestions and contributions welcome!

---

## 🙏 Credits

Built with ❤️ using SwiftUI and AppKit.

