import SwiftUI
import AppKit

/// Main application entry point for Rz Clipboard
/// This is a macOS menu bar app that tracks clipboard history
@main
struct RzClipboardApp: App {
    // MARK: - Singleton Check
    /// Static check to prevent multiple instances from running
    /// This executes before init() to avoid race conditions
    private static let shouldTerminate: Bool = {
        let bundleId = "com.robin.rzclipboard"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        let currentPID = ProcessInfo.processInfo.processIdentifier
        
        // Check if there's another instance already running (different PID)
        let otherInstances = runningApps.filter { $0.processIdentifier != currentPID }
        
        if !otherInstances.isEmpty {
            // Another instance is already running - terminate this one immediately
            print("⚠️  Another instance of Rz Clipboard is already running. Terminating this instance.")
            // Schedule termination on main thread
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
            return true
        }
        return false
    }()
    
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
        // If we should terminate, don't initialize anything
        // The static check already scheduled termination
        guard !Self.shouldTerminate else {
            // Create dummy instances to satisfy Swift's initialization requirements
            _preferences = StateObject(wrappedValue: PreferencesModel())
            _store = StateObject(wrappedValue: ClipboardHistoryStore(preferences: PreferencesModel()))
            return
        }
        
        // Create preferences model (loads from UserDefaults or uses defaults)
        let prefs = PreferencesModel()
        _preferences = StateObject(wrappedValue: prefs)
        
        // Create clipboard store with preferences dependency
        // Store will start polling clipboard immediately
        _store = StateObject(wrappedValue: ClipboardHistoryStore(preferences: prefs))
        
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
