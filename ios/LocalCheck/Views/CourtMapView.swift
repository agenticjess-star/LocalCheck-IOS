import SwiftUI
import MapKit

struct CourtMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCourt: Court? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    ForEach(appState.courts) { court in
                        Annotation(court.name, coordinate: court.coordinate) {
                            courtPin(court: court)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCourt = court
                                    }
                                }
                        }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))

                if let court = selectedCourt {
                    VStack {
                        Spacer()
                        courtDetailCard(court: court)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Courts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.tint(Theme.orange)
                }
            }
            .task {
                await appState.loadMap()
            }
        }
    }

    private func courtPin(court: Court) -> some View {
        ZStack {
            Circle()
                .fill(court.isConfirmed ? Theme.orange : Theme.unconfirmed)
                .frame(width: 30, height: 30)
            Image(systemName: court.sportType.icon)
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
        .overlay {
            if court.id == appState.localCourt?.id {
                Circle()
                    .stroke(Theme.green, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private func courtDetailCard(court: Court) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: court.sportType.icon)
                            .foregroundStyle(Theme.orange)
                        Text(court.name)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text(court.address)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button { withAnimation { selectedCourt = nil } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            HStack(spacing: 16) {
                Label("\(court.localPlayerCount) locals", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Label(court.isConfirmed ? "Confirmed" : "Unconfirmed", systemImage: court.isConfirmed ? "checkmark.seal.fill" : "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(court.isConfirmed ? Theme.green : Theme.textTertiary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
