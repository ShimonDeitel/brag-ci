import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: BragStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: BragSheet?

    private var recentEntries: [BragEntry] {
        store.entries.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BGTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        impactCard
                        entryList
                    }
                    .padding()
                }
            }
            .navigationTitle("Brag")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeSheet = .summary
                    } label: {
                        Image(systemName: "doc.text.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("summaryButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if store.canAddEntry(isPro: purchases.isPro) {
                            activeSheet = .addEntry
                        } else {
                            activeSheet = .paywall
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("addEntryButton")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addEntry:
                    EntryFormView(existing: nil)
                case .editEntry(let entry):
                    EntryFormView(existing: entry)
                case .summary:
                    SummaryView()
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    /// Quirky signature feature: an "Impact Score" gauge — weighted sum of
    /// logged wins over the last 30 days, framed like a review-readiness
    /// meter that fills up as review season approaches.
    private var impactCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Impact Score (30 days)")
                        .font(.caption)
                        .foregroundStyle(BGTheme.inkFaded)
                    Text("\(store.monthlyImpactScore)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(BGTheme.brass)
                        .accessibilityIdentifier("impactScoreValue")
                }
                Spacer()
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(BGTheme.brassBright)
            }
            HStack {
                Text("All-time: \(store.impactScore)")
                    .font(.caption)
                    .foregroundStyle(BGTheme.inkFaded)
                Spacer()
            }
        }
        .padding(18)
        .background(BGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(BGTheme.brass, lineWidth: 2))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var entryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Wins")
                .font(BGTheme.headlineFont)
                .foregroundStyle(BGTheme.ink)

            if recentEntries.isEmpty {
                Text("No accomplishments logged yet. Tap + to add one.")
                    .font(.subheadline)
                    .foregroundStyle(BGTheme.inkFaded)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(recentEntries) { entry in
                    Button {
                        activeSheet = .editEntry(entry)
                    } label: {
                        entryRow(entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func entryRow(_ entry: BragEntry) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .font(.subheadline)
                    .foregroundStyle(BGTheme.ink)
                    .multilineTextAlignment(.leading)
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(BGTheme.inkFaded)
            }
            Spacer()
            Text(entry.impact.rawValue)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(BGTheme.impactBlue.opacity(0.15))
                .foregroundStyle(BGTheme.impactBlue)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(BGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HomeView()
        .environmentObject(BragStore())
        .environmentObject(PurchaseManager())
}
