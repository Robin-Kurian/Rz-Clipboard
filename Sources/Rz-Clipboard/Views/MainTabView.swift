import SwiftUI

/// Tab identifier enum for stable tab selection
/// Using enum ensures tab IDs don't change when preferences toggle
enum TabIdentifier: String, Codable {
    case history
    case images
    case settings
}

/// Main tab view container for History and Settings tabs
/// Custom implementation without inner container boxes
struct MainTabView: View {
    // MARK: - Properties
    /// Clipboard store for history view
    @ObservedObject var store: ClipboardHistoryStore
    
    /// Preferences model for settings view
    @ObservedObject var preferences: PreferencesModel
    
    /// Currently selected tab ID (persisted to UserDefaults)
    @State private var selectedTab: TabIdentifier
    
    /// UserDefaults key for persisting selected tab
    private let selectedTabKey = "com.robin.rzclipboard.selectedTab"
    
    /// Initialize with store and preferences
    init(store: ClipboardHistoryStore, preferences: PreferencesModel) {
        self.store = store
        self.preferences = preferences
        
        // Load persisted tab selection from UserDefaults
        if let savedTab = UserDefaults.standard.string(forKey: "com.robin.rzclipboard.selectedTab"),
           let tab = TabIdentifier(rawValue: savedTab) {
            _selectedTab = State(initialValue: tab)
        } else {
            _selectedTab = State(initialValue: .history)
        }
    }
    
    /// Computed tab items - Images tab is hidden until saveImages is enabled
    private var tabs: [TabItem] {
        var items: [TabItem] = [
            TabItem(id: TabIdentifier.history.rawValue, title: "History", icon: "doc.on.clipboard")
        ]
        
        // Add Images tab if saveImages is enabled (always exists, just hidden)
        if preferences.saveImages {
            items.append(TabItem(id: TabIdentifier.images.rawValue, title: "Images", icon: "photo"))
        }
        
        // Settings is always last
        items.append(TabItem(id: TabIdentifier.settings.rawValue, title: "Settings", icon: "gearshape"))
        
        return items
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab content area (no inner container)
            Group {
                switch selectedTab {
                case .history:
                    HistoryView(store: store)
                case .images:
                    if preferences.saveImages {
                        ImagesView(store: store)
                    } else {
                        // If images tab was selected but saveImages is now disabled, show settings
                        SettingsView(preferences: preferences)
                            .onAppear {
                                selectedTab = .settings
                            }
                    }
                case .settings:
                    SettingsView(preferences: preferences)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Reusable tab bar component (only shows visible tabs)
            TabBar(items: tabs, selectedTab: Binding(
                get: { selectedTab.rawValue },
                set: { newValue in
                    if let tab = TabIdentifier(rawValue: newValue) {
                        selectedTab = tab
                        // Persist tab selection to UserDefaults
                        UserDefaults.standard.set(newValue, forKey: selectedTabKey)
                    }
                }
            ))
        }
        .frame(width: 420, height: 480)
    }
}

