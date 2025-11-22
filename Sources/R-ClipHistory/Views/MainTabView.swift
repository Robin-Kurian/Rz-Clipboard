import SwiftUI

/// Main tab view container for History and Settings tabs
/// Custom implementation without inner container boxes
struct MainTabView: View {
    // MARK: - Properties
    /// Clipboard store for history view
    @ObservedObject var store: ClipboardHistoryStore
    
    /// Preferences model for settings view
    @ObservedObject var preferences: PreferencesModel
    
    /// Currently selected tab ID
    @State private var selectedTab: Int = 0
    
    /// Tab items configuration (easily extensible for more tabs)
    private let tabs: [TabItem] = [
        TabItem(id: 0, title: "History", icon: "doc.on.clipboard"),
        TabItem(id: 1, title: "Settings", icon: "gearshape")
        // Add more tabs here as needed, e.g.:
        // TabItem(id: 2, title: "Search", icon: "magnifyingglass")
    ]

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab content area (no inner container)
            Group {
                switch selectedTab {
                case 0:
                    HistoryView(store: store)
                case 1:
                    SettingsView(preferences: preferences)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Reusable tab bar component
            TabBar(items: tabs, selectedTab: $selectedTab)
        }
        .frame(width: 320, height: 360)
    }
}

