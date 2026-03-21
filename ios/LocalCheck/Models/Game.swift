import Foundation

nonisolated struct Game: Identifiable, Hashable, Sendable {
    let id: String
    let courtID: String
    let courtName: String
    let date: Date
    let teamA: [PlayerRef]
    let teamB: [PlayerRef]
    let scoreA: Int
    let scoreB: Int
    let winnerTeam: Team
    let likeCount: Int
    let commentCount: Int

    nonisolated enum Team: String, Sendable {
        case teamA
        case teamB
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
}

nonisolated struct PlayerRef: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let avatarURL: String?
}
