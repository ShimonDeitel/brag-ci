import Foundation

/// Category tag for a brag entry, used for filtering + the quirky
/// "impact meter" that weights entries when generating a review summary.
enum ImpactLevel: String, Codable, CaseIterable, Identifiable {
    case small = "Small Win"
    case medium = "Solid Contribution"
    case big = "Major Impact"

    var id: String { rawValue }

    var weight: Int {
        switch self {
        case .small: return 1
        case .medium: return 3
        case .big: return 5
        }
    }
}

/// A single work accomplishment entry.
struct BragEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var text: String
    var impact: ImpactLevel

    init(id: UUID = UUID(), date: Date = Date(), text: String, impact: ImpactLevel = .medium) {
        self.id = id
        self.date = date
        self.text = text
        self.impact = impact
    }
}

/// Quirky signature feature: an "Impact Score" for a date range — the sum
/// of impact weights, framed like a review-season readiness gauge.
enum ImpactScore {
    static func compute(entries: [BragEntry], since: Date? = nil) -> Int {
        let filtered = since.map { cutoff in entries.filter { $0.date >= cutoff } } ?? entries
        return filtered.reduce(0) { $0 + $1.impact.weight }
    }

    /// Generates a simple bullet-point summary suitable for pasting into a
    /// performance review or resume update, most impactful entries first.
    static func summary(entries: [BragEntry]) -> String {
        let sorted = entries.sorted { $0.impact.weight > $1.impact.weight || ($0.impact.weight == $1.impact.weight && $0.date > $1.date) }
        return sorted.map { "- \($0.text)" }.joined(separator: "\n")
    }
}
