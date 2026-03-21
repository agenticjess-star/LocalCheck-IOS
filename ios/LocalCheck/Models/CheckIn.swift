import Foundation

nonisolated struct CheckIn: Identifiable, Hashable, Sendable {
    let id: String
    let playerID: String
    let playerName: String
    let playerAvatarURL: String?
    let courtID: String
    let timestamp: Date
    let note: String?
    let isActive: Bool

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: CheckIn, rhs: CheckIn) -> Bool {
        lhs.id == rhs.id
    }
}
