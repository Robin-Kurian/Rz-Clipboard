import SwiftUI
import AppKit

/// Images view displaying captured clipboard images in a thumbnail grid
struct ImagesView: View {
    // MARK: - Properties
    /// Clipboard store containing image entries
    @ObservedObject var store: ClipboardHistoryStore
    
    // MARK: - Body
    var body: some View {
        if store.imageEntries.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(store.imageEntries) { imageEntry in
                        ImageThumbnail(imageEntry: imageEntry) {
                            store.copyImageToClipboard(imageEntry)
                        }
                    }
                }
                .padding(8)
            }
        }
    }
    
    // MARK: - Empty State
    /// Empty state shown when no images have been captured
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No images yet")
                .font(.headline)
            Text("Copy images to clipboard to see them here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Individual image thumbnail with hover copy action
struct ImageThumbnail: View {
    // MARK: - Properties
    let imageEntry: ImageEntry
    let copyAction: () -> Void
    
    @State private var isHovering = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Thumbnail image
            if let thumbnail = imageEntry.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
            }
            
            // Copy icon overlay (shown on hover)
            if isHovering {
                Button(action: copyAction) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}

