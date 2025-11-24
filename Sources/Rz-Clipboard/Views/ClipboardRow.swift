import SwiftUI

/// Reusable row component for displaying a clipboard entry
/// Handles tap-to-copy, pin/unpin actions, and visual feedback
struct ClipboardRow: View {
    // MARK: - Properties
    /// The clipboard entry to display
    let entry: ClipboardEntry
    
    /// Callback when user taps to copy this entry
    let copyAction: () -> Void
    
    /// Callback when user taps pin/unpin button
    let pinAction: () -> Void
    
    /// Optional callback when user taps delete button (only for recent items)
    let deleteAction: (() -> Void)?
    
    /// Formatted time string to display (e.g., "2:30 PM")
    let relativeTime: String
    
    // MARK: - State
    /// Whether this entry was recently copied (for visual feedback)
    /// Shows "Copied" label temporarily after tap
    @State private var didCopyRecently = false
    
    /// Whether mouse is hovering over this row (for visual highlight)
    @State private var isHovering = false

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top row: content text
            Text(entry.content)
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.leading)
                .lineLimit(3) // Show max 3 lines, truncate with ellipsis
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.clear, lineWidth: 1)
                )
                // White shadow for a subtle glow effect on the text container
                .shadow(color: .white.opacity(0.2), radius: 6, x: 0, y: 2)
                .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: 1)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            
            // Bottom row: time, delete button (if recent), copy status, pin button
            HStack {
                // Time label with pin or clock icon
                Label(relativeTime, systemImage: entry.isPinned ? "pin.fill" : "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Delete button (only shown for non-pinned items, right after time)
                if let deleteAction = deleteAction, !entry.isPinned {
                    Button {
                        deleteAction()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
                
                Spacer()
                
                // Copy status label (changes to "Copied" after tap)
                Label(didCopyRecently ? "Copied" : "Tap to copy", 
                      systemImage: didCopyRecently ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(didCopyRecently ? .green : .secondary)
                
                // Pin/unpin button
                Button {
                    pinAction()
                } label: {
                    Label(entry.isPinned ? "Unpin" : "Pin", 
                          systemImage: entry.isPinned ? "pin.slash" : "pin")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        // Background with rounded corners - lighter opacity to match container
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
        // Hover border highlight
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        // Hover shadow effect
        .shadow(color: .black.opacity(isHovering ? 0.2 : 0.05), 
                radius: isHovering ? 6 : 2, x: 0, y: 2)
        // Make entire row tappable (not just text)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        // Handle tap to copy
        .onTapGesture {
            copyAction()
            // Show "Copied" feedback for 1.2 seconds
            didCopyRecently = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                didCopyRecently = false
            }
        }
        // Track hover state for visual feedback
        .onHover { hovering in
            isHovering = hovering
        }
        // Animate hover state changes smoothly
        .animation(.easeInOut(duration: 0.12), value: isHovering)
    }
}

