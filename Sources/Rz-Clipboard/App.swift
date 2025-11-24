import SwiftUI
import AppKit

/// Main application entry point for Rz Clipboard
/// This is a macOS menu bar app that tracks clipboard history
@main
struct RzClipboardApp: App {
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
        
        // Prevent multiple instances from running
        // Check if another instance is already running (before this one was launched)
        let bundleId = "com.robin.rzclipboard"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        
        // Get current process ID
        let currentPID = ProcessInfo.processInfo.processIdentifier
        
        // Check if there's another instance running (different PID)
        let otherInstances = runningApps.filter { $0.processIdentifier != currentPID }
        
        // If there's already a running instance (other than this one), terminate
        // Note: This check happens after initialization to satisfy Swift's requirements
        if !otherInstances.isEmpty {
            // Another instance is already running - terminate this one after a brief delay
            // This allows the app to initialize properly before terminating
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                NSApplication.shared.terminate(nil)
            }
            return
        }
        
        // Sync Launch Agent with current preference state on app launch
        // Delay slightly to ensure app is fully initialized
        Task { @MainActor in
            // Small delay to ensure app is fully running
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            let launchAgentManager = LaunchAgentManager()
            let shouldBeEnabled = prefs.autoStartOnLogin
            let isCurrentlyEnabled = launchAgentManager.isAutoStartEnabled()
            
            // If preference says enabled but Launch Agent doesn't exist, create it
            if shouldBeEnabled && !isCurrentlyEnabled {
                _ = launchAgentManager.enableAutoStart()
            }
            // If preference says disabled but Launch Agent exists, remove it
            else if !shouldBeEnabled && isCurrentlyEnabled {
                _ = launchAgentManager.disableAutoStart()
            }
        }
    }

    // MARK: - Scene Configuration
    /// Configure menu bar extra with dropdown window
    var body: some Scene {
        MenuBarExtra("Rz Clipboard", systemImage: "doc.on.clipboard.fill") {
            // Main tab view containing History and Settings tabs
            MainTabView(store: store, preferences: preferences)
                .padding(12)
                .background(.quaternary.opacity(0.25))
                // .background(.ultraThinMaterial.opacity(0.25))
        }
        .menuBarExtraStyle(.window) // Window style allows clicking outside to close
    }
}
