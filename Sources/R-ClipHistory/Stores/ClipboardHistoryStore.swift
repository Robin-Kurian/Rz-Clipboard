import SwiftUI
import AppKit
import Combine

/// Core store for managing clipboard history
/// Monitors system pasteboard, maintains in-memory recent entries and persistent pinned entries
/// All operations must run on MainActor for UI thread safety
@MainActor
final class ClipboardHistoryStore: ObservableObject {
    // MARK: - Published Properties
    /// Recent (non-pinned) clipboard entries stored in memory only
    /// These are lost when app quits - only pinned entries persist
    /// Sorted by most recent first (inserted at index 0)
    @Published private(set) var entries: [ClipboardEntry] = []
    
    /// Pinned clipboard entries that persist across app restarts
    /// Saved to ~/Library/Application Support/R-ClipHistory/pinned.json
    /// Sorted by most recent first (inserted at index 0)
    @Published private(set) var pinnedEntries: [ClipboardEntry] = []
    
    /// Captured images from clipboard (stored in memory only)
    /// Only captured when saveImages preference is enabled
    /// Sorted by most recent first (inserted at index 0)
    @Published private(set) var imageEntries: [ImageEntry] = []

    // MARK: - Private Properties
    /// Reference to preferences model for configuration
    private let preferences: PreferencesModel
    
    /// Tracks the last known pasteboard change count to detect clipboard changes
    /// NSPasteboard.changeCount increments whenever clipboard content changes
    private var changeCount: Int
    
    /// Timer that polls clipboard at configured interval
    /// Invalidated and recreated when poll interval changes
    private var timer: Timer?
    
    /// Legacy UserDefaults key for pinned entries (used for migration from older builds)
    private let pinnedStorageKey = "com.robin.rcliphistory.pinned"
    
    /// Combine cancellables for preference change subscriptions
    private var cancellables: Set<AnyCancellable> = []
    
    /// File URL for persistent storage of pinned entries
    /// Location: ~/Library/Application Support/R-ClipHistory/pinned.json
    /// Directory is created automatically if it doesn't exist
    private lazy var pinnedFileURL: URL = {
        let fileManager = FileManager.default
        // Get Application Support directory for current user
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        // Create R-ClipHistory subdirectory
        let directory = appSupport.appendingPathComponent("R-ClipHistory", isDirectory: true)
        // Create directory if it doesn't exist (first run)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        // Return path to pinned.json file
        return directory.appendingPathComponent("pinned.json")
    }()

    // MARK: - Initialization
    /// Initialize clipboard store with preferences
    /// - Parameter preferences: Preferences model for configuration
    /// Sets up clipboard monitoring, loads persisted pins, and binds preference changes
    init(preferences: PreferencesModel) {
        self.preferences = preferences
        // Capture current pasteboard change count to avoid capturing existing content
        self.changeCount = NSPasteboard.general.changeCount
        // Load pinned entries from disk (if any)
        loadPinnedEntries()
        // Start polling clipboard at configured interval
        startPolling()
        // Subscribe to preference changes for reactive updates
        bindPreferences()
    }

    // MARK: - Public Methods
    /// Copy an entry's content back to the system clipboard
    /// Updates changeCount to prevent re-capturing this content immediately
    /// - Parameter entry: The clipboard entry to copy
    func copyToClipboard(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.content, forType: .string)
        // Update changeCount so we don't immediately re-capture this content
        // This prevents entries from duplicating when user copies from history
        changeCount = pasteboard.changeCount
    }
    
    /// Copy an image entry back to the system clipboard
    /// Updates changeCount to prevent re-capturing this image immediately
    /// - Parameter imageEntry: The image entry to copy
    func copyImageToClipboard(_ imageEntry: ImageEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let image = imageEntry.getImage() {
            pasteboard.writeObjects([image])
        }
        // Update changeCount so we don't immediately re-capture this image
        changeCount = pasteboard.changeCount
    }

    /// Clear all recent (non-pinned) entries from memory
    /// Pinned entries are not affected
    func clear() {
        entries.removeAll()
    }

    /// Toggle pin status of an entry
    /// Pinned entries are moved to pinnedEntries and persisted to disk
    /// Unpinned entries are moved back to entries (in-memory)
    /// - Parameter entry: The entry to pin/unpin
    func togglePin(_ entry: ClipboardEntry) {
        entry.isPinned ? unpin(entry) : pin(entry)
    }
    
    /// Delete a recent (non-pinned) entry
    /// Only works for entries in the recent list, not pinned entries
    /// - Parameter entry: The entry to delete
    func deleteEntry(_ entry: ClipboardEntry) {
        // Only allow deletion of non-pinned entries
        guard !entry.isPinned else { return }
        entries.removeAll { $0.id == entry.id }
    }

    // MARK: - Pin Management
    /// Pin an entry (move to persistent storage)
    /// - Parameter entry: Entry to pin
    private func pin(_ entry: ClipboardEntry) {
        // Prevent duplicate pins
        guard !pinnedEntries.contains(where: { $0.id == entry.id }) else { return }
        
        // Mark as pinned and add to pinned entries (most recent first)
        var pinnedEntry = entry
        pinnedEntry.isPinned = true
        pinnedEntries.insert(pinnedEntry, at: 0)
        
        // Remove from recent entries if it exists there
        entries.removeAll { $0.id == entry.id }
        
        // Persist to disk immediately
        persistPinnedEntries()
    }

    /// Unpin an entry (move back to in-memory recent entries)
    /// - Parameter entry: Entry to unpin
    private func unpin(_ entry: ClipboardEntry) {
        // Remove from pinned entries
        pinnedEntries.removeAll { $0.id == entry.id }
        
        // Mark as unpinned and add back to recent entries (most recent first)
        var restoredEntry = entry
        restoredEntry.isPinned = false
        entries.insert(restoredEntry, at: 0)
        
        // Enforce history limit (may remove oldest if over limit)
        enforceHistoryLimit()
        
        // Persist updated pinned list to disk
        persistPinnedEntries()
    }

    // MARK: - Preference Binding
    /// Subscribe to preference changes for reactive updates
    /// Uses Combine to automatically respond to preference changes
    private func bindPreferences() {
        // When history limit changes, enforce it immediately
        preferences.$historyLimit
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.enforceHistoryLimit()
            }
            .store(in: &cancellables)

        // When poll interval changes, restart polling with new interval
        preferences.$pollInterval
            .removeDuplicates() // Only react to actual value changes
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.startPolling()
            }
            .store(in: &cancellables)
    }

    // MARK: - Clipboard Polling
    /// Start or restart clipboard polling timer with current interval
    /// Invalidates existing timer before creating new one
    private func startPolling() {
        // Stop existing timer if any
        timer?.invalidate()
        
        // Ensure minimum interval of 0.3 seconds (prevents excessive CPU usage)
        let interval = max(preferences.pollInterval, 0.3)
        
        // Create new timer that calls captureClipboardChange
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            // Use Task to call async function from timer callback
            Task { await self?.captureClipboardChange() }
        }
        
        // Add timer to main run loop so it works even when menu is closed
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Check clipboard for changes and capture new content
    /// Called periodically by polling timer
    /// Captures both text and images (if enabled)
    @MainActor
    private func captureClipboardChange() {
        let pasteboard = NSPasteboard.general
        
        // Check if clipboard actually changed (changeCount increments on any change)
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount

        // Try to capture image first (if enabled)
        if preferences.saveImages {
            if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
               let tiffData = image.tiffRepresentation,
               let imageData = NSBitmapImageRep(data: tiffData)?.representation(using: .png, properties: [:]) {
                // Check for duplicates by comparing image data
                if !preferences.preventDuplicates || 
                   !imageEntries.contains(where: { $0.imageData == imageData }) {
                    let imageEntry = ImageEntry(imageData: imageData, capturedAt: Date())
                    imageEntries.insert(imageEntry, at: 0)
                    // Limit to 50 images max
                    if imageEntries.count > 50 {
                        imageEntries.removeLast()
                    }
                    return // Don't process text if we captured an image
                }
            }
        }

        // Get string content and trim whitespace
        guard let newValue = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !newValue.isEmpty else { return }

        // Skip if duplicate prevention is enabled and content already exists
        if preferences.preventDuplicates &&
            (entries.contains(where: { $0.content == newValue }) ||
             pinnedEntries.contains(where: { $0.content == newValue })) {
            return
        }

        // Create new entry with current timestamp
        let entry = ClipboardEntry(content: newValue, capturedAt: Date())
        
        // Add to recent entries (most recent first)
        entries.insert(entry, at: 0)
        
        // Enforce history limit (may remove oldest entries)
        enforceHistoryLimit()
    }

    /// Enforce maximum history limit by removing oldest entries
    /// Only affects recent (non-pinned) entries
    private func enforceHistoryLimit() {
        let limit = preferences.historyLimit
        if entries.count > limit {
            // Remove oldest entries (from end of array)
            entries.removeLast(entries.count - limit)
        }
    }

    // MARK: - Persistence
    /// Load pinned entries from disk on app startup
    /// Falls back to UserDefaults for migration from older builds
    private func loadPinnedEntries() {
        // Try loading from JSON file (current storage method)
        if let data = try? Data(contentsOf: pinnedFileURL) {
            decodePinnedEntries(from: data)
            return
        }

        // Fallback: Migrate from UserDefaults (older builds used this)
        // This ensures users upgrading from old versions don't lose pinned items
        if let legacyData = UserDefaults.standard.data(forKey: pinnedStorageKey) {
            decodePinnedEntries(from: legacyData)
            // Migrate to new file-based storage
            persistPinnedEntries()
            // Clean up old UserDefaults entry
            UserDefaults.standard.removeObject(forKey: pinnedStorageKey)
        }
    }

    /// Decode pinned entries from JSON data
    /// Ensures all loaded entries are marked as pinned
    /// - Parameter data: JSON data containing array of ClipboardEntry
    private func decodePinnedEntries(from data: Data) {
        guard let decoded = try? JSONDecoder().decode([ClipboardEntry].self, from: data) else { return }
        
        // Ensure all entries are marked as pinned (safety check)
        pinnedEntries = decoded.map {
            var entry = $0
            entry.isPinned = true
            return entry
        }
    }

    /// Save pinned entries to disk as JSON
    /// Uses atomic write to prevent corruption if app crashes during save
    private func persistPinnedEntries() {
        guard let data = try? JSONEncoder().encode(pinnedEntries) else { return }
        // Atomic write ensures file is either fully written or not at all
        // Prevents partial/corrupted files if app crashes during write
        try? data.write(to: pinnedFileURL, options: [.atomic])
    }
}

