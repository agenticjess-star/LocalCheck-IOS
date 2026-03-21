// ============================================================
// File: ios/LocalCheck/Services/AppState.swift
// ============================================================
// @Observable store — inject via .environment(AppState()) in LocalCheckApp
// Schema aligned to live Supabase project 2026-03-20
// ============================================================

import SwiftUI

@Observable
final class AppState {
    // Auth — set this from Supabase Auth on sign-in
    var currentUserID: String = SupabaseConfig.currentUserID

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
    var errorMessage: String? = nil

    private let service = SupabaseService.shared

    // MARK: - Loaders

    func loadHome() async {
        isLoadingHome = true; defer { isLoadingHome = false }
        do {
            async let playerTask = service.fetchCurrentPlayer()
            async let courtTask = service.fetchLocalCourt()
            let (player, court) = try await (playerTask, courtTask)
            currentPlayer = player
            localCourt = court
            if let courtID = court?.id {
                async let checkInsTask = service.fetchActiveCheckIns(courtID: courtID)
                async let feedTask = service.fetchCourtFeed(courtID: courtID)
                let (checkIns, feed) = try await (checkInsTask, feedTask)
                activeCheckIns = checkIns
                courtFeed = feed
                isCheckedIn = checkIns.contains { $0.playerID == currentUserID }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func loadProfile() async {
        isLoadingProfile = true; defer { isLoadingProfile = false }
        do {
            async let playerTask = service.fetchCurrentPlayer()
            async let gamesTask = service.fetchRecentGames()
            async let playersTask = service.fetchPlayers(localCourtID: localCourt?.id)
            let (player, games, courtPlayers) = try await (playerTask, gamesTask, playersTask)
            currentPlayer = player
            recentGames = games
            players = courtPlayers
            // Derive top opponents from game history
            var counts: [String: Int] = [:]
            for game in games {
                let meInA = game.teamA.contains { $0.id == currentUserID }
                let opponents = meInA ? game.teamB : game.teamA
                for opp in opponents { counts[opp.id, default: 0] += 1 }
            }
            topOpponents = counts.compactMap { (id, count) in
                courtPlayers.first { $0.id == id }.map { ($0, count) }
            }.sorted { $0.1 > $1.1 }.prefix(5).map { $0 }
        } catch { errorMessage = error.localizedDescription }
    }

    func loadRankings() async {
        isLoadingRankings = true; defer { isLoadingRankings = false }
        do { players = try await service.fetchPlayers() }
        catch { errorMessage = error.localizedDescription }
    }

    func loadSchedule() async {
        isLoadingSchedule = true; defer { isLoadingSchedule = false }
        do { scheduledGames = try await service.fetchScheduledGames() }
        catch { errorMessage = error.localizedDescription }
    }

    func loadMap() async {
        isLoadingMap = true; defer { isLoadingMap = false }
        do { courts = try await service.fetchCourts() }
        catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Actions

    func performCheckIn(courtID: String, note: String?) async {
        do {
            try await service.checkIn(courtID: courtID, note: note)
            isCheckedIn = true
            // Refresh check-ins list
            activeCheckIns = try await service.fetchActiveCheckIns(courtID: courtID)
        } catch { errorMessage = error.localizedDescription }
    }

    func performCheckOut() async {
        guard let courtID = localCourt?.id else { return }
        do {
            try await service.checkOut(userID: currentUserID, courtID: courtID)
            isCheckedIn = false
            activeCheckIns = try await service.fetchActiveCheckIns(courtID: courtID)
        } catch { errorMessage = error.localizedDescription }
    }

    func postToFeed(courtID: String, content: String, type: FeedPost.PostType) async {
        do {
            try await service.postToFeed(courtID: courtID, content: content, type: type)
            courtFeed = try await service.fetchCourtFeed(courtID: courtID)
        } catch { errorMessage = error.localizedDescription }
    }

    func rsvpToGame(gameID: String) async {
        do {
            try await service.rsvpToGame(gameID: gameID)
            scheduledGames = try await service.fetchScheduledGames()
        } catch { errorMessage = error.localizedDescription }
    }
}
