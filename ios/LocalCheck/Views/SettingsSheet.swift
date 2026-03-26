import SwiftUI

struct SettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var notificationsEnabled: Bool = true
    @State private var checkInReminders: Bool = true
    @State private var gameAlerts: Bool = true
    @State private var isSigningOut: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let player = appState.currentPlayer {
                        LabeledContent("Player") {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(player.displayName)
                                Text("@\(player.username)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }

                    LabeledContent("Email") {
                        Text(appState.currentUserEmail ?? "Unavailable")
                            .foregroundStyle(Theme.textSecondary)
                    }

                    LabeledContent("Local Court") {
                        Text(appState.localCourt?.name ?? "Not set")
                            .foregroundStyle(appState.localCourt == nil ? Theme.textTertiary : Theme.textPrimary)
                    }
                }
                .listRowBackground(Theme.surfaceCard)
                .foregroundStyle(Theme.textPrimary)

                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Check-In Reminders", isOn: $checkInReminders)
                    Toggle("Game Alerts", isOn: $gameAlerts)
                }
                .listRowBackground(Theme.surfaceCard)
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.orange)

                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text("Email and password is the active preview path. Apple sign-in can be switched on closer to launch.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.surfaceCard)

                Section {
                    Button(role: .destructive) {
                        isSigningOut = true
                        Task {
                            await appState.signOut()
                            isSigningOut = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSigningOut {
                                ProgressView()
                            } else {
                                Text("Sign Out")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSigningOut)
                }
                .listRowBackground(Theme.surfaceCard)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.surfaceElevated)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(Theme.orange)
                }
            }
        }
    }
}
