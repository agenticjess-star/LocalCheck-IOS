import Foundation
import CoreLocation

nonisolated struct Court: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let sportType: SportType
    let addedBy: String
    let addedDate: Date
    let imageURL: String?
    let localPlayerCount: Int
    let isConfirmed: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: Court, rhs: Court) -> Bool {
        lhs.id == rhs.id
    }
}

nonisolated enum SportType: String, CaseIterable, Sendable, Hashable {
    case basketball = "Basketball"
    case pickleball = "Pickleball"
    case tennis = "Tennis"
    case soccer = "Soccer"
    case volleyball = "Volleyball"

    var icon: String {
        switch self {
        case .basketball: "basketball.fill"
        case .pickleball: "figure.pickleball"
        case .tennis: "tennis.racket"
        case .soccer: "soccerball"
        case .volleyball: "volleyball.fill"
        }
    }
}
