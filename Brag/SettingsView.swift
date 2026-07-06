import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BragStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("brag_weekly_reminder") private var weeklyReminder: Bool = true
    @State private var activeSheet: BragSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Remind me weekly to log a win", isOn: $weeklyReminder)
                        .accessibilityIdentifier("reminderToggle")
                }

                Section("Overview") {
                    HStack {
                        Text("Entries Logged")
                        Spacer()
                        Text("\(store.entries.count)")
                            .foregroundStyle(BGTheme.inkFaded)
                    }
                    HStack {
                        Text("All-Time Impact Score")
                        Spacer()
                        Text("\(store.impactScore)")
                            .foregroundStyle(BGTheme.inkFaded)
                    }
                }

                Section("Brag Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(BGTheme.brass)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(BGTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/brag-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(BGTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all accomplishments?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BragStore())
        .environmentObject(PurchaseManager())
}
