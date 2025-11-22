import SwiftUI

/// Main application entry point for R-ClipHistory
/// This is a macOS menu bar app that tracks clipboard history
@main
struct RClipHistoryApp: App {
    // MARK: - State Management
    /// User preferences (history limit, poll interval, duplicate prevention)
    /// Persisted to UserDefaults and automatically synced
    @StateObject private var preferences: PreferencesModel
    
    /// Core clipboard history store that monitors pasteboard changes
    /// Manages both pinned (persistent) and recent (in-memory) entries
    @StateObject private var store: ClipboardHistoryStore

    // MARK: - Initialization
    /// Initialize app with shared preferences and clipboard store
    /// Preferences must be created first since store depends on it
    init() {
        // Create preferences model (loads from UserDefaults or uses defaults)
        let prefs = PreferencesModel()
        _preferences = StateObject(wrappedValue: prefs)
        
        // Create clipboard store with preferences dependency
        // Store will start polling clipboard immediately
        _store = StateObject(wrappedValue: ClipboardHistoryStore(preferences: prefs))
    }

    // MARK: - Scene Configuration
    /// Configure menu bar extra with dropdown window
    var body: some Scene {
        MenuBarExtra("R-ClipHistory", systemImage: "doc.on.clipboard.fill") {
            // Main tab view containing History and Settings tabs
            MainTabView(store: store, preferences: preferences)
                .padding(12)
                .background(.quaternary.opacity(0.25))
        }
        .menuBarExtraStyle(.window) // Window style allows clicking outside to close
    }
}
