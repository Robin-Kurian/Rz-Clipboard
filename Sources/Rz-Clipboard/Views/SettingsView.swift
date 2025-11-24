import SwiftUI
import AppKit

/// Settings view for configuring clipboard history preferences
/// All changes are automatically persisted to UserDefaults
struct SettingsView: View {
    // MARK: - Properties
    /// Preferences model for reading and updating settings
    @ObservedObject var preferences: PreferencesModel

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header
                Divider()
                
                // Settings sections
                historyLimitSection
                pollingSection
                duplicatesSection
                imagesSection
                autoStartSection
                
                Spacer()
                
                // Bottom buttons: Reset on left, Quit on right
                bottomButtons
            }
            .padding(8)
        }
    }

    // MARK: - Header
    /// Settings page title
    private var header: some View {
        Text("Settings")
            .font(.title3)
            .bold()
    }

    // MARK: - Settings Sections
    /// History limit configuration section
    /// Controls maximum number of recent (non-pinned) entries to keep
    private var historyLimitSection: some View {
        GroupBox("History limit") {
            VStack(alignment: .leading, spacing: 8) {
                // Stepper for adjusting limit (10-100, step 5)
                Stepper(value: $preferences.historyLimit, in: 10...100, step: 5) {
                    Text("\(preferences.historyLimit) items")
                }
                // Help text explaining the setting
                Text("Controls how many recent clips are retained.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Clipboard polling interval configuration section
    /// Controls how frequently the app checks for clipboard changes
    private var pollingSection: some View {
        GroupBox("Clipboard polling") {
            VStack(alignment: .leading, spacing: 8) {
                // Slider for adjusting interval (0.3-2.0 seconds, step 0.1)
                Slider(value: $preferences.pollInterval, in: 0.3...2.0, step: 0.1) {
                    Text("Interval")
                }
                HStack {
                    // Display current interval value
                    Text("\(preferences.pollInterval, specifier: "%.1f")s between checks")
                    Spacer()
                    // Help text
                    Text("Lower = faster")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Duplicate prevention configuration section
    /// Controls whether identical clipboard content should be skipped
    private var duplicatesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                // Toggle for enabling/disabling duplicate prevention
                Toggle("Skip duplicate entries", isOn: $preferences.preventDuplicates)
                // Help text explaining the setting
                Text("Prevents identical clips from being saved multiple times.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// Image saving configuration section
    /// Controls whether images from clipboard should be captured
    private var imagesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                // Toggle for enabling/disabling image saving
                Toggle("Save images", isOn: $preferences.saveImages)
                // Help text explaining the setting
                Text("Captures images copied to clipboard and shows them in Images tab.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// Auto-start on login configuration section
    /// Controls whether app should start automatically on system login
    private var autoStartSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                // Toggle for enabling/disabling auto-start
                Toggle("Start at login", isOn: $preferences.autoStartOnLogin)
                // Help text explaining the setting
                Text("Automatically launch the app when you log in to your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions
    /// Bottom buttons container with Reset (left) and Quit (right)
    private var bottomButtons: some View {
        HStack {
            // Reset button on the left
            Button("Reset to defaults") {
                preferences.resetToDefaults()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // Quit button on the right
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
        }
    }
}

