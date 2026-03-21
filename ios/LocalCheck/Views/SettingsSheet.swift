import SwiftUI

struct SettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var notificationsEnabled: Bool = true
    @State private var checkInReminders: Bool = true
    @State private var gameAlerts: Bool = true
    @State private var selectedUserID: String = ""
    @State private var selectedCourtID: String = ""
    @State private var isSwitchingUser: Bool = false
    @State private var isSavingCourt: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let player = appState.currentPlayer {
                        LabeledContent("Active Player") {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(player.displayName)
                                Text("@\(player.username)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
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

                Section("Development") {
                    Picker("Active Player", selection: $selectedUserID) {
                        ForEach(appState.players) { player in
                            Text("\(player.displayName) (@\(player.username))")
                                .tag(player.id)
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)

                    Button {
                        isSwitchingUser = true
                        Task {
                            await appState.switchCurrentUser(to: selectedUserID)
                            selectedCourtID = appState.localCourt?.id ?? appState.currentPlayer?.localCourtID ?? ""
                            isSwitchingUser = false
                        }
                    } label: {
                        HStack {
                            if isSwitchingUser {
                                ProgressView()
                            }
                            Text(isSwitchingUser ? "Switching..." : "Use Selected Player")
                        }
                    }
                    .disabled(
                        selectedUserID.isEmpty ||
                        selectedUserID == appState.currentUserID ||
                        isSwitchingUser
                    )

                    Picker("Local Court", selection: $selectedCourtID) {
                        Text("Select a Court").tag("")
                        ForEach(appState.courts) { court in
                            Text(court.name).tag(court.id)
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)

                    Button {
                        isSavingCourt = true
                        Task {
                            await appState.updateLocalCourt(courtID: selectedCourtID)
                            isSavingCourt = false
                        }
                    } label: {
                        HStack {
                            if isSavingCourt {
                                ProgressView()
                            }
                            Text(isSavingCourt ? "Saving..." : "Save Local Court")
                        }
                    }
                    .disabled(
                        selectedCourtID.isEmpty ||
                        selectedCourtID == (appState.localCourt?.id ?? appState.currentPlayer?.localCourtID ?? "") ||
                        isSavingCourt
                    )
                }
                .listRowBackground(Theme.surfaceCard)
                .foregroundStyle(Theme.textPrimary)

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
                    Text("Supabase Auth and Sign in with Apple are still pending. These controls let you test the live backend with real profile data in the meantime.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
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
            .task {
                if appState.players.isEmpty {
                    await appState.loadRankings()
                }
                if appState.courts.isEmpty {
                    await appState.loadMap()
                }
                selectedUserID = appState.currentUserID
                selectedCourtID = appState.localCourt?.id ?? appState.currentPlayer?.localCourtID ?? ""
            }
        }
    }
}
