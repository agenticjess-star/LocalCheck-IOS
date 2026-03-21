import SwiftUI

struct PostToCourtSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onPost: (String) -> Void
    @State private var content: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("What's happening at the court?", text: $content, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .frame(minHeight: 100, alignment: .topLeading)
                    .background(Theme.surfaceCard)
                    .clipShape(.rect(cornerRadius: 12))
                    .foregroundStyle(Theme.textPrimary)

                Button {
                    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    onPost(content)
                    dismiss()
                } label: {
                    Text("Post")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.surfaceCard : Theme.orange, in: .rect(cornerRadius: 12))
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Post to Court")
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
