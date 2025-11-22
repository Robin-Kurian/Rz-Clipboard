import Foundation
import AppKit

/// Represents a clipboard image entry with its data and metadata
struct ImageEntry: Identifiable {
    // MARK: - Properties
    /// Unique identifier for this entry
    let id: UUID
    
    /// The image data captured from clipboard
    let imageData: Data
    
    /// Timestamp when this image was captured
    let capturedAt: Date
    
    /// Thumbnail image for display (cached)
    var thumbnail: NSImage?
    
    // MARK: - Initialization
    /// Create a new image entry
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - imageData: The image data from clipboard
    ///   - capturedAt: When the image was captured (defaults to now)
    init(id: UUID = UUID(), imageData: Data, capturedAt: Date = Date()) {
        self.id = id
        self.imageData = imageData
        self.capturedAt = capturedAt
        // Generate thumbnail from image data
        if let image = NSImage(data: imageData) {
            self.thumbnail = image
        }
    }
    
    // MARK: - Helper Methods
    /// Get the full-size image from stored data
    /// - Returns: NSImage if data is valid, nil otherwise
    func getImage() -> NSImage? {
        return NSImage(data: imageData)
    }
}

