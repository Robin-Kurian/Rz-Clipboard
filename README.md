# R-ClipHistory

R-ClipHistory is a tiny SwiftUI menu-bar utility that keeps text you copy a keyboard shortcut away. It watches the macOS clipboard, splits the data into pinned and recent sections, and lets you drop favorite snippets back onto the pasteboard with a click.

## Features

- **Menu bar dropdown** – A `MenuBarExtra` window that auto-dismisses when focus leaves it.
- **Live clipboard capture** – Polls the system pasteboard roughly every 800 ms and ignores empty/whitespace-only values.
- **Pinned clips** – Promote important entries; they stay above recents and are immune to history limits.
- **Persistent storage** – Pins are saved to `~/Library/Application Support/R-ClipHistory/pinned.json`, so reinstalls or machine restarts keep your favorites intact.
- **Tap-to-copy feedback** – Clicking any entry copies it instantly, shows a “Copied” confirmation, and does not duplicate that entry in history.
- **Clear recent list** – Remove transient items without touching the pinned section.

## Build & Run

```bash
cd "/Users/robin/My Space/Personal/R-ClipHistory"
swift run
```

The app targets macOS 13+ and requires the Xcode 15.4 (Swift 6) toolchain. When you run it, look for the “R-ClipHistory” icon in your menu bar.

## Project Layout

- `Package.swift` – SwiftPM manifest that links SwiftUI and AppKit.
- `Sources/main.swift` – Entire app (app entry point, clipboard store, persistence, and views).

## Roadmap Ideas

Search, pin ordering, keyboard shortcuts, iCloud sync, and better filtering are the next items on the wishlist. Suggestions are welcome!

