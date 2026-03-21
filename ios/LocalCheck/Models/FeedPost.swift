import Foundation

nonisolated struct FeedPost: Identifiable, Hashable, Sendable {
    let id: String
    let authorID: String
    let authorName: String
    let authorAvatarURL: String?
    let courtID: String
    let courtName: String
    let content: String
    let timestamp: Date
    let type: PostType
    let likeCount: Int

    nonisolated enum PostType: String, Sendable {
        case checkIn
        case note
        case gameResult
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: FeedPost, rhs: FeedPost) -> Bool {
        lhs.id == rhs.id
    }
}
