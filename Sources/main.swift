import SwiftUI
import AppKit
import Combine

@main
struct RClipHistoryApp: App {
    @StateObject private var preferences: PreferencesModel
    @StateObject private var store: ClipboardHistoryStore

    init() {
        let prefs = PreferencesModel()
        _preferences = StateObject(wrappedValue: prefs)
        _store = StateObject(wrappedValue: ClipboardHistoryStore(preferences: prefs))
    }

    var body: some Scene {
        MenuBarExtra("R-ClipHistory", systemImage: "doc.on.clipboard.fill") {
            ClipboardHistoryView(store: store, preferences: preferences)
                .frame(width: 320, height: 360)
                .padding(12)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry] = []
    @Published private(set) var pinnedEntries: [ClipboardEntry] = []

    private let preferences: PreferencesModel
    private var changeCount: Int
    private var timer: Timer?
    private let pinnedStorageKey = "com.robin.rcliphistory.pinned"
    private var cancellables: Set<AnyCancellable> = []
    private lazy var pinnedFileURL: URL = {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("R-ClipHistory", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("pinned.json")
    }()

    init(preferences: PreferencesModel) {
        self.preferences = preferences
        self.changeCount = NSPasteboard.general.changeCount
        loadPinnedEntries()
        startPolling()
        bindPreferences()
    }

    func copyToClipboard(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.content, forType: .string)
        changeCount = pasteboard.changeCount
    }

    func clear() {
        entries.removeAll()
    }

    func togglePin(_ entry: ClipboardEntry) {
        entry.isPinned ? unpin(entry) : pin(entry)
    }

    private func pin(_ entry: ClipboardEntry) {
        guard !pinnedEntries.contains(where: { $0.id == entry.id }) else { return }
        var pinnedEntry = entry
        pinnedEntry.isPinned = true
        pinnedEntries.insert(pinnedEntry, at: 0)
        entries.removeAll { $0.id == entry.id }
        persistPinnedEntries()
    }

    private func unpin(_ entry: ClipboardEntry) {
        pinnedEntries.removeAll { $0.id == entry.id }
        var restoredEntry = entry
        restoredEntry.isPinned = false
        entries.insert(restoredEntry, at: 0)
        enforceHistoryLimit()
        persistPinnedEntries()
    }

    private func bindPreferences() {
        preferences.$historyLimit
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.enforceHistoryLimit()
            }
            .store(in: &cancellables)

        preferences.$pollInterval
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.startPolling()
            }
            .store(in: &cancellables)
    }

    private func startPolling() {
        timer?.invalidate()
        let interval = max(preferences.pollInterval, 0.3)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] _ in
            Task { await self?.captureClipboardChange() }
        })
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func captureClipboardChange() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount

        guard let newValue = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !newValue.isEmpty else { return }

        if preferences.preventDuplicates &&
            (entries.contains(where: { $0.content == newValue }) ||
             pinnedEntries.contains(where: { $0.content == newValue })) {
            return
        }

        let entry = ClipboardEntry(content: newValue, capturedAt: Date())
        entries.insert(entry, at: 0)
        enforceHistoryLimit()
    }

    private func enforceHistoryLimit() {
        let limit = preferences.historyLimit
        if entries.count > limit {
            entries.removeLast(entries.count - limit)
        }
    }

    private func loadPinnedEntries() {
        if let data = try? Data(contentsOf: pinnedFileURL) {
            decodePinnedEntries(from: data)
            return
        }

        // Fallback for older builds that used UserDefaults.
        if let legacyData = UserDefaults.standard.data(forKey: pinnedStorageKey) {
            decodePinnedEntries(from: legacyData)
            persistPinnedEntries()
            UserDefaults.standard.removeObject(forKey: pinnedStorageKey)
        }
    }

    private func decodePinnedEntries(from data: Data) {
        guard let decoded = try? JSONDecoder().decode([ClipboardEntry].self, from: data) else { return }
        pinnedEntries = decoded.map {
            var entry = $0
            entry.isPinned = true
            return entry
        }
    }

    private func persistPinnedEntries() {
        guard let data = try? JSONEncoder().encode(pinnedEntries) else { return }
        try? data.write(to: pinnedFileURL, options: [.atomic])
    }
}

struct ClipboardEntry: Identifiable, Codable {
    var id: UUID
    let content: String
    let capturedAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), content: String, capturedAt: Date, isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
        self.isPinned = isPinned
    }
}

struct ClipboardHistoryView: View {
    @ObservedObject var store: ClipboardHistoryStore
    @ObservedObject var preferences: PreferencesModel
    @State private var isShowingSettings = false
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            header
            Divider()
            historyList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(preferences: preferences)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .imageScale(.medium)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                    )
            }
            .buttonStyle(.plain)
            .help("Settings")

            VStack(alignment: .leading, spacing: 2) {
                Text("R-ClipHistory")
                    .font(.headline)
                Text("NB: Pinned items wont be purged!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Clear Recent", role: .destructive) {
                store.clear()
            }
            .disabled(store.entries.isEmpty)
        }
    }

    @ViewBuilder
    private var historyList: some View {
        if store.entries.isEmpty && store.pinnedEntries.isEmpty {
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
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !store.pinnedEntries.isEmpty {
                        sectionLabel("Pinned")
                        VStack(spacing: 8) {
                            ForEach(store.pinnedEntries) { entry in
                                ClipboardRow(
                                    entry: entry,
                                    copyAction: { store.copyToClipboard(entry) },
                                    pinAction: { store.togglePin(entry) },
                                    relativeTime: dateFormatter.localizedString(for: entry.capturedAt, relativeTo: Date())
                                )
                            }
                        }
                    }

                    if !store.entries.isEmpty {
                        sectionLabel("Recent")
                        VStack(spacing: 8) {
                            ForEach(store.entries) { entry in
                                ClipboardRow(
                                    entry: entry,
                                    copyAction: { store.copyToClipboard(entry) },
                                    pinAction: { store.togglePin(entry) },
                                    relativeTime: dateFormatter.localizedString(for: entry.capturedAt, relativeTo: Date())
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }
}

struct ClipboardRow: View {
    let entry: ClipboardEntry
    let copyAction: () -> Void
    let pinAction: () -> Void
    let relativeTime: String
    @State private var didCopyRecently = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.content)
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Label(relativeTime, systemImage: entry.isPinned ? "pin.fill" : "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Label(didCopyRecently ? "Copied" : "Tap to copy", systemImage: didCopyRecently ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(didCopyRecently ? .green : .secondary)
                Button {
                    pinAction()
                } label: {
                    Label(entry.isPinned ? "Unpin" : "Pin", systemImage: entry.isPinned ? "pin.slash" : "pin")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isHovering ? 0.2 : 0.05), radius: isHovering ? 6 : 2, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            copyAction()
            didCopyRecently = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                didCopyRecently = false
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut(duration: 0.12), value: isHovering)
    }
}
