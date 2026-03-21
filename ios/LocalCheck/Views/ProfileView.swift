import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if appState.isLoadingProfile && appState.currentPlayer == nil {
                        ProgressView("Loading profile...").padding(.top, 80)
                    } else {
                        profileHeader
                        statsGrid
                        localCourtSection
                        topOpponentsSection
                        recentGamesSection
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.surface)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape.fill") { showSettings = true }
                        .tint(Theme.orange)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.surfaceElevated)
            }
            .task {
                await appState.loadProfile()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appeared = true }
            }
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            if let player = appState.currentPlayer {
                AvatarView(name: player.displayName, size: 80)
                Text(player.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("@\(player.username)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("\(player.eloRating)")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.orange)
                        Text("ELO")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Divider().frame(height: 30)
                    VStack(spacing: 2) {
                        Text(player.record)
                            .font(.title3.bold())
                            .foregroundStyle(Theme.textPrimary)
                        Text("Record")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Divider().frame(height: 30)
                    VStack(spacing: 2) {
                        Text("\(player.wins + player.losses)")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.textPrimary)
                        Text("Games")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.95)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    // MARK: - Stats grid
    private var statsGrid: some View {
        let player = appState.currentPlayer
        return LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
            statCard(title: "Win Rate", value: String(format: "%.0f%%", (player?.winRate ?? 0) * 100), icon: "chart.line.uptrend.xyaxis")
            statCard(title: "Court Time", value: "\((player?.totalCourtTimeMinutes ?? 0) / 60)h", icon: "clock.fill")
        }
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.orange)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 14))
    }

    // MARK: - Local court
    private var localCourtSection: some View {
        Group {
            if let court = appState.localCourt {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Local Court")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 10) {
                        Image(systemName: court.sportType.icon)
                            .font(.title2)
                            .foregroundStyle(Theme.orange)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(court.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textPrimary)
                            Text(court.address)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("\(court.localPlayerCount) locals")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(12)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .padding(.horizontal, 16).padding(.top, 20)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    // MARK: - Top opponents
    private var topOpponentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Most Played")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            if appState.topOpponents.isEmpty {
                Text("Play some games to see your opponents here.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ForEach(appState.topOpponents, id: \.0.id) { player, count in
                    HStack(spacing: 10) {
                        AvatarView(name: player.displayName, size: 32)
                        Text(player.displayName)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(count) games")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(10)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
    }

    // MARK: - Recent games
    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Games")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            if appState.recentGames.isEmpty {
                Text("No games yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ForEach(appState.recentGames.prefix(5)) { game in
                    GameResultCard(game: game, currentUserID: appState.currentUserID)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
    }
}
