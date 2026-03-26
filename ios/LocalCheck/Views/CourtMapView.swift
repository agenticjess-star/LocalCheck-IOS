import SwiftUI
import MapKit
import CoreLocation

struct CourtMapView: View {
    private static let fallbackRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var onboardingMode: Bool = false

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCourt: Court? = nil
    @State private var showAddCourt: Bool = false
    @State private var loadFailed: Bool = false
    @State private var locationManager = CLLocationManager()

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    UserAnnotation()

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

                VStack {
                    if onboardingMode {
                        onboardingBanner
                    }

                    Spacer()

                    if loadFailed && appState.courts.isEmpty {
                        networkErrorCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let court = selectedCourt {
                        courtDetailCard(court: court)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if onboardingMode {
                        onboardingEmptyState
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(onboardingMode ? "Set Local Court" : "Courts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if onboardingMode {
                        Button("Skip for Now") {
                            appState.skipCourtOnboarding()
                        }
                        .tint(Theme.textSecondary)
                    } else {
                        Button("Done") { dismiss() }.tint(Theme.orange)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Court", systemImage: "plus") {
                        showAddCourt = true
                    }
                    .tint(Theme.orange)
                }
            }
            .task {
                locationManager.requestWhenInUseAuthorization()

                await appState.loadMap()
                loadFailed = appState.errorMessage != nil && appState.courts.isEmpty

                if let localCourt = appState.localCourt {
                    position = .region(
                        MKCoordinateRegion(
                            center: localCourt.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                        )
                    )
                } else if let firstCourt = appState.courts.first {
                    position = .region(
                        MKCoordinateRegion(
                            center: firstCourt.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                        )
                    )
                } else {
                    position = .userLocation(fallback: .region(Self.fallbackRegion))
                }
            }
            .sheet(isPresented: $showAddCourt) {
                AddCourtSheet { court in
                    selectedCourt = court
                    position = .region(
                        MKCoordinateRegion(
                            center: court.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.surfaceElevated)
            }
        }
    }

    private var onboardingBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose the court your local community revolves around.")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Tap an existing pin or add a new court so Home, Profile, and your local feed have context.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var onboardingEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No court selected yet")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Tap a court pin on the map, or add a new one and we'll make it your local court right away.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 12) {
                Button("Add New Court", systemImage: "plus.circle.fill") {
                    showAddCourt = true
                }
                .tint(Theme.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var networkErrorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(Theme.orange)
                Text("Couldn't load courts")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("Check your connection and try again, or add a court manually.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 12) {
                Button("Retry") {
                    loadFailed = false
                    Task { await appState.loadMap() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.orange)

                Button("Add Court Instead") {
                    showAddCourt = true
                }
                .tint(Theme.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
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
            Button {
                Task {
                    await appState.updateLocalCourt(courtID: court.id)
                }
            } label: {
                Text(court.id == appState.localCourt?.id ? "Current Local Court" : "Set as Local Court")
                    .font(.subheadline.bold())
                    .foregroundStyle(court.id == appState.localCourt?.id ? Theme.green : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        court.id == appState.localCourt?.id ? Theme.green.opacity(0.15) : Theme.orange,
                        in: .rect(cornerRadius: 12)
                    )
            }
            .disabled(court.id == appState.localCourt?.id)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
