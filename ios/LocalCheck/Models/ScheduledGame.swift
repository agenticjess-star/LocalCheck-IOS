import Foundation

nonisolated struct ScheduledGame: Identifiable, Hashable, Sendable {
    let id: String
    let courtID: String
    let courtName: String
    let organizerID: String
    let organizerName: String
    let date: Date
    let maxPlayers: Int
    let confirmedPlayers: [PlayerRef]
    let isOpenInvite: Bool
    let title: String
    let note: String?

    var spotsRemaining: Int {
        max(0, maxPlayers - confirmedPlayers.count)
    }

    var isFull: Bool {
        spotsRemaining == 0
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: ScheduledGame, rhs: ScheduledGame) -> Bool {
        lhs.id == rhs.id
    }
}
