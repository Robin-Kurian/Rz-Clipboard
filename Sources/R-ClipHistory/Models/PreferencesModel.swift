import SwiftUI
import Combine

/// Manages user preferences for clipboard history app
/// All preferences are automatically persisted to UserDefaults and validated
/// Changes trigger Combine publishers for reactive updates
final class PreferencesModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Maximum number of recent (non-pinned) entries to keep in memory
    /// Range: 10-100 items, clamped automatically
    /// Stored in UserDefaults key: "pref.historyLimit"
    @Published var historyLimit: Int {
        didSet {
            // Clamp value to valid range before saving
            let clamped = Self.clampedHistoryLimit(historyLimit)
            if clamped != historyLimit {
                // If value was out of range, update to clamped value (triggers didSet again)
                historyLimit = clamped
                return
            }
            // Save to UserDefaults only if value is valid
            defaults.set(clamped, forKey: Keys.historyLimit.rawValue)
        }
    }

    /// Interval in seconds between clipboard polling checks
    /// Range: 0.3-2.0 seconds, clamped automatically
    /// Lower values = faster detection but more CPU usage
    /// Stored in UserDefaults key: "pref.pollInterval"
    @Published var pollInterval: Double {
        didSet {
            // Clamp value to valid range before saving
            let clamped = Self.clampedPollInterval(pollInterval)
            if clamped != pollInterval {
                // If value was out of range, update to clamped value (triggers didSet again)
                pollInterval = clamped
                return
            }
            // Save to UserDefaults only if value is valid
            defaults.set(clamped, forKey: Keys.pollInterval.rawValue)
        }
    }

    /// Whether to skip adding duplicate clipboard entries
    /// If true, identical content won't be added to history
    /// Stored in UserDefaults key: "pref.preventDuplicates"
    @Published var preventDuplicates: Bool {
        didSet {
            // Immediately persist boolean value
            defaults.set(preventDuplicates, forKey: Keys.preventDuplicates.rawValue)
        }
    }
    
    /// Whether to save and track images from clipboard
    /// If true, images copied to clipboard will be captured and stored
    /// Stored in UserDefaults key: "pref.saveImages"
    @Published var saveImages: Bool {
        didSet {
            // Immediately persist boolean value
            defaults.set(saveImages, forKey: Keys.saveImages.rawValue)
        }
    }

    // MARK: - Private Properties
    /// UserDefaults instance for persistence (defaults to .standard)
    private let defaults: UserDefaults

    // MARK: - Initialization
    /// Initialize preferences model, loading from UserDefaults or using defaults
    /// - Parameter defaults: UserDefaults instance (defaults to .standard)
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        // Load stored values or use defaults
        let storedHistoryLimit = defaults.object(forKey: Keys.historyLimit.rawValue) as? Int ?? 25
        let storedInterval = defaults.object(forKey: Keys.pollInterval.rawValue) as? Double ?? 0.8
        let storedPreventDupes = defaults.object(forKey: Keys.preventDuplicates.rawValue) as? Bool ?? true
        let storedSaveImages = defaults.object(forKey: Keys.saveImages.rawValue) as? Bool ?? false

        // Clamp loaded values to ensure they're in valid ranges
        self.historyLimit = Self.clampedHistoryLimit(storedHistoryLimit)
        self.pollInterval = Self.clampedPollInterval(storedInterval)
        self.preventDuplicates = storedPreventDupes
        self.saveImages = storedSaveImages
    }

    // MARK: - Public Methods
    /// Reset all preferences to their default values
    /// This will trigger didSet observers and save to UserDefaults
    func resetToDefaults() {
        historyLimit = 25
        pollInterval = 0.8
        preventDuplicates = true
        saveImages = false
    }

    // MARK: - Private Validation Methods
    /// Clamp history limit to valid range (10-100)
    /// - Parameter value: Input value to clamp
    /// - Returns: Clamped value between 10 and 100
    private static func clampedHistoryLimit(_ value: Int) -> Int {
        min(max(value, 10), 100)
    }

    /// Clamp poll interval to valid range (0.3-2.0 seconds)
    /// - Parameter value: Input value to clamp
    /// - Returns: Clamped value between 0.3 and 2.0
    private static func clampedPollInterval(_ value: Double) -> Double {
        min(max(value, 0.3), 2.0)
    }

    // MARK: - UserDefaults Keys
    /// UserDefaults keys for preference storage
    /// Using enum ensures type safety and prevents key typos
    private enum Keys: String {
        case historyLimit = "pref.historyLimit"
        case pollInterval = "pref.pollInterval"
        case preventDuplicates = "pref.preventDuplicates"
        case saveImages = "pref.saveImages"
    }
}

