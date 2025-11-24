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
    
    /// Computed tab items - Images tab is hidden until saveImages is enabled
    private var tabs: [TabItem] {
        var items: [TabItem] = [
            TabItem(id: 0, title: "History", icon: "doc.on.clipboard")
        ]
        
        // Add Images tab if saveImages is enabled (always exists, just hidden)
        if preferences.saveImages {
            items.append(TabItem(id: 1, title: "Images", icon: "photo"))
        }
        
        // Settings is always last
        items.append(TabItem(id: preferences.saveImages ? 2 : 1, title: "Settings", icon: "gearshape"))
        
        return items
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab content area (no inner container)
            Group {
                switch selectedTab {
                case 0:
                    HistoryView(store: store)
                case 1:
                    if preferences.saveImages {
                        ImagesView(store: store)
                    } else {
                        SettingsView(preferences: preferences)
                    }
                case 2:
                    SettingsView(preferences: preferences)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Reusable tab bar component (only shows visible tabs)
            TabBar(items: tabs, selectedTab: $selectedTab)
        }
        .frame(width: 320, height: 360)
    }
}

