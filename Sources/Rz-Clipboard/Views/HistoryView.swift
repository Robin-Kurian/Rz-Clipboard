import SwiftUI

/// Main history view displaying pinned and recent clipboard entries
/// Shows empty state when no entries exist, otherwise displays sections for pinned and recent items
struct HistoryView: View {
    // MARK: - Properties
    /// Clipboard store containing all entries
    @ObservedObject var store: ClipboardHistoryStore

    // MARK: - Main Body
    var body: some View {
        VStack(spacing: 8) {
            header
            Divider()
            historyList
        }
        .padding(8)
    }
    
    // MARK: - Time Formatting
    /// Date formatter for displaying copied time (e.g., "2:30 PM")
    /// Uses system's short time style (respects user's 12/24 hour preference)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short // Shows time only (no date)
        formatter.dateStyle = .none
        return formatter
    }()
    
    /// Weekday formatter for displaying day names (e.g., "Monday")
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full weekday name
        return formatter
    }()
    
    /// Date and time formatter for older dates
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Format a date as a time string with relative date (e.g., "Today 2:30 PM", "Yesterday 7:10 PM")
    /// - Parameter date: Date to format
    /// - Returns: Formatted time string with relative date prefix
    private func formatCopiedTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if date is today
        if calendar.isDateInToday(date) {
            return "\(Self.timeFormatter.string(from: date)) Today"
        }
        
        // Check if date is yesterday
        if calendar.isDateInYesterday(date) {
            return "\(Self.timeFormatter.string(from: date)) Yesterday"
        }
        
        // Check if date is within the last 7 days
        if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo <= 7 {
            return "\(Self.timeFormatter.string(from: date)) \(Self.weekdayFormatter.string(from: date))"
        }
        
        // For older dates, show date and time
        return Self.dateTimeFormatter.string(from: date)
    }

    // MARK: - Header
    /// Top header with app title and clear button
    private var header: some View {
        HStack(spacing: 10) {
            // App title and info text
            VStack(alignment: .leading, spacing: 2) {
                Text("Rz Clipboard")
                    .font(.headline)
                Text("NB: Pinned items wont be purged!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Clear button (only clears recent, not pinned)
            Button("Clear Recent", role: .destructive) {
                store.clear()
            }
            .disabled(store.entries.isEmpty) // Disable if no recent entries
        }
    }

    // MARK: - History List
    /// Main content area showing pinned and recent entries
    /// Shows empty state if no entries exist
    @ViewBuilder
    private var historyList: some View {
        if store.entries.isEmpty && store.pinnedEntries.isEmpty {
            // Show empty state when no entries
            emptyState
        } else {
            // Show scrollable list of entries
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Pinned section (shown first if entries exist)
                    if !store.pinnedEntries.isEmpty {
                        sectionLabel("Pinned")
                        VStack(spacing: 8) {
                            // Render each pinned entry (no delete action for pinned items)
                            ForEach(store.pinnedEntries) { entry in
                                ClipboardRow(
                                    entry: entry,
                                    copyAction: { store.copyToClipboard(entry) },
                                    pinAction: { store.togglePin(entry) },
                                    deleteAction: nil, // Pinned items cannot be deleted
                                    relativeTime: formatCopiedTime(entry.capturedAt)
                                )
                            }
                        }
                    }

                    // Recent section (shown after pinned)
                    if !store.entries.isEmpty {
                        sectionLabel("Recent")
                        VStack(spacing: 8) {
                            // Render each recent entry (with delete action)
                            ForEach(store.entries) { entry in
                                ClipboardRow(
                                    entry: entry,
                                    copyAction: { store.copyToClipboard(entry) },
                                    pinAction: { store.togglePin(entry) },
                                    deleteAction: { store.deleteEntry(entry) }, // Recent items can be deleted
                                    relativeTime: formatCopiedTime(entry.capturedAt)
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    /// Empty state shown when no clipboard entries exist
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No items yet")
                .font(.headline)
            Text("Copy text anywhere to build your history.")
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

