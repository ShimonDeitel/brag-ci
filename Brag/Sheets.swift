import SwiftUI

enum BragSheet: Identifiable {
    case addEntry
    case editEntry(BragEntry)
    case summary
    case paywall

    var id: String {
        switch self {
        case .addEntry: return "add"
        case .editEntry(let e): return "edit-\(e.id)"
        case .summary: return "summary"
        case .paywall: return "paywall"
        }
    }
}

struct EntryFormView: View {
    @EnvironmentObject private var store: BragStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: BragEntry?

    @State private var date: Date
    @State private var text: String
    @State private var impact: ImpactLevel

    init(existing: BragEntry?) {
        self.existing = existing
        _date = State(initialValue: existing?.date ?? Date())
        _text = State(initialValue: existing?.text ?? "")
        _impact = State(initialValue: existing?.impact ?? .medium)
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Accomplishment") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("What did you get done?", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("entryTextField")
                    Picker("Impact", selection: $impact) {
                        ForEach(ImpactLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .accessibilityIdentifier("impactPicker")
                }

                if isEditing {
                    Section {
                        Button("Delete Entry", role: .destructive) {
                            if let existing {
                                store.deleteEntry(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteEntryButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Entry" : "Log a Win")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if isEditing, let existing {
                            store.updateEntry(existing.id, date: date, text: text, impact: impact)
                        } else {
                            store.addEntry(date: date, text: text, impact: impact, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("saveEntryButton")
                }
            }
        }
    }
}

struct SummaryView: View {
    @EnvironmentObject private var store: BragStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(store.summaryText().isEmpty ? "No accomplishments logged yet." : store.summaryText())
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(BGTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .accessibilityIdentifier("summaryText")
            }
            .navigationTitle("Review Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: store.summaryText().isEmpty ? "No accomplishments logged yet." : store.summaryText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
