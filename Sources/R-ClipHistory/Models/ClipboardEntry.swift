import Foundation

/// Represents a single clipboard entry with its content and metadata
/// Conforms to Identifiable for SwiftUI list rendering and Codable for JSON persistence
struct ClipboardEntry: Identifiable, Codable {
    // MARK: - Properties
    /// Unique identifier for this entry (used for SwiftUI ForEach and deduplication)
    var id: UUID
    
    /// The actual text content that was copied to clipboard
    let content: String
    
    /// Timestamp when this entry was captured from the clipboard
    /// Used for displaying time and sorting entries
    let capturedAt: Date
    
    /// Whether this entry is pinned (persisted across app restarts)
    /// Pinned entries are saved to disk, recent entries are in-memory only
    var isPinned: Bool

    // MARK: - Initialization
    /// Create a new clipboard entry
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - content: The clipboard text content
    ///   - capturedAt: When the content was captured (defaults to now)
    ///   - isPinned: Whether entry should be persisted (defaults to false)
    init(id: UUID = UUID(), content: String, capturedAt: Date, isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
        self.isPinned = isPinned
    }
}

