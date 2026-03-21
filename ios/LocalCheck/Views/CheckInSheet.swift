import SwiftUI

struct CheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isCheckedIn: Bool
    let onCheckIn: (String?) -> Void
    let onCheckOut: () -> Void
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isCheckedIn {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.green)
                        Text("You're checked in!")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.textPrimary)
                        Text("Other players can see you're at the court.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button {
                            onCheckOut()
                            dismiss()
                        } label: {
                            Text("Check Out")
                                .font(.headline)
                                .foregroundStyle(Theme.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Theme.red.opacity(0.15), in: .rect(cornerRadius: 12))
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.orange)
                        Text("Check In")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.textPrimary)
                        Text("Let others know you're at the court.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("Add a note (optional)", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Theme.surfaceCard)
                            .clipShape(.rect(cornerRadius: 10))
                            .foregroundStyle(Theme.textPrimary)
                        Button {
                            onCheckIn(note.isEmpty ? nil : note)
                            dismiss()
                        } label: {
                            Text("Check In Now")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Theme.orange, in: .rect(cornerRadius: 12))
                        }
                    }
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle(isCheckedIn ? "Status" : "Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Theme.textSecondary)
                }
            }
        }
    }
}
