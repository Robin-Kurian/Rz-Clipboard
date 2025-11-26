# Rz Clipboard

Rz Clipboard is a tiny SwiftUI menu-bar utility that keeps text you copy a keyboard shortcut away. It watches the macOS clipboard, splits the data into pinned and recent sections, and lets you drop favorite snippets back onto the pasteboard with a click.

## Features

### Text Clipboard
- **Menu bar dropdown** – A `MenuBarExtra` window that auto-dismisses when focus leaves it.
- **Live clipboard capture** – Polls the system pasteboard (configurable interval, default 800ms) and ignores empty/whitespace-only values.
- **Pinned clips** – Promote important entries; they stay above recents and are immune to history limits.
- **Persistent storage** – Pins are saved to `~/Library/Application Support/rzclipboard/pinned.json`, so reinstalls or machine restarts keep your favorites intact. Uses atomic writes to prevent corruption.
- **Tap-to-copy feedback** – Clicking any entry copies it instantly, shows a "Copied" confirmation, and does not duplicate that entry in history.
- **Delete individual items** – Remove specific recent entries with the delete button (pinned items cannot be deleted).
- **Clear recent list** – Remove all transient items without touching the pinned section.
- **Time display** – Shows actual copied time with relative dates (e.g., "2:25 PM Today", "Yesterday 7:10 PM", weekday names for past week).
- **Hover effects** – Visual feedback when hovering over items (border highlight and shadow effects).
- **Text truncation** – Long entries are truncated to 3 lines with ellipsis for clean display.
- **Empty state** – Helpful message when no clipboard entries exist yet.
- **Single instance** – Prevents multiple instances from running simultaneously.

### Image Support
- **Image capture** – Optionally save images copied to clipboard (enabled in Settings). Supports TIFF and PNG formats.
- **Images tab** – Appears when image saving is enabled, displays captured images in a 3-column grid.
- **Square thumbnails** – All images displayed as uniform 90x90 squares with maintained aspect ratio (cropped to fit).
- **Pin/unpin images** – Pin important images to persist across app restarts.
- **Image persistence** – Pinned images saved to `~/Library/Application Support/rzclipboard/pinned-images.json`. Uses atomic writes to prevent corruption.
- **Delete images** – Remove individual recent images (pinned images must be unpinned first).
- **Image limit** – Maximum of 50 recent images kept in memory (pinned images are unlimited).
- **Hover actions** – Images show copy, pin/unpin, and delete buttons on hover for quick access.
- **Copy feedback** – Visual confirmation when copying images back to clipboard.
- **Empty state** – Helpful message when no images have been captured yet.
- **Image storage** – Images are stored as PNG data for efficient storage and compatibility.

### Settings
- **History limit** – Configure maximum number of recent entries (10-100, default 25, step 5).
- **Poll interval** – Adjust clipboard check frequency (0.3-2.0 seconds, default 0.8s, step 0.1s).
- **Duplicate prevention** – Toggle to skip identical clipboard content (checks both recent and pinned entries).
- **Save images** – Enable/disable image capture from clipboard.
- **Start at login** – Automatically launch the app when you log in to your Mac. Creates Launch Agent that syncs with preferences.
- **Reset to defaults** – Restore all settings to default values.
- **Quit button** – Quick access to quit the app from Settings tab.

## Build & Run

### Development
```bash
cd "/Users/robin/My Space/Personal/Rz-Clipboard"
swift run
```

### Release Build (App Bundle & DMG)
To create a distributable app bundle and DMG file:
```bash
./build-release.sh
```

This will create:
- `build/Rz Clipboard.app` - macOS app bundle
- `build/Rz Clipboard-v1.0.0.dmg` - DMG installer

To install from DMG:
1. Open the DMG file
2. Drag `Rz Clipboard.app` to your Applications folder
3. Launch from Applications or Spotlight

**Note:** Menu bar apps (LSUIElement) don't appear in the dock but will show in the menu bar.

### Uninstall
To completely remove the app and all its data:
```bash
./uninstall.sh
```

The uninstall script will:
- Stop any running instances
- Remove the app bundle from common locations
- Delete application data (`~/Library/Application Support/rzclipboard`)
- Remove preferences (`~/Library/Preferences/com.robin.rzclipboard.plist`)
- Remove Launch Agent if auto-start was enabled (`~/Library/LaunchAgents/com.robin.rzclipboard.plist`)
- Clear any caches

Or manually:
1. Quit the app (click menu bar icon or `pkill -f "Rz Clipboard"`)
2. Remove app bundle from wherever you installed it
3. Delete `~/Library/Application Support/rzclipboard`
4. Delete `~/Library/Preferences/com.robin.rzclipboard.plist` (if exists)
5. Delete `~/Library/LaunchAgents/com.robin.rzclipboard.plist` (if auto-start was enabled)

The app targets macOS 13+ and requires the Xcode 15.4 (Swift 6) toolchain. When you run it, look for the "Rz Clipboard" icon in your menu bar.

## Data Storage

### Preferences
- Stored in `UserDefaults` with keys prefixed with `pref.`
- Automatically synced and validated on changes
- Settings include: history limit, poll interval, duplicate prevention, image saving, auto-start

### Pinned Entries
- Text entries: `~/Library/Application Support/rzclipboard/pinned.json`
- Image entries: `~/Library/Application Support/rzclipboard/pinned-images.json`
- Uses atomic writes to prevent corruption
- Automatic migration from legacy UserDefaults storage (for older builds)

### Recent Entries
- Stored in memory only (lost on app quit)
- Text entries: up to configured history limit (default 25)
- Image entries: maximum 50 recent images
- Automatically trimmed when limits are exceeded

## Project Layout

- `Package.swift` – SwiftPM manifest that links SwiftUI and AppKit.
- `Sources/Rz-Clipboard/App.swift` – Main app entry point with single-instance enforcement and Launch Agent sync.
- `Sources/Rz-Clipboard/Models/` – Data models (ClipboardEntry, ImageEntry, PreferencesModel).
- `Sources/Rz-Clipboard/Stores/` – ClipboardHistoryStore for clipboard monitoring and persistence, LaunchAgentManager for auto-start functionality.
- `Sources/Rz-Clipboard/Views/` – SwiftUI views (HistoryView, ImagesView, SettingsView, MainTabView, TabBar, ClipboardRow, ImageThumbnail).

## Roadmap Ideas

Search, pin ordering, keyboard shortcuts, iCloud sync, and better filtering are the next items on the wishlist. Suggestions are welcome!
