import SwiftUI

struct CreateGameSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let onCreated: () -> Void

    @State private var title: String = ""
    @State private var selectedCourtID: String = ""
    @State private var date: Date = Date().addingTimeInterval(3600)
    @State private var maxPlayers: Int = 10
    @State private var isOpenInvite: Bool = true
    @State private var note: String = ""
    @State private var isSubmitting: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Game Details") {
                    TextField("Title (e.g. Evening 5v5)", text: $title)
                        .foregroundStyle(Theme.textPrimary)
                    Picker("Court", selection: $selectedCourtID) {
                        Text("Select a Court").tag("")
                        ForEach(appState.courts) { court in
                            Text(court.name).tag(court.id)
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)
                    DatePicker("Date & Time", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .foregroundStyle(Theme.textPrimary)
                    Stepper("Max Players: \(maxPlayers)", value: $maxPlayers, in: 2...20)
                        .foregroundStyle(Theme.textPrimary)
                    Toggle("Open Invite", isOn: $isOpenInvite)
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.orange)
                }
                .listRowBackground(Theme.surfaceCard)

                Section("Note (optional)") {
                    TextField("Add a note for players", text: $note, axis: .vertical)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(minHeight: 60, alignment: .topLeading)
                }
                .listRowBackground(Theme.surfaceCard)

                Section {
                    Button {
                        isSubmitting = true
                        Task {
                            do {
                                try await SupabaseService.shared.createScheduledGame(
                                    courtID: selectedCourtID,
                                    title: title,
                                    note: note.isEmpty ? nil : note,
                                    startTime: date,
                                    maxPlayers: maxPlayers,
                                    isOpenInvite: isOpenInvite
                                )
                                onCreated()
                                dismiss()
                            } catch {
                                appState.errorMessage = error.localizedDescription
                                isSubmitting = false
                            }
                        }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text(isSubmitting ? "Creating..." : "Create Game")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .disabled(title.isEmpty || selectedCourtID.isEmpty || isSubmitting)
                    .listRowBackground(title.isEmpty || selectedCourtID.isEmpty ? Theme.surfaceCard : Theme.orange)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.surfaceElevated)
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Theme.textSecondary)
                }
            }
            .task {
                await appState.loadMap() // loads courts list for the picker
            }
        }
    }
}
