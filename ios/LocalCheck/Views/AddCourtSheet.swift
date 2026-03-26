import CoreLocation
import MapKit
import SwiftUI

struct AddCourtSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let onCreated: (Court) -> Void

    @State private var searchQuery: String = ""
    @State private var courtName: String = ""
    @State private var address: String = ""
    @State private var sportType: SportType = .basketball
    @State private var position: MapCameraPosition = .region(Self.defaultRegion)
    @State private var selectedCoordinate: CLLocationCoordinate2D = Self.defaultRegion.center
    @State private var isSearching: Bool = false
    @State private var isRefreshingAddress: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var didSetInitialPosition: Bool = false

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchSection
                    mapSection
                    formSection
                    submitButton
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Theme.surface)
            .navigationTitle("Add Court")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Theme.textSecondary)
                }
            }
            .task {
                await appState.loadMap()
                setInitialPositionIfNeeded()
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search Address")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 10) {
                TextField("Park, school, or street address", text: $searchQuery)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Theme.textPrimary)
                    .submitLabel(.search)
                    .onSubmit {
                        submitSearch()
                    }

                Button {
                    submitSearch()
                } label: {
                    if isSearching {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 46, height: 46)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                    }
                }
                .disabled(isSearching || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .background(
                    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.surfaceCard : Theme.orange,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }

            Text("Search first, then move the map to fine-tune the pin.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pin Location")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    Task {
                        await refreshAddressFromPin()
                    }
                } label: {
                    if isRefreshingAddress {
                        ProgressView()
                            .tint(Theme.orange)
                    } else {
                        Label("Use Pin", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold))
                    }
                }
                .tint(Theme.orange)
            }

            ZStack {
                Map(position: $position)
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
                    .onMapCameraChange(frequency: .onEnd) { context in
                        selectedCoordinate = context.region.center
                    }

                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.orange)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                    Circle()
                        .fill(Theme.orange)
                        .frame(width: 8, height: 8)
                }
                .offset(y: -18)

                VStack {
                    Spacer()
                    Text("Move the map until the pin sits on the court.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 12)
                }
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.surfaceBorder, lineWidth: 1)
            }
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Court Details")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            field(title: "Court Name", text: $courtName, capitalization: .words)
            field(title: "Address", text: $address, capitalization: .words)

            Picker("Sport", selection: $sportType) {
                ForEach(SportType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var submitButton: some View {
        Button {
            isSubmitting = true
            Task {
                do {
                    let court = try await appState.createCourt(
                        name: courtName.trimmingCharacters(in: .whitespacesAndNewlines),
                        address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                        latitude: selectedCoordinate.latitude,
                        longitude: selectedCoordinate.longitude,
                        sportType: sportType
                    )
                    onCreated(court)
                    dismiss()
                } catch {
                    isSubmitting = false
                }
            }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }
                Text(isSubmitting ? "Adding Court..." : "Add Court")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canSubmit ? Theme.orange : Theme.surfaceCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!canSubmit)
    }

    private var canSubmit: Bool {
        !courtName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSubmitting
    }

    private func field(
        title: String,
        text: Binding<String>,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(Theme.textPrimary)
    }

    private func setInitialPositionIfNeeded() {
        guard !didSetInitialPosition else { return }
        didSetInitialPosition = true

        if let court = appState.localCourt ?? appState.courts.first {
            updateMapPosition(to: court.coordinate)
        } else {
            updateMapPosition(to: Self.defaultRegion.center)
        }
    }

    private func submitSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isSearching else { return }

        isSearching = true
        Task {
            defer { isSearching = false }

            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = MKCoordinateRegion(
                    center: selectedCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                )

                let response = try await MKLocalSearch(request: request).start()
                guard let item = response.mapItems.first else {
                    throw CourtComposerError.noSearchResults
                }

                let resultCoordinate = item.placemark.coordinate
                updateMapPosition(to: resultCoordinate)

                if courtName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    courtName = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                }

                let resolvedAddress = formattedAddress(from: item.placemark)
                if !resolvedAddress.isEmpty {
                    address = resolvedAddress
                }
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshAddressFromPin() async {
        guard !isRefreshingAddress else { return }
        isRefreshingAddress = true
        defer { isRefreshingAddress = false }

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(
                CLLocation(latitude: selectedCoordinate.latitude, longitude: selectedCoordinate.longitude)
            )
            guard let placemark = placemarks.first else {
                throw CourtComposerError.noSearchResults
            }

            let resolvedAddress = formattedAddress(from: placemark)
            if !resolvedAddress.isEmpty {
                address = resolvedAddress
            }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func updateMapPosition(to coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        position = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        )
    }

    private func formattedAddress(from placemark: CLPlacemark) -> String {
        let firstLine = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let secondLine = [placemark.locality, placemark.administrativeArea, placemark.postalCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        let parts = [firstLine, secondLine].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }
}

private enum CourtComposerError: LocalizedError {
    case noSearchResults

    var errorDescription: String? {
        switch self {
        case .noSearchResults:
            return "No matching address was found. Try a nearby landmark or move the map pin manually."
        }
    }
}
