import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled: Bool = true
    @State private var checkInReminders: Bool = true
    @State private var gameAlerts: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Check-In Reminders", isOn: $checkInReminders)
                    Toggle("Game Alerts", isOn: $gameAlerts)
                }
                .listRowBackground(Theme.surfaceCard)
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.orange)

                Section("Account") {
                    Button("Edit Profile") { }
                        .foregroundStyle(Theme.textPrimary)
                    Button("Change Local Court") { }
                        .foregroundStyle(Theme.textPrimary)
                }
                .listRowBackground(Theme.surfaceCard)

                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .listRowBackground(Theme.surfaceCard)

                Section {
                    Button("Sign Out", role: .destructive) { }
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
                    Button("Done") { dismiss() }
                        .tint(Theme.orange)
                }
            }
        }
    }
}
