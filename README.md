# R-ClipHistory

R-ClipHistory is a tiny SwiftUI menu-bar utility that keeps text you copy a keyboard shortcut away. It watches the macOS clipboard, splits the data into pinned and recent sections, and lets you drop favorite snippets back onto the pasteboard with a click.

## Features

### Text Clipboard
- **Menu bar dropdown** – A `MenuBarExtra` window that auto-dismisses when focus leaves it.
- **Live clipboard capture** – Polls the system pasteboard (configurable interval, default 800ms) and ignores empty/whitespace-only values.
- **Pinned clips** – Promote important entries; they stay above recents and are immune to history limits.
- **Persistent storage** – Pins are saved to `~/Library/Application Support/R-ClipHistory/pinned.json`, so reinstalls or machine restarts keep your favorites intact.
- **Tap-to-copy feedback** – Clicking any entry copies it instantly, shows a "Copied" confirmation, and does not duplicate that entry in history.
- **Delete individual items** – Remove specific recent entries with the delete button (pinned items cannot be deleted).
- **Clear recent list** – Remove all transient items without touching the pinned section.
- **Time display** – Shows actual copied time with relative dates (e.g., "2:25 PM Today", "Yesterday 7:10 PM").
- **Hover effects** – Visual feedback when hovering over items.

### Image Support
- **Image capture** – Optionally save images copied to clipboard (enabled in Settings).
- **Images tab** – Appears when image saving is enabled, displays captured images in a 3-column grid.
- **Square thumbnails** – All images displayed as uniform 90x90 squares with maintained aspect ratio (cropped to fit).
- **Pin/unpin images** – Pin important images to persist across app restarts.
- **Image persistence** – Pinned images saved to `~/Library/Application Support/R-ClipHistory/pinned-images.json`.
- **Delete images** – Remove individual recent images (pinned images must be unpinned first).

### Settings
- **History limit** – Configure maximum number of recent entries (10-100, default 25).
- **Poll interval** – Adjust clipboard check frequency (0.3-2.0 seconds, default 0.8s).
- **Duplicate prevention** – Toggle to skip identical clipboard content.
- **Save images** – Enable/disable image capture from clipboard.
- **Reset to defaults** – Restore all settings to default values.

## Build & Run

```bash
cd "/Users/robin/My Space/Personal/R-ClipHistory"
swift run
```

The app targets macOS 13+ and requires the Xcode 15.4 (Swift 6) toolchain. When you run it, look for the "R-ClipHistory" icon in your menu bar.

## Project Layout

- `Package.swift` – SwiftPM manifest that links SwiftUI and AppKit.
- `Sources/R-ClipHistory/App.swift` – Main app entry point.
- `Sources/R-ClipHistory/Models/` – Data models (ClipboardEntry, ImageEntry, PreferencesModel).
- `Sources/R-ClipHistory/Stores/` – ClipboardHistoryStore for clipboard monitoring and persistence.
- `Sources/R-ClipHistory/Views/` – SwiftUI views (HistoryView, ImagesView, SettingsView, MainTabView, TabBar, ClipboardRow).

## Roadmap Ideas

Search, pin ordering, keyboard shortcuts, iCloud sync, and better filtering are the next items on the wishlist. Suggestions are welcome!
