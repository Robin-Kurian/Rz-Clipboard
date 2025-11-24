import Foundation
import AppKit

/// Manages Launch Agent for auto-starting app on login
/// Creates and removes Launch Agent plist file in ~/Library/LaunchAgents/
@MainActor
final class LaunchAgentManager {
    // MARK: - Properties
    /// Bundle identifier for the app
    private let bundleId = "com.robin.rzclipboard"
    
    /// Launch Agent plist file URL
    private var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(bundleId).plist")
    }
    
    /// Get the app bundle's executable path
    private var appExecutablePath: String? {
        // Check if running as app bundle
        if let appBundlePath = Bundle.main.bundlePath as String?,
           !appBundlePath.isEmpty,
           appBundlePath.hasSuffix(".app") {
            // Running as app bundle - use Contents/MacOS/executable
            let executableName = Bundle.main.executableURL?.lastPathComponent ?? "rzclipboard"
            return "\(appBundlePath)/Contents/MacOS/\(executableName)"
        }
        
        // Running from command line (swift run) - use current executable
        if let executablePath = Bundle.main.executablePath {
            return executablePath
        }
        
        return nil
    }
    
    // MARK: - Public Methods
    /// Enable auto-start on login by creating Launch Agent plist file
    /// IMPORTANT: We do NOT call launchctl load here because:
    /// 1. Calling launchctl load with RunAtLoad=true would execute the app immediately
    /// 2. This would create a duplicate instance that gets killed by our singleton check
    /// 3. macOS will automatically load the agent on next login - no manual loading needed
    /// - Returns: true if successful, false otherwise
    func enableAutoStart() -> Bool {
        guard let executablePath = appExecutablePath else {
            print("⚠️  Could not determine app executable path")
            return false
        }
        
        // Ensure LaunchAgents directory exists
        let launchAgentsDir = launchAgentURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: launchAgentsDir.path) {
            try? FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
        }
        
        // Create Launch Agent plist file
        // DO NOT call launchctl load - macOS will load it automatically on next login
        // Calling load now would trigger RunAtLoad immediately and create a duplicate instance
        let plistContent = createLaunchAgentPlist(executablePath: executablePath)
        
        do {
            try plistContent.write(to: launchAgentURL, atomically: true, encoding: .utf8)
            // Success - plist created, will be loaded automatically on next login
            // No need to call launchctl load - that would trigger immediate execution
            return true
        } catch {
            print("❌ Failed to create Launch Agent: \(error)")
            return false
        }
    }
    
    /// Disable auto-start on login by removing Launch Agent
    /// Unloads the agent if it's currently loaded, then removes the plist file
    /// - Returns: true if successful, false otherwise
    func disableAutoStart() -> Bool {
        // Unload the Launch Agent if it exists and is loaded
        // This prevents it from running on next login
        if FileManager.default.fileExists(atPath: launchAgentURL.path) {
            let process = Process()
            process.launchPath = "/bin/launchctl"
            process.arguments = ["unload", launchAgentURL.path]
            // Ignore errors - agent might not be loaded
            try? process.run()
            process.waitUntilExit()
        }
        
        // Remove the plist file
        do {
            if FileManager.default.fileExists(atPath: launchAgentURL.path) {
                try FileManager.default.removeItem(at: launchAgentURL)
            }
            return true
        } catch {
            print("❌ Failed to remove Launch Agent: \(error)")
            return false
        }
    }
    
    /// Check if auto-start is currently enabled
    /// - Returns: true if Launch Agent plist file exists
    func isAutoStartEnabled() -> Bool {
        return FileManager.default.fileExists(atPath: launchAgentURL.path)
    }
    
    // MARK: - Private Methods
    /// Create Launch Agent plist content
    /// - Parameter executablePath: Path to the app executable
    /// - Returns: XML plist content as string
    private func createLaunchAgentPlist(executablePath: String) -> String {
        return """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>\(bundleId)</string>
    <key>ProgramArguments</key>
    <array>
        <string>\(executablePath)</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
"""
    }
}

