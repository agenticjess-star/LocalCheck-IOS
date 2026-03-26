// ============================================================
// File: ios/LocalCheck/Services/AppState.swift
// ============================================================
// @Observable store — inject via .environment(AppState()) in LocalCheckApp
// ============================================================

import AuthenticationServices
import SwiftUI

@Observable
final class AppState {
    // Auth
    var authSession: AuthSession?
    var currentUserID: String = ""
    var authNotice: String?

    // Data
    var currentPlayer: Player?
    var localCourt: Court?
    var courts: [Court] = []
    var activeCheckIns: [CheckIn] = []
    var courtFeed: [FeedPost] = []
    var recentGames: [Game] = []
    var activityGames: [Game] = []
    var scheduledGames: [ScheduledGame] = []
    var players: [Player] = []
    var topOpponents: [(Player, Int)] = []

    // UI state
    var isInitializingApp: Bool = false
    var isAuthenticating: Bool = false
    var isCheckedIn: Bool = false
    var isLoadingHome: Bool = false
    var isLoadingProfile: Bool = false
    var isLoadingRankings: Bool = false
    var isLoadingSchedule: Bool = false
    var isLoadingMap: Bool = false
    var errorMessage: String?

    var skippedCourtOnboarding: Bool = false

    var isAuthenticated: Bool {
        authSession != nil
    }

    var requiresLocalCourtSelection: Bool {
        isAuthenticated && currentPlayer != nil && localCourt == nil && !skippedCourtOnboarding
    }

    var currentUserEmail: String? {
        authSession?.user.email
    }

    private var hasInitializedApp: Bool = false

    private let service = SupabaseService.shared
    private let authService = SupabaseAuthService.shared

    // MARK: - Lifecycle

    func initializeApp() async {
        guard !hasInitializedApp else { return }
        hasInitializedApp = true

        isInitializingApp = true
        defer { isInitializingApp = false }

        do {
            if let restoredSession = try await authService.restoreSession() {
                try await establishSession(restoredSession)
            } else {
                await service.setAccessToken(nil)
                clearAuthenticatedState()
            }
        } catch {
            await service.setAccessToken(nil)
            clearAuthenticatedState()
            setError(error)
        }
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async {
        clearMessages()
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let session = try await authService.signIn(email: email, password: password)
            try await establishSession(session)
        } catch {
            setError(error)
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        clearMessages()
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let result = try await authService.signUp(email: email, password: password, displayName: displayName)
            if let session = result.session {
                try await establishSession(session, preferredDisplayName: displayName)
            } else if result.requiresEmailConfirmation {
                authNotice = "Account created. Confirm your email, then sign in."
            }
        } catch {
            setError(error)
        }
    }

    func signInWithApple(authorization: ASAuthorization, rawNonce: String) async {
        clearMessages()
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidIdentityToken
            }
            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  !identityToken.isEmpty else {
                throw AuthError.invalidIdentityToken
            }

            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0?.trimmedNonEmpty }
                .joined(separator: " ")
                .trimmedNonEmpty

            let session = try await authService.signInWithApple(idToken: identityToken, rawNonce: rawNonce)
            try await establishSession(session, preferredDisplayName: fullName)
        } catch {
            setError(error)
        }
    }

    func signOut() async {
        let accessToken = authSession?.accessToken
        await authService.signOut(accessToken: accessToken)
        await service.setAccessToken(nil)
        clearAuthenticatedState()
    }

    private func establishSession(_ session: AuthSession, preferredDisplayName: String? = nil) async throws {
        authSession = session
        currentUserID = session.user.id
        await service.setAccessToken(session.accessToken)

        let player = try await service.ensureProfile(
            for: session.user,
            preferredDisplayName: preferredDisplayName
        )
        currentPlayer = player
        localCourt = try await service.fetchCourt(id: player.localCourtID)
        authNotice = nil

        await loadHome()
        await loadSchedule()
    }

    private func clearAuthenticatedState() {
        authSession = nil
        currentUserID = ""
        currentPlayer = nil
        localCourt = nil
        courts = []
        activeCheckIns = []
        courtFeed = []
        recentGames = []
        activityGames = []
        scheduledGames = []
        players = []
        topOpponents = []
        isCheckedIn = false
        skippedCourtOnboarding = false
        authNotice = nil
    }

    private func clearMessages() {
        errorMessage = nil
        authNotice = nil
    }

    // MARK: - Errors

    private func setError(_ error: any Error) {
        if let authError = error as? AuthError, case .cancelled = authError {
            return
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !message.isEmpty {
            errorMessage = message
        }
    }

    // MARK: - Loaders

    private func refreshCurrentPlayerContext() async throws -> (Player, Court?) {
        guard !currentUserID.isEmpty else {
            throw AuthError.unauthorized("Please sign in to continue.")
        }

        let player = try await service.fetchCurrentPlayer(userID: currentUserID)
        let court = try await service.fetchCourt(id: player.localCourtID)
        currentPlayer = player
        localCourt = court
        return (player, court)
    }

    func loadHome() async {
        guard isAuthenticated else { return }

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
        guard isAuthenticated else { return }

        isLoadingProfile = true
        defer { isLoadingProfile = false }

        do {
            let (player, _) = try await refreshCurrentPlayerContext()
            async let gamesTask = service.fetchRecentGames(forUserID: currentUserID)
            async let courtPlayersTask = service.fetchPlayers(localCourtID: player.localCourtID)
            let (games, courtPlayers) = try await (gamesTask, courtPlayersTask)

            recentGames = games
            players = courtPlayers

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
        guard isAuthenticated else { return }

        isLoadingRankings = true
        defer { isLoadingRankings = false }

        do {
            let (player, _) = try await refreshCurrentPlayerContext()
            if let courtID = player.localCourtID {
                players = try await service.fetchPlayers(localCourtID: courtID)
            } else {
                players = []
            }
        } catch {
            setError(error)
        }
    }

    func loadSchedule() async {
        guard isAuthenticated else { return }

        isLoadingSchedule = true
        defer { isLoadingSchedule = false }

        do {
            let (_, court) = try await refreshCurrentPlayerContext()
            if let courtID = court?.id {
                scheduledGames = try await service.fetchScheduledGames(courtID: courtID)
            } else {
                scheduledGames = []
            }
        } catch {
            setError(error)
        }
    }

    func skipCourtOnboarding() {
        skippedCourtOnboarding = true
    }

    func loadMap() async {
        guard isAuthenticated else { return }

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
        guard isAuthenticated else { return }

        do {
            try await service.checkIn(userID: currentUserID, courtID: courtID, note: note)
            isCheckedIn = true
            activeCheckIns = try await service.fetchActiveCheckIns(courtID: courtID)
        } catch {
            setError(error)
        }
    }

    func performCheckOut() async {
        guard isAuthenticated, let courtID = localCourt?.id else { return }

        do {
            try await service.checkOut(userID: currentUserID, courtID: courtID)
            isCheckedIn = false
            activeCheckIns = try await service.fetchActiveCheckIns(courtID: courtID)
        } catch {
            setError(error)
        }
    }

    func postToFeed(courtID: String, content: String, type: FeedPost.PostType) async {
        guard isAuthenticated else { return }

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
        guard isAuthenticated else { return }

        do {
            try await service.rsvpToGame(userID: currentUserID, gameID: gameID)
            let (_, court) = try await refreshCurrentPlayerContext()
            if let courtID = court?.id {
                scheduledGames = try await service.fetchScheduledGames(courtID: courtID)
            } else {
                scheduledGames = []
            }
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
        guard isAuthenticated else { return }

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
            let (_, currentCourt) = try await refreshCurrentPlayerContext()
            if let currentCourtID = currentCourt?.id {
                scheduledGames = try await service.fetchScheduledGames(courtID: currentCourtID)
            } else {
                scheduledGames = []
            }
        } catch {
            setError(error)
            throw error
        }
    }

    func updateLocalCourt(courtID: String) async {
        guard isAuthenticated else { return }

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

    func createCourt(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        sportType: SportType
    ) async throws -> Court {
        guard isAuthenticated else {
            throw AuthError.unauthorized("Please sign in to continue.")
        }

        do {
            let court = try await service.createCourt(
                userID: currentUserID,
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude,
                sportType: sportType
            )

            try await service.updateLocalCourt(userID: currentUserID, courtID: court.id)
            currentPlayer = try await service.fetchCurrentPlayer(userID: currentUserID)
            localCourt = try await service.fetchCourt(id: court.id) ?? court
            courts = try await service.fetchCourts()
            activeCheckIns = []
            courtFeed = []
            isCheckedIn = false
            await loadHome()
            await loadSchedule()
            return localCourt ?? court
        } catch {
            setError(error)
            throw error
        }
    }

    func loadActivity() async {
        guard isAuthenticated else { return }

        do {
            let (_, court) = try await refreshCurrentPlayerContext()
            if let courtID = court?.id {
                activityGames = try await service.fetchRecentGames(courtID: courtID)
            } else {
                activityGames = []
            }
        } catch {
            setError(error)
        }
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
