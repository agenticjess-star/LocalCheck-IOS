import SwiftUI

struct RankingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedFilter: RankingFilter = .allTime
    @State private var appeared: Bool = false

    private var players: [Player] { appState.players }

    nonisolated enum RankingFilter: String, CaseIterable {
        case week = "Week"; case month = "Month"; case allTime = "All Time"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    filterBar
                    if appState.isLoadingRankings && players.isEmpty {
                        ProgressView("Loading rankings...").padding(.top, 60)
                    } else {
                        topThree
                        fullLeaderboard
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden).background(Theme.surface)
            .navigationTitle("Rankings").navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await appState.loadRankings()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appeared = true }
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 0) {
            ForEach(RankingFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedFilter = filter }
                } label: {
                    Text(filter.rawValue).font(.subheadline.bold())
                        .foregroundStyle(selectedFilter == filter ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(selectedFilter == filter ? Theme.surfaceElevated : Color.clear)
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
        .padding(4).background(Theme.surfaceCard).clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var topThree: some View {
        let top = Array(players.prefix(3))
        return HStack(alignment: .bottom, spacing: 8) {
            if top.count > 1 { podiumCard(player: top[1], rank: 2, height: 80) }
            if top.count > 0 { podiumCard(player: top[0], rank: 1, height: 100) }
            if top.count > 2 { podiumCard(player: top[2], rank: 3, height: 65) }
        }
        .padding(.horizontal, 16).padding(.vertical, 20)
    }

    private func podiumCard(player: Player, rank: Int, height: CGFloat) -> some View {
        let isMe = player.id == appState.currentUserID
        return VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AvatarView(name: player.displayName, size: rank == 1 ? 56 : 44)
                if isMe { Circle().fill(Theme.orange).frame(width: 12, height: 12).offset(x: 2, y: -2) }
            }
            Text(player.displayName.split(separator: " ").first.map(String.init) ?? "")
                .font(.caption.bold()).foregroundStyle(Theme.textPrimary).lineLimit(1)
            Text("\(player.eloRating)").font(.caption2).foregroundStyle(Theme.textSecondary)
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(rank == 1 ? Theme.eloGold.opacity(0.2) : Theme.surfaceElevated)
                Text(rank == 1 ? "🥇" : rank == 2 ? "🥈" : "🥉").font(.title3)
            }
            .frame(maxWidth: .infinity).frame(height: height)
        }
        .frame(maxWidth: .infinity)
        .opacity(appeared ? 1 : 0).scaleEffect(appeared ? 1 : 0.8)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(rank) * 0.05), value: appeared)
    }

    private var fullLeaderboard: some View {
        VStack(spacing: 6) {
            ForEach(Array(players.dropFirst(3).enumerated()), id: \.element.id) { index, player in
                leaderboardRow(player: player, rank: index + 4)
                    .padding(.horizontal, 16)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.03 + 0.2), value: appeared)
            }
        }
    }

    private func leaderboardRow(player: Player, rank: Int) -> some View {
        let isMe = player.id == appState.currentUserID
        return HStack(spacing: 12) {
            Text("\(rank)").font(.subheadline.bold()).foregroundStyle(Theme.textTertiary).frame(width: 28)
            AvatarView(name: player.displayName, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.displayName).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                    if isMe { Text("You").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Theme.orange.opacity(0.2)).foregroundStyle(Theme.orange).clipShape(Capsule()) }
                }
                Text(player.record).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("\(player.eloRating)").font(.subheadline.bold()).foregroundStyle(Theme.orange)
        }
        .padding(12)
        .background(isMe ? Theme.orange.opacity(0.08) : Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 12))
        .overlay { if isMe { RoundedRectangle(cornerRadius: 12).stroke(Theme.orange.opacity(0.3), lineWidth: 1) } }
    }
}
