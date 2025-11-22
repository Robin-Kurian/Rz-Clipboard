import SwiftUI

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
                
                Spacer()
                
                // Reset button at bottom
                resetButton
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

    // MARK: - Actions
    /// Reset all preferences to default values
    private var resetButton: some View {
        Button("Reset to defaults") {
            preferences.resetToDefaults()
        }
        .buttonStyle(.bordered)
    }
}

