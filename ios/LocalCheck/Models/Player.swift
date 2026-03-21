import Foundation

nonisolated struct Player: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let username: String
    let avatarURL: String?
    let eloRating: Int
    let wins: Int
    let losses: Int
    let localCourtID: String?
    let joinDate: Date
    let totalCourtTimeMinutes: Int

    var winRate: Double {
        let total = wins + losses
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }

    var record: String {
        "\(wins)W - \(losses)L"
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}
