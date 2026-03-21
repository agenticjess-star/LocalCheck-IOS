import SwiftUI

struct ScheduleView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDate: Date = Date()
    @State private var showCreateGame: Bool = false
    @State private var appeared: Bool = false

    private var games: [ScheduledGame] { appState.scheduledGames }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    dateStrip
                    if appState.isLoadingSchedule && games.isEmpty {
                        ProgressView("Loading schedule...").padding(.top, 60)
                    } else {
                        gamesList
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden).background(Theme.surface)
            .navigationTitle("Schedule").navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Game", systemImage: "plus") { showCreateGame = true }.tint(Theme.orange)
                }
            }
            .sheet(isPresented: $showCreateGame) {
                CreateGameSheet(onCreated: { Task { await appState.loadSchedule() } })
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
                    .presentationBackground(Theme.surfaceElevated)
            }
            .task { await appState.loadSchedule()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appeared = true }
            }
        }
    }

    private var filteredGames: [ScheduledGame] {
        let cal = Calendar.current
        return games.filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var dateStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(0..<14, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date()))!
                    datePill(date: date)
                }
            }
        }
        .contentMargins(.horizontal, 16).scrollIndicators(.hidden)
        .padding(.vertical, 12)
    }

    private func datePill(date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        return Button { withAnimation(.spring(response: 0.3)) { selectedDate = date } } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.abbreviated))).font(.caption2).foregroundStyle(isSelected ? Theme.orange : Theme.textTertiary)
                Text(date.formatted(.dateTime.day())).font(.subheadline.bold()).foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                if isToday { Circle().fill(Theme.orange).frame(width: 4, height: 4) } else { Circle().fill(Color.clear).frame(width: 4, height: 4) }
            }
            .frame(width: 44).padding(.vertical, 8)
            .background(isSelected ? Theme.surfaceElevated : Color.clear).clipShape(.rect(cornerRadius: 10))
        }
    }

    private var gamesList: some View {
        Group {
            if filteredGames.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus").font(.system(size: 40)).foregroundStyle(Theme.textTertiary)
                    Text("No games scheduled").font(.subheadline).foregroundStyle(Theme.textSecondary)
                    Button("Create a Game") { showCreateGame = true }.tint(Theme.orange)
                }
                .frame(maxWidth: .infinity).padding(.top, 60)
            } else {
                ForEach(Array(filteredGames.enumerated()), id: \.element.id) { index, game in
                    ScheduledGameCard(game: game, currentUserID: appState.currentUserID) {
                        Task { await appState.rsvpToGame(gameID: game.id) }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 10)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.05), value: appeared)
                }
            }
        }
    }
}

struct ScheduledGameCard: View {
    let game: ScheduledGame
    let currentUserID: String
    let onRSVP: () -> Void
    @State private var rsvpTrigger: Int = 0
    @State private var isRSVPd: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title).font(.headline).foregroundStyle(Theme.textPrimary)
                    Label(game.courtName, systemImage: "mappin.fill").font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(game.date.formatted(.dateTime.hour().minute())).font(.subheadline.bold()).foregroundStyle(Theme.orange)
                    Text(game.isOpenInvite ? "Open" : "Invite").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(game.isOpenInvite ? Theme.green.opacity(0.2) : Theme.orange.opacity(0.2)).foregroundStyle(game.isOpenInvite ? Theme.green : Theme.orange).clipShape(Capsule())
                }
            }
            HStack(spacing: -8) {
                ForEach(game.confirmedPlayers.prefix(5)) { player in
                    AvatarView(name: player.displayName, size: 28).overlay { Circle().stroke(Theme.surface, lineWidth: 2) }
                }
                if game.confirmedPlayers.count > 5 {
                    Text("+\(game.confirmedPlayers.count - 5)").font(.caption2).foregroundStyle(Theme.textSecondary)
                        .frame(width: 28, height: 28).background(Theme.surfaceCard).clipShape(Circle()).overlay { Circle().stroke(Theme.surface, lineWidth: 2) }
                }
                Spacer()
                Text("\(game.spotsRemaining) spots left").font(.caption).foregroundStyle(game.isFull ? Theme.red : Theme.textSecondary)
            }
            Button {
                if !isRSVPd && !game.isFull { rsvpTrigger += 1; isRSVPd = true; onRSVP() }
            } label: {
                Text(isRSVPd ? "RSVP'd ✓" : game.isFull ? "Full" : "RSVP")
                    .font(.subheadline.bold()).foregroundStyle(isRSVPd ? Theme.green : game.isFull ? Theme.textTertiary : .white)
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(isRSVPd ? Theme.green.opacity(0.15) : game.isFull ? Theme.surfaceCard : Theme.orange, in: .rect(cornerRadius: 10))
            }
            .disabled(isRSVPd || game.isFull)
            .sensoryFeedback(.impact(weight: .medium), trigger: rsvpTrigger)
        }
        .padding(14).background(Theme.surfaceElevated).clipShape(.rect(cornerRadius: 16))
        .onAppear { isRSVPd = game.confirmedPlayers.contains { $0.id == currentUserID } }
    }
}
