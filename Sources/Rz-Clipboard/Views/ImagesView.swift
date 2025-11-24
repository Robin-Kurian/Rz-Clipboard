import SwiftUI
import AppKit

/// Images view displaying captured clipboard images in a thumbnail grid
/// Shows pinned and recent sections, similar to HistoryView
struct ImagesView: View {
    // MARK: - Properties
    /// Clipboard store containing image entries
    @ObservedObject var store: ClipboardHistoryStore
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 8) {
            header
            Divider()
            imageGrid
        }
        .padding(8)
    }
    
    // MARK: - Header
    /// Top header with title and clear button
    private var header: some View {
        HStack(spacing: 10) {
            // Title and info text
            VStack(alignment: .leading, spacing: 2) {
                Text("Images")
                    .font(.headline)
                Text("NB: Pinned images won't be purged!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Clear button (only clears recent, not pinned)
            Button("Clear Recent", role: .destructive) {
                store.clearImages()
            }
            .disabled(store.imageEntries.isEmpty) // Disable if no recent entries
        }
    }
    
    // MARK: - Image Grid
    /// Main content area showing pinned and recent images
    /// Shows empty state if no images exist
    @ViewBuilder
    private var imageGrid: some View {
        if store.imageEntries.isEmpty && store.pinnedImageEntries.isEmpty {
            // Show empty state when no images
            emptyState
        } else {
            // Show scrollable grid of images
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Pinned section (shown first if entries exist)
                    if !store.pinnedImageEntries.isEmpty {
                        sectionLabel("Pinned")
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(store.pinnedImageEntries) { imageEntry in
                                ImageThumbnail(
                                    imageEntry: imageEntry,
                                    copyAction: { store.copyImageToClipboard(imageEntry) },
                                    pinAction: { store.toggleImagePin(imageEntry) },
                                    deleteAction: nil // Pinned images cannot be deleted
                                )
                            }
                        }
                    }
                    
                    // Recent section (shown after pinned)
                    if !store.imageEntries.isEmpty {
                        sectionLabel("Recent")
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(store.imageEntries) { imageEntry in
                                ImageThumbnail(
                                    imageEntry: imageEntry,
                                    copyAction: { store.copyImageToClipboard(imageEntry) },
                                    pinAction: { store.toggleImagePin(imageEntry) },
                                    deleteAction: { store.deleteImageEntry(imageEntry) } // Provide delete action for recent items
                                )
                            }
                        }
                    }
                }
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
    
    // MARK: - Helper Views
    /// Section label for "Pinned" or "Recent" sections
    /// - Parameter title: Section title to display
    /// - Returns: Uppercased label view
    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }
}

/// Individual image thumbnail with hover copy, pin, and delete actions
/// All thumbnails are displayed as squares with maintained aspect ratio (cropped to fit)
struct ImageThumbnail: View {
    // MARK: - Properties
    let imageEntry: ImageEntry
    let copyAction: () -> Void
    let pinAction: () -> Void
    let deleteAction: (() -> Void)? // Optional - only for recent items
    
    // MARK: - State
    @State private var isHovering = false
    @State private var didCopyRecently = false
    
    // MARK: - Body
    var body: some View {
        // Fixed square container ensures all thumbnails are the same size
        ZStack {
            // Thumbnail image - always square, maintains aspect ratio by cropping
            Group {
                if let image = imageEntry.getImage(), image.isValid {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Fill the square, cropping if needed to maintain aspect ratio
                        .frame(width: 90, height: 90) // Fixed square dimensions for all thumbnails
                        .clipped() // Clip any overflow to maintain perfect square
                        .cornerRadius(8)
                } else {
                    // Fallback for invalid or missing images
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 90, height: 90) // Fixed square dimensions
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        )
                }
            }
            
            // Action buttons overlay (shown on hover)
            if isHovering {
                VStack {
                    HStack {
                        // Pin/unpin button (top left)
                        Button(action: pinAction) {
                            Image(systemName: imageEntry.isPinned ? "pin.slash" : "pin")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.7))
                                )
                        }
                        .buttonStyle(.plain)
                        .help(imageEntry.isPinned ? "Unpin" : "Pin")
                        
                        Spacer()
                        
                        // Delete button (top right, only for recent items)
                        if let deleteAction = deleteAction, !imageEntry.isPinned {
                            Button(action: deleteAction) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(
                                        Circle()
                                            .fill(Color.red.opacity(0.8))
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("Delete")
                        }
                    }
                    .padding(6)
                    
                    Spacer()
                    
                    // Copy button (bottom center)
                    Button(action: {
                        copyAction()
                        didCopyRecently = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            didCopyRecently = false
                        }
                    }) {
                        Image(systemName: didCopyRecently ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            .font(.title3)
                            .foregroundStyle(didCopyRecently ? .green : .white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                            )
                    }
                    .buttonStyle(.plain)
                    .help(didCopyRecently ? "Copied!" : "Copy image")
                    .padding(.bottom, 6)
                }
            }
        }
        .frame(width: 90, height: 90) // Fixed container size ensures no overlapping
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}

