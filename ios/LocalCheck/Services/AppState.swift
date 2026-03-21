// ============================================================
// File: ios/LocalCheck/Services/AppState.swift
// ============================================================
// @Observable store — inject via .environment(AppState()) in LocalCheckApp
// Schema aligned to live Supabase project 2026-03-20
// ============================================================

import SwiftUI

@Observable
final class AppState {
    // Replace this with a Supabase Auth session once auth is wired.
    var currentUserID: String = SupabaseConfig.initialCurrentUserID {
        didSet {
            guard currentUserID != oldValue else { return }
            UserDefaults.standard.set(currentUserID, forKey: SupabaseConfig.currentUserDefaultsKey)
        }
    }

    // Data
    var currentPlayer: Player?
    var localCourt: Court?
    var courts: [Court] = []
    var activeCheckIns: [CheckIn] = []
    var courtFeed: [FeedPost] = []
    var recentGames: [Game] = []
    var scheduledGames: [ScheduledGame] = []
    var players: [Player] = []
    var topOpponents: [(Player, Int)] = []

    // UI state
    var isCheckedIn: Bool = false
    var isLoadingHome: Bool = false
    var isLoadingProfile: Bool = false
    var isLoadingRankings: Bool = false
    var isLoadingSchedule: Bool = false
    var isLoadingMap: Bool = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    // MARK: - Loaders

    private func setError(_ error: any Error) {
        errorMessage = error.localizedDescription
    }

    private func resetSessionData() {
        currentPlayer = nil
        localCourt = nil
        activeCheckIns = []
        courtFeed = []
        recentGames = []
        scheduledGames = []
        topOpponents = []
        isCheckedIn = false
        errorMessage = nil
    }

    private func refreshCurrentPlayerContext() async throws -> (Player, Court?) {
        let player = try await service.fetchCurrentPlayer(userID: currentUserID)
        let court = try await service.fetchCourt(id: player.localCourtID)
        currentPlayer = player
        localCourt = court
        return (player, court)
    }

    func loadHome() async {
        isLoadingHome = true
        defer { isLoadingHome = false }

        do {
            let (_, court) = try await refreshCurrentPlayerContext()
            if let courtID = court?.id {
                async let checkInsTask = service.fetchActiveCheckIns(courtID: courtID)
                async let feedTask = service.fetchCourtFeed(courtID: courtID)
                let (checkIns, feed) = try await (checkInsTask, feedTask)
                activeCheckIns = checkIns
                courtFeed = feed
                isCheckedIn = checkIns.contains { $0.playerID == currentUserID }
            } else {
                activeCheckIns = []
                courtFeed = []
                isCheckedIn = false
            }
        } catch {
            setError(error)
        }
    }

    func loadProfile() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        do {
            let (player, _) = try await refreshCurrentPlayerContext()
            async let gamesTask = service.fetchRecentGames(forUserID: currentUserID)
            async let courtPlayersTask = service.fetchPlayers(localCourtID: player.localCourtID)
            let (games, courtPlayers) = try await (gamesTask, courtPlayersTask)
            recentGames = games

            var counts: [String: Int] = [:]
            for game in games {
                let meInA = game.teamA.contains { $0.id == currentUserID }
                let opponents = meInA ? game.teamB : game.teamA
                for opponent in opponents {
                    counts[opponent.id, default: 0] += 1
                }
            }

            topOpponents = counts.compactMap { entry in
                let (id, count) = entry
                return courtPlayers.first { $0.id == id }.map { ($0, count) }
            }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
        } catch {
            setError(error)
        }
    }

    func loadRankings() async {
        isLoadingRankings = true
        defer { isLoadingRankings = false }

        do {
            players = try await service.fetchPlayers()
        } catch {
            setError(error)
        }
    }

    func loadSchedule() async {
        isLoadingSchedule = true
        defer { isLoadingSchedule = false }

        do {
            scheduledGames = try await service.fetchScheduledGames()
        } catch {
            setError(error)
        }
    }

    func loadMap() async {
        isLoadingMap = true
        defer { isLoadingMap = false }

        do {
            courts = try await service.fetchCourts()
        } catch {
            setError(error)
        }
    }

    // MARK: - Actions

    func performCheckIn(courtID: String, note: String?) async {
        do {
            try await service.checkIn(userID: currentUserID, courtID: courtID, note: note)
            isCheckedIn = true
            activeCheckIns = try await service.fetchActiveCheckIns(courtID: courtID)
        } catch {
            setError(error)
        }
    }

    func performCheckOut() async {
        guard let courtID = localCourt?.id else { return }

        do {
            try await service.checkOut(userID: currentUserID, courtID: courtID)
            isCheckedIn = false
            activeCheckIns = try await service.fetchActiveCheckIns(courtID: courtID)
        } catch {
            setError(error)
        }
    }

    func postToFeed(courtID: String, content: String, type: FeedPost.PostType) async {
        do {
            try await service.postToFeed(
                userID: currentUserID,
                courtID: courtID,
                content: content,
                type: type
            )
            courtFeed = try await service.fetchCourtFeed(courtID: courtID)
        } catch {
            setError(error)
        }
    }

    func rsvpToGame(gameID: String) async {
        do {
            try await service.rsvpToGame(userID: currentUserID, gameID: gameID)
            scheduledGames = try await service.fetchScheduledGames()
        } catch {
            setError(error)
        }
    }

    func createScheduledGame(
        courtID: String,
        title: String,
        note: String?,
        startTime: Date,
        maxPlayers: Int,
        isOpenInvite: Bool
    ) async throws {
        do {
            try await service.createScheduledGame(
                userID: currentUserID,
                courtID: courtID,
                title: title,
                note: note,
                startTime: startTime,
                maxPlayers: maxPlayers,
                isOpenInvite: isOpenInvite
            )
            scheduledGames = try await service.fetchScheduledGames()
        } catch {
            setError(error)
            throw error
        }
    }

    func switchCurrentUser(to userID: String) async {
        guard !userID.isEmpty else { return }
        resetSessionData()
        currentUserID = userID
        await loadHome()
        await loadProfile()
        await loadSchedule()
    }

    func updateLocalCourt(courtID: String) async {
        do {
            try await service.updateLocalCourt(userID: currentUserID, courtID: courtID)
            localCourt = try await service.fetchCourt(id: courtID)
            currentPlayer = try await service.fetchCurrentPlayer(userID: currentUserID)

            if let updatedCourtID = localCourt?.id {
                activeCheckIns = try await service.fetchActiveCheckIns(courtID: updatedCourtID)
                courtFeed = try await service.fetchCourtFeed(courtID: updatedCourtID)
                isCheckedIn = activeCheckIns.contains { $0.playerID == currentUserID }
            } else {
                activeCheckIns = []
                courtFeed = []
                isCheckedIn = false
            }
        } catch {
            setError(error)
        }
    }
}
