import SwiftUI

struct ActivityFeedView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared: Bool = false

    private var games: [Game] { appState.activityGames }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if games.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.textTertiary)
                            Text("No recent games")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                            GameResultCard(game: game, currentUserID: appState.currentUserID)
                                .padding(.horizontal, 16)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 10)
                                .animation(.spring(response: 0.4).delay(Double(index) * 0.04), value: appeared)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.surface)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await appState.loadActivity()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appeared = true }
            }
        }
    }
}

struct GameResultCard: View {
    let game: Game
    let currentUserID: String

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(game.date)
        let hours = Int(interval / 3600)
        if hours < 1 { return "Just now" }
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Label(game.courtName, systemImage: "mappin.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }

            // Score
            HStack(spacing: 0) {
                teamColumn(players: game.teamA, score: game.scoreA, isWinner: game.winnerTeam == .teamA)
                VStack(spacing: 4) {
                    Text("VS")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(game.scoreA) - \(game.scoreB)")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 70)
                teamColumn(players: game.teamB, score: game.scoreB, isWinner: game.winnerTeam == .teamB)
            }

            // Engagement
            HStack(spacing: 16) {
                Label("\(game.likeCount)", systemImage: "heart")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                Label("\(game.commentCount)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(14)
        .background(Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 16))
    }

    private func teamColumn(players: [PlayerRef], score: Int, isWinner: Bool) -> some View {
        VStack(spacing: 6) {
            if isWinner {
                Text("W")
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.green)
            }
            HStack(spacing: -6) {
                ForEach(players.prefix(3)) { player in
                    AvatarView(name: player.displayName, size: 28)
                        .overlay { Circle().stroke(Theme.surfaceElevated, lineWidth: 2) }
                }
            }
            VStack(spacing: 2) {
                ForEach(players.prefix(2)) { player in
                    let isMe = player.id == currentUserID
                    Text(player.displayName.split(separator: " ").first.map(String.init) ?? "")
                        .font(.caption2)
                        .foregroundStyle(isMe ? Theme.orange : Theme.textSecondary)
                        .lineLimit(1)
                }
                if players.count > 2 {
                    Text("+\(players.count - 2)")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
