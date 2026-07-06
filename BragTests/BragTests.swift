import XCTest
@testable import Brag

final class BragTests: XCTestCase {
    var store: BragStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = BragStore()
        store.deleteAllData()
    }

    @MainActor
    func testAddEntry() {
        let added = store.addEntry(date: Date(), text: "Shipped v2.0", impact: .big, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].text, "Shipped v2.0")
    }

    @MainActor
    func testAddEntryRejectsEmptyText() {
        let added = store.addEntry(date: Date(), text: "   ", impact: .small, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksExtraEntries() {
        for i in 0..<BragStore.freeEntryLimit {
            _ = store.addEntry(date: Date(), text: "Win \(i)", impact: .small, isPro: false)
        }
        XCTAssertFalse(store.canAddEntry(isPro: false))
        let blocked = store.addEntry(date: Date(), text: "Extra", impact: .small, isPro: false)
        XCTAssertFalse(blocked)
        XCTAssertEqual(store.entries.count, BragStore.freeEntryLimit)
    }

    @MainActor
    func testProAllowsUnlimitedEntries() {
        for i in 0..<(BragStore.freeEntryLimit + 4) {
            _ = store.addEntry(date: Date(), text: "Win \(i)", impact: .small, isPro: true)
        }
        XCTAssertEqual(store.entries.count, BragStore.freeEntryLimit + 4)
    }

    @MainActor
    func testUpdateEntry() {
        _ = store.addEntry(date: Date(), text: "Draft", impact: .small, isPro: false)
        let id = store.entries[0].id
        store.updateEntry(id, date: Date(), text: "Finalized", impact: .big)
        XCTAssertEqual(store.entries[0].text, "Finalized")
        XCTAssertEqual(store.entries[0].impact, .big)
    }

    @MainActor
    func testDeleteEntry() {
        _ = store.addEntry(date: Date(), text: "Temp", impact: .small, isPro: false)
        let id = store.entries[0].id
        store.deleteEntry(id)
        XCTAssertTrue(store.entries.isEmpty)
    }

    // MARK: - Impact score

    func testImpactWeights() {
        XCTAssertEqual(ImpactLevel.small.weight, 1)
        XCTAssertEqual(ImpactLevel.medium.weight, 3)
        XCTAssertEqual(ImpactLevel.big.weight, 5)
    }

    func testImpactScoreSumsWeights() {
        let entries = [
            BragEntry(text: "a", impact: .small),
            BragEntry(text: "b", impact: .medium),
            BragEntry(text: "c", impact: .big)
        ]
        XCTAssertEqual(ImpactScore.compute(entries: entries), 9)
    }

    func testImpactScoreFiltersBySinceDate() {
        let cal = Calendar.current
        let now = Date()
        let entries = [
            BragEntry(date: cal.date(byAdding: .day, value: -40, to: now)!, text: "old", impact: .big),
            BragEntry(date: now, text: "recent", impact: .small)
        ]
        let cutoff = cal.date(byAdding: .day, value: -30, to: now)!
        XCTAssertEqual(ImpactScore.compute(entries: entries, since: cutoff), 1)
    }

    func testSummaryOrdersByImpactDescending() {
        let entries = [
            BragEntry(text: "small win", impact: .small),
            BragEntry(text: "big win", impact: .big),
            BragEntry(text: "medium win", impact: .medium)
        ]
        let summary = ImpactScore.summary(entries: entries)
        let lines = summary.components(separatedBy: "\n")
        XCTAssertEqual(lines[0], "- big win")
        XCTAssertEqual(lines[1], "- medium win")
        XCTAssertEqual(lines[2], "- small win")
    }

    func testSummaryEmptyWhenNoEntries() {
        XCTAssertEqual(ImpactScore.summary(entries: []), "")
    }

    @MainActor
    func testMonthlyImpactScoreExcludesOldEntries() {
        let cal = Calendar.current
        let now = Date()
        _ = store.addEntry(date: cal.date(byAdding: .day, value: -45, to: now)!, text: "old", impact: .big, isPro: true)
        _ = store.addEntry(date: now, text: "new", impact: .small, isPro: true)
        XCTAssertEqual(store.monthlyImpactScore, 1)
        XCTAssertEqual(store.impactScore, 6)
    }
}
