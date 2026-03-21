import SwiftUI

struct FeedPostRow: View {
    let post: FeedPost

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(post.timestamp)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(name: post.authorName, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(post.authorName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.textPrimary)
                    if post.type == .checkIn {
                        Text("checked in")
                            .font(.caption)
                            .foregroundStyle(Theme.green)
                    }
                    Spacer()
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }

                Text(post.content)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 16) {
                    Label("\(post.likeCount)", systemImage: "heart")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 12))
    }
}
