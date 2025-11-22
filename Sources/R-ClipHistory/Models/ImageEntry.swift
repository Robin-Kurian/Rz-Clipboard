import Foundation
import AppKit

/// Extension to NSImage for validation
extension NSImage {
    /// Check if the image is valid and can be displayed
    var isValid: Bool {
        guard !self.representations.isEmpty else { return false }
        guard self.size.width > 0 && self.size.height > 0 else { return false }
        return true
    }
}

/// Represents a clipboard image entry with its data and metadata
/// Conforms to Identifiable for ForEach loops and Codable for persistence
struct ImageEntry: Identifiable, Codable {
    // MARK: - Properties
    /// Unique identifier for this entry
    var id: UUID
    
    /// The image data captured from clipboard (stored as PNG)
    let imageData: Data
    
    /// Timestamp when this image was captured
    let capturedAt: Date
    
    /// A boolean indicating whether the entry is pinned.
    /// Pinned entries are persisted and not subject to history limits.
    var isPinned: Bool
    
    // MARK: - Initialization
    /// Create a new image entry
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - imageData: The image data from clipboard
    ///   - capturedAt: When the image was captured (defaults to now)
    ///   - isPinned: Initial pin status (defaults to false)
    init(id: UUID = UUID(), imageData: Data, capturedAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.isPinned = isPinned
    }
    
    // MARK: - Helper Methods
    /// Get the full-size image from stored data
    /// - Returns: NSImage if data is valid, nil otherwise
    func getImage() -> NSImage? {
        guard !imageData.isEmpty else { return nil }
        guard let image = NSImage(data: imageData) else { return nil }
        // Validate image has valid size
        guard image.size.width > 0 && image.size.height > 0 else { return nil }
        return image
    }
    
    /// Get thumbnail image for display (computed property)
    /// - Returns: NSImage if data is valid, nil otherwise
    var thumbnail: NSImage? {
        return getImage()
    }
}

