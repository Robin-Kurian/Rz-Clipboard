import SwiftUI

/// Reusable tab item model for tab bar
struct TabItem: Identifiable {
    let id: String  // Changed from Int to String for stable IDs
    let title: String
    let icon: String
    let selectedIcon: String
    
    init(id: String, title: String, icon: String, selectedIcon: String? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon + ".fill"
    }
}

/// Reusable tab bar component with consistent styling
struct TabBar: View {
    // MARK: - Properties
    /// Array of tab items to display
    let items: [TabItem]
    
    /// Currently selected tab ID (String instead of Int)
    @Binding var selectedTab: String
    
    // MARK: - Body
    var body: some View {
        Divider()
        HStack(spacing: 0) {
            ForEach(items) { item in
                TabButton(
                    item: item,
                    isSelected: selectedTab == item.id,
                    action: { selectedTab = item.id }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

/// Individual tab button component
struct TabButton: View {
    // MARK: - Properties
    let item: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? item.selectedIcon : item.icon)
                    .imageScale(.small)
                    .font(.system(size: 12))
                Text(item.title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            // Make entire button area tappable, not just text/icon
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

