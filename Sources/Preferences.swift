import SwiftUI

final class PreferencesModel: ObservableObject {
    @Published var historyLimit: Int {
        didSet {
            let clamped = PreferencesModel.clampedHistoryLimit(historyLimit)
            if clamped != historyLimit {
                historyLimit = clamped
                return
            }
            defaults.set(clamped, forKey: Keys.historyLimit.rawValue)
        }
    }

    @Published var pollInterval: Double {
        didSet {
            let clamped = PreferencesModel.clampedPollInterval(pollInterval)
            if clamped != pollInterval {
                pollInterval = clamped
                return
            }
            defaults.set(clamped, forKey: Keys.pollInterval.rawValue)
        }
    }

    @Published var preventDuplicates: Bool {
        didSet {
            defaults.set(preventDuplicates, forKey: Keys.preventDuplicates.rawValue)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedHistoryLimit = defaults.object(forKey: Keys.historyLimit.rawValue) as? Int ?? 25
        let storedInterval = defaults.object(forKey: Keys.pollInterval.rawValue) as? Double ?? 0.8
        let storedPreventDupes = defaults.object(forKey: Keys.preventDuplicates.rawValue) as? Bool ?? true

        self.historyLimit = PreferencesModel.clampedHistoryLimit(storedHistoryLimit)
        self.pollInterval = PreferencesModel.clampedPollInterval(storedInterval)
        self.preventDuplicates = storedPreventDupes
    }

    func resetToDefaults() {
        historyLimit = 25
        pollInterval = 0.8
        preventDuplicates = true
    }

    private static func clampedHistoryLimit(_ value: Int) -> Int {
        min(max(value, 10), 100)
    }

    private static func clampedPollInterval(_ value: Double) -> Double {
        min(max(value, 0.3), 2.0)
    }

    private enum Keys: String {
        case historyLimit = "pref.historyLimit"
        case pollInterval = "pref.pollInterval"
        case preventDuplicates = "pref.preventDuplicates"
    }
}

struct SettingsView: View {
    @ObservedObject var preferences: PreferencesModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title3)
                    .bold()
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            Divider()

            GroupBox("History limit") {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper(value: $preferences.historyLimit, in: 10...100, step: 5) {
                        Text("\(preferences.historyLimit) items")
                    }
                    Text("Controls how many recent clips are retained.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox("Clipboard polling") {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $preferences.pollInterval, in: 0.3...2.0, step: 0.1) {
                        Text("Interval")
                    }
                    HStack {
                        Text("\(preferences.pollInterval, specifier: "%.1f")s between checks")
                        Spacer()
                        Text("Lower = faster")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GroupBox {
                Toggle("Skip duplicate entries", isOn: $preferences.preventDuplicates)
                Text("Prevents identical clips from being saved multiple times.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Reset to defaults") {
                preferences.resetToDefaults()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(width: 360, height: 420)
    }
}

