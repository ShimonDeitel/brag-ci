import Foundation
import Combine

@MainActor
final class BragStore: ObservableObject {
    @Published private(set) var entries: [BragEntry] = []

    static let freeEntryLimit = 10

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("brag_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
    }

    var impactScore: Int {
        ImpactScore.compute(entries: entries)
    }

    var monthlyImpactScore: Int {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        return ImpactScore.compute(entries: entries, since: cutoff)
    }

    func canAddEntry(isPro: Bool) -> Bool {
        isPro || entries.count < Self.freeEntryLimit
    }

    @discardableResult
    func addEntry(date: Date, text: String, impact: ImpactLevel, isPro: Bool) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddEntry(isPro: isPro) else { return false }
        entries.append(BragEntry(date: date, text: trimmed, impact: impact))
        save()
        return true
    }

    func updateEntry(_ id: UUID, date: Date, text: String, impact: ImpactLevel) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].date = date
        entries[idx].text = trimmed
        entries[idx].impact = impact
        save()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func summaryText() -> String {
        ImpactScore.summary(entries: entries)
    }

    func deleteAllData() {
        entries = []
        save()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var entries: [BragEntry]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            entries = decoded.entries
        }
    }

    private func save() {
        let snapshot = Snapshot(entries: entries)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
