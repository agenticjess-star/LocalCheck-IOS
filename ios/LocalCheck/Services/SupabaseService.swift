// ============================================================
// File: ios/LocalCheck/Services/SupabaseService.swift
// ============================================================
// Pure URLSession REST client. Zero dependencies.
// Schema verified against live Supabase project 2026-03-20.
// ============================================================

import Foundation

// MARK: - Config

enum SupabaseConfig {
    static let url = "https://jzclwnzcektqhgkkdeje.supabase.co"
    static let anonKey = "sb_publishable_oL6OFCLyIPWUuxv27tqZUQ_1i7WYcHS"
    static let sessionKeychainAccount = "supabase.auth.session"
}

// MARK: - SupabaseService
actor SupabaseService {
    static let shared = SupabaseService()
    private let base = URL(string: SupabaseConfig.url)!
    private var accessToken: String?

    private func headers(prefer: String = "return=representation") -> [String: String] {
        [
            "apikey": SupabaseConfig.anonKey,
            "Authorization": "Bearer \(accessToken ?? SupabaseConfig.anonKey)",
            "Content-Type": "application/json",
            "Prefer": prefer,
        ]
    }

    func setAccessToken(_ token: String?) {
        accessToken = token
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw AppError.server("HTTP \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
        }
        return data
    }

    // MARK: - HTTP helpers
    private func get<T: Decodable>(_ table: String, query: [String: String] = [:]) async throws -> T {
        var comps = URLComponents(url: base.appendingPathComponent("/rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var req = URLRequest(url: comps.url!)
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let data = try await responseData(for: req)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    private func post<T: Decodable>(
        _ table: String,
        body: some Encodable,
        prefer: String = "return=representation",
        query: [String: String] = [:]
    ) async throws -> T {
        var comps = URLComponents(url: base.appendingPathComponent("/rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        headers(prefer: prefer).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder.supabase.encode(body)
        let data = try await responseData(for: req)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    private func postNoResponse(_ table: String, body: some Encodable) async throws {
        var req = URLRequest(url: base.appendingPathComponent("/rest/v1/\(table)"))
        req.httpMethod = "POST"
        headers(prefer: "return=minimal").forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder.supabase.encode(body)
        _ = try await responseData(for: req)
    }

    private func patch(_ table: String, filters: [String: String], body: some Encodable) async throws {
        var comps = URLComponents(url: base.appendingPathComponent("/rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        comps.queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "PATCH"
        headers(prefer: "return=minimal").forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder.supabase.encode(body)
        _ = try await responseData(for: req)
    }

    private func isDuplicateConflict(_ error: Error) -> Bool {
        guard let appError = error as? AppError else { return false }
        guard case let .server(message) = appError else { return false }
        return message.contains("409") || message.localizedCaseInsensitiveContains("duplicate")
    }

    // MARK: - Profiles
    func fetchCurrentPlayer(userID: String) async throws -> Player {
        try await fetchProfileRow(userID: userID).toPlayer()
    }

    func fetchPlayers(localCourtID: String? = nil) async throws -> [Player] {
        var q: [String: String] = ["select": "*", "order": "elo_rating.desc"]
        if let id = localCourtID {
            q["local_court_id"] = "eq.\(id)"
        }
        let rows: [ProfileRow] = try await get("profiles", query: q)
        return rows.map { $0.toPlayer() }
    }

    private func fetchProfileRow(userID: String) async throws -> ProfileRow {
        let rows: [ProfileRow] = try await get("profiles", query: [
            "id": "eq.\(userID)",
            "select": "*",
        ])
        guard let row = rows.first else { throw AppError.notFound("profile") }
        return row
    }

    func ensureProfile(
        for user: AuthUser,
        preferredDisplayName: String? = nil,
        preferredUsername: String? = nil
    ) async throws -> Player {
        do {
            let existingRow = try await fetchProfileRow(userID: user.id)
            let displayName = existingRow.display_name?.trimmedNonEmpty ?? preferredDisplayName?.trimmedNonEmpty ?? user.displayNameCandidate
            let username = existingRow.username?.trimmedNonEmpty ?? preferredUsername?.trimmedNonEmpty ?? user.usernameCandidate

            if displayName != existingRow.display_name || username != existingRow.username {
                struct Body: Encodable {
                    let display_name: String?
                    let username: String?
                }

                try await patch("profiles",
                    filters: ["id": "eq.\(user.id)"],
                    body: Body(display_name: displayName, username: username)
                )
                return try await fetchCurrentPlayer(userID: user.id)
            }

            return existingRow.toPlayer()
        } catch let error as AppError {
            if case .notFound(_) = error {
                return try await createProfile(
                    for: user,
                    preferredDisplayName: preferredDisplayName,
                    preferredUsername: preferredUsername
                )
            }
            throw error
        }
    }

    private func createProfile(
        for user: AuthUser,
        preferredDisplayName: String?,
        preferredUsername: String?
    ) async throws -> Player {
        struct Body: Encodable {
            let id: String
            let display_name: String
            let username: String
        }

        let displayName = preferredDisplayName?.trimmedNonEmpty ?? user.displayNameCandidate ?? "Player"
        let baseUsername = preferredUsername?.trimmedNonEmpty ?? user.usernameCandidate ?? "player"
        let usernameCandidates = candidateUsernames(from: baseUsername, userID: user.id)

        for username in usernameCandidates {
            do {
                let rows: [ProfileRow] = try await post("profiles",
                    body: [Body(id: user.id, display_name: displayName, username: username)],
                    prefer: "resolution=merge-duplicates,return=representation",
                    query: ["on_conflict": "id"]
                )
                if let row = rows.first {
                    return row.toPlayer()
                }
                return try await fetchCurrentPlayer(userID: user.id)
            } catch {
                if isDuplicateConflict(error) {
                    continue
                }
                throw error
            }
        }

        throw AppError.server("Could not create a unique username for this profile.")
    }

    // MARK: - Courts (use the view which includes stats)
    func fetchCourts() async throws -> [Court] {
        let rows: [CourtWithStatsRow] = try await get("courts_with_stats", query: [
            "is_archived": "eq.false",
            "select": "*",
            "order": "local_player_count.desc",
        ])
        return rows.map { $0.toCourt() }
    }

    func fetchCourt(id: String?) async throws -> Court? {
        guard let id, !id.isEmpty else { return nil }
        let courts: [CourtWithStatsRow] = try await get("courts_with_stats", query: [
            "id": "eq.\(id)",
            "is_archived": "eq.false",
            "select": "*",
        ])
        return courts.first?.toCourt()
    }

    func createCourt(
        userID: String,
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        sportType: SportType
    ) async throws -> Court {
        struct Body: Encodable {
            let name: String
            let address: String
            let latitude: Double
            let longitude: Double
            let sport_type: String
            let added_by: String
        }

        struct InsertedCourtRow: Decodable {
            let id: String
        }

        let rows: [InsertedCourtRow] = try await post("courts", body: Body(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            sport_type: sportType.rawValue.lowercased(),
            added_by: userID
        ))

        guard let id = rows.first?.id,
              let court = try await fetchCourt(id: id) else {
            throw AppError.notFound("court")
        }

        return court
    }

    // MARK: - Check-ins (use the active_check_ins view)
    func fetchActiveCheckIns(courtID: String) async throws -> [CheckIn] {
        let rows: [ActiveCheckInRow] = try await get("active_check_ins", query: [
            "court_id": "eq.\(courtID)",
            "select": "*",
            "order": "timestamp.desc",
        ])
        return rows.map { $0.toCheckIn() }
    }

    func checkIn(userID: String, courtID: String, note: String?) async throws {
        struct Body: Encodable {
            let user_id: String
            let court_id: String
            let note: String?
        }

        try await postNoResponse("check_ins", body: Body(
            user_id: userID,
            court_id: courtID,
            note: note
        ))
    }

    func checkOut(userID: String, courtID: String) async throws {
        struct Body: Encodable {
            let checked_out_at: String
        }

        try await patch("check_ins",
            filters: [
                "user_id": "eq.\(userID)",
                "court_id": "eq.\(courtID)",
                "checked_out_at": "is.null",
            ],
            body: Body(checked_out_at: ISO8601DateFormatter().string(from: Date()))
        )
    }

    // MARK: - Feed (use the view which includes author/court names + like counts)
    func fetchCourtFeed(courtID: String) async throws -> [FeedPost] {
        let rows: [FeedPostWithCountsRow] = try await get("feed_posts_with_counts", query: [
            "court_id": "eq.\(courtID)",
            "select": "*",
            "order": "timestamp.desc",
            "limit": "30",
        ])
        return rows.map { $0.toFeedPost() }
    }

    func postToFeed(userID: String, courtID: String, content: String, type: FeedPost.PostType) async throws {
        struct Body: Encodable {
            let author_id: String
            let court_id: String
            let content: String
            let post_type: String
        }

        try await postNoResponse("feed_posts", body: Body(
            author_id: userID,
            court_id: courtID,
            content: content,
            post_type: type.rawValue
        ))
    }

    // MARK: - Games (use games_with_counts view + participants separately)
    func fetchRecentGames(courtID: String? = nil) async throws -> [Game] {
        var q: [String: String] = ["select": "*", "order": "date.desc", "limit": "20"]
        if let id = courtID {
            q["court_id"] = "eq.\(id)"
        }
        let gameRows: [GameWithCountsRow] = try await get("games_with_counts", query: q)
        return try await hydrateGames(from: gameRows)
    }

    func fetchRecentGames(forUserID userID: String) async throws -> [Game] {
        let membershipRows: [GameMembershipRow] = try await get("game_participants", query: [
            "user_id": "eq.\(userID)",
            "select": "game_id",
        ])
        let uniqueGameIDs = Array(Set(membershipRows.map(\.game_id))).sorted()
        guard !uniqueGameIDs.isEmpty else { return [] }
        let gameRows: [GameWithCountsRow] = try await get("games_with_counts", query: [
            "id": "in.(\(uniqueGameIDs.joined(separator: ",")))",
            "select": "*",
            "order": "date.desc",
            "limit": "20",
        ])
        return try await hydrateGames(from: gameRows)
    }

    private func hydrateGames(from gameRows: [GameWithCountsRow]) async throws -> [Game] {
        let gameIDs = gameRows.map(\.id).joined(separator: ",")
        guard !gameIDs.isEmpty else { return [] }
        let participants: [GameParticipantRow] = try await get("game_participants", query: [
            "game_id": "in.(\(gameIDs))",
            "select": "*",
            "order": "display_order.asc",
        ])
        let profilesByID = try await fetchProfileSummaries(userIDs: participants.map(\.user_id))
        return gameRows.map { row in
            row.toGame(
                participants: participants.filter { $0.game_id == row.id },
                profilesByID: profilesByID
            )
        }
    }

    // MARK: - Scheduled games
    func fetchScheduledGames(courtID: String? = nil) async throws -> [ScheduledGame] {
        let now = ISO8601DateFormatter().string(from: Date())
        var query: [String: String] = [
            "start_time": "gte.\(now)",
            "select": "*",
            "order": "start_time.asc",
            "status": "neq.cancelled",
        ]
        if let courtID {
            query["court_id"] = "eq.\(courtID)"
        }
        let rows: [ScheduledGameRow] = try await get("scheduled_games", query: query)
        guard !rows.isEmpty else { return [] }
        let courtNamesByID = try await fetchCourtSummaries(courtIDs: rows.map(\.court_id))
        let organizerProfilesByID = try await fetchProfileSummaries(userIDs: rows.map(\.organizer_id))

        let ids = rows.map(\.id).joined(separator: ",")
        let participants: [ScheduledGameParticipantRow] = try await get("scheduled_game_participants", query: [
            "scheduled_game_id": "in.(\(ids))",
            "select": "*",
        ])
        let participantProfilesByID = try await fetchProfileSummaries(userIDs: participants.map(\.user_id))
        return rows.map { row in
            row.toScheduledGame(
                participants: participants.filter { $0.scheduled_game_id == row.id && $0.countsTowardAttendance },
                organizer: organizerProfilesByID[row.organizer_id],
                court: courtNamesByID[row.court_id],
                participantProfilesByID: participantProfilesByID
            )
        }
    }

    private func fetchProfileSummaries(userIDs: [String]) async throws -> [String: ProfileSummaryRow] {
        let uniqueIDs = Array(Set(userIDs)).sorted()
        guard !uniqueIDs.isEmpty else { return [:] }
        let rows: [ProfileSummaryRow] = try await get("profiles", query: [
            "id": "in.(\(uniqueIDs.joined(separator: ",")))",
            "select": "id,display_name,avatar_url",
        ])
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
    }

    private func fetchCourtSummaries(courtIDs: [String]) async throws -> [String: CourtSummaryRow] {
        let uniqueIDs = Array(Set(courtIDs)).sorted()
        guard !uniqueIDs.isEmpty else { return [:] }
        let rows: [CourtSummaryRow] = try await get("courts", query: [
            "id": "in.(\(uniqueIDs.joined(separator: ",")))",
            "select": "id,name",
        ])
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
    }

    func rsvpToGame(userID: String, gameID: String) async throws {
        struct Body: Encodable {
            let scheduled_game_id: String
            let user_id: String
            let rsvp_status: String
        }

        do {
            try await postNoResponse("scheduled_game_participants", body: Body(
                scheduled_game_id: gameID,
                user_id: userID,
                rsvp_status: "confirmed"
            ))
        } catch {
            guard let appError = error as? AppError,
                  case let .server(message) = appError,
                  message.localizedCaseInsensitiveContains("rsvp_status") else {
                throw error
            }

            try await postNoResponse("scheduled_game_participants", body: Body(
                scheduled_game_id: gameID,
                user_id: userID,
                rsvp_status: "going"
            ))
        }
    }

    func createScheduledGame(
        userID: String,
        courtID: String,
        title: String,
        note: String?,
        startTime: Date,
        maxPlayers: Int,
        isOpenInvite: Bool
    ) async throws {
        struct Body: Encodable {
            let court_id: String
            let organizer_id: String
            let title: String
            let note: String?
            let start_time: Date
            let max_players: Int
            let is_open_invite: Bool
            let status: String
        }

        struct InsertedScheduledGameRow: Decodable {
            let id: String
        }

        let rows: [InsertedScheduledGameRow] = try await post("scheduled_games", body: Body(
            court_id: courtID,
            organizer_id: userID,
            title: title,
            note: note,
            start_time: startTime,
            max_players: maxPlayers,
            is_open_invite: isOpenInvite,
            status: "scheduled"
        ))
        guard let gameID = rows.first?.id else { throw AppError.notFound("scheduled game") }

        do {
            try await rsvpToGame(userID: userID, gameID: gameID)
        } catch {
            if !isDuplicateConflict(error) {
                throw error
            }
        }
    }

    func updateLocalCourt(userID: String, courtID: String) async throws {
        struct Body: Encodable {
            let local_court_id: String
        }

        try await patch("profiles",
            filters: ["id": "eq.\(userID)"],
            body: Body(local_court_id: courtID)
        )
    }
}

// MARK: - Codecs
extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            let fmts = [
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX",
            ]
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            for fmt in fmts {
                f.dateFormat = fmt
                if let d = f.date(from: s) {
                    return d
                }
            }
            if let d = ISO8601DateFormatter().date(from: s) {
                return d
            }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Cannot decode date: \(s)"
            )
        }
        return d
    }()
}

extension JSONEncoder {
    static let supabase: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

// MARK: - Errors
enum AppError: LocalizedError {
    case notFound(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let s):
            return "Not found: \(s)"
        case .server(let s):
            return "Server error: \(s)"
        }
    }
}

private func candidateUsernames(from rawValue: String, userID: String) -> [String] {
    let base = rawValue.sanitizedUsername ?? "player\(userID.prefix(6))"
    let fallbackSeed = userID.replacingOccurrences(of: "-", with: "")
    let suffix = String(fallbackSeed.prefix(4))
    return [
        base,
        "\(base)_\(suffix)",
        "\(base)\(suffix)",
        "player\(suffix)",
    ]
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var sanitizedUsername: String? {
        let lowered = lowercased()
        let filtered = lowered.unicodeScalars.reduce(into: "") { partialResult, scalar in
            if CharacterSet.alphanumerics.contains(scalar) {
                partialResult.unicodeScalars.append(scalar)
            } else {
                partialResult.append("_")
            }
        }
        let collapsed = filtered
            .replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        let truncated = String(collapsed.prefix(24))
        return truncated.trimmedNonEmpty
    }
}

// MARK: - Row types (Supabase JSON → Swift models)

// profiles
struct ProfileRow: Decodable {
    let id: String
    let display_name: String?
    let username: String?
    let avatar_url: String?
    let elo_rating: Int?
    let wins: Int?
    let losses: Int?
    let local_court_id: String?
    let created_at: Date?
    let total_court_time_minutes: Int?

    func toPlayer() -> Player {
        Player(
            id: id,
            displayName: display_name ?? "Player",
            username: username ?? id.prefix(8).description,
            avatarURL: avatar_url,
            eloRating: elo_rating ?? 1200,
            wins: wins ?? 0,
            losses: losses ?? 0,
            localCourtID: local_court_id,
            joinDate: created_at ?? Date(),
            totalCourtTimeMinutes: total_court_time_minutes ?? 0
        )
    }
}

// courts_with_stats view
struct CourtWithStatsRow: Decodable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let sport_type: String
    let added_by: String
    let created_at: Date
    let image_url: String?
    let local_player_count: Int?
    let is_confirmed: Bool?

    func toCourt() -> Court {
        Court(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            sportType: SportType(rawValue: sport_type.capitalized) ?? .basketball,
            addedBy: added_by,
            addedDate: created_at,
            imageURL: image_url,
            localPlayerCount: local_player_count ?? 0,
            isConfirmed: is_confirmed ?? false
        )
    }
}

struct CourtSummaryRow: Decodable {
    let id: String
    let name: String
}

struct ProfileSummaryRow: Decodable {
    let id: String
    let display_name: String?
    let avatar_url: String?
}

// active_check_ins view
struct ActiveCheckInRow: Decodable {
    let id: String
    let player_id: String?
    let user_id: String?
    let player_name: String?
    let player_avatar_url: String?
    let court_id: String
    let timestamp: Date?
    let note: String?
    let is_active: Bool?

    func toCheckIn() -> CheckIn {
        CheckIn(
            id: id,
            playerID: player_id ?? user_id ?? id,
            playerName: player_name ?? "Player",
            playerAvatarURL: player_avatar_url,
            courtID: court_id,
            timestamp: timestamp ?? Date(),
            note: note,
            isActive: is_active ?? true
        )
    }
}

// feed_posts_with_counts view
struct FeedPostWithCountsRow: Decodable {
    let id: String
    let author_id: String
    let author_name: String?
    let author_avatar_url: String?
    let court_id: String
    let court_name: String?
    let post_type: String
    let content: String
    let timestamp: Date?
    let like_count: Int?

    func toFeedPost() -> FeedPost {
        FeedPost(
            id: id,
            authorID: author_id,
            authorName: author_name ?? "Player",
            authorAvatarURL: author_avatar_url,
            courtID: court_id,
            courtName: court_name ?? "",
            content: content,
            timestamp: timestamp ?? Date(),
            type: FeedPost.PostType(rawValue: post_type) ?? .note,
            likeCount: like_count ?? 0
        )
    }
}

// games_with_counts view
struct GameWithCountsRow: Decodable {
    let id: String
    let court_id: String
    let court_name: String?
    let date: Date?
    let score_a: Int
    let score_b: Int
    let winner_side: String?
    let like_count: Int?
    let comment_count: Int?

    func toGame(participants: [GameParticipantRow], profilesByID: [String: ProfileSummaryRow]) -> Game {
        let teamA = participants.filter { $0.team_side == "A" }.map { p -> PlayerRef in
            let profile = profilesByID[p.user_id]
            return PlayerRef(
                id: p.user_id,
                displayName: profile?.display_name ?? "Player",
                avatarURL: profile?.avatar_url
            )
        }
        let teamB = participants.filter { $0.team_side == "B" }.map { p -> PlayerRef in
            let profile = profilesByID[p.user_id]
            return PlayerRef(
                id: p.user_id,
                displayName: profile?.display_name ?? "Player",
                avatarURL: profile?.avatar_url
            )
        }

        let winner: Game.Team
        if winner_side == "A" {
            winner = .teamA
        } else if winner_side == "B" {
            winner = .teamB
        } else {
            winner = score_a >= score_b ? .teamA : .teamB
        }

        return Game(
            id: id,
            courtID: court_id,
            courtName: court_name ?? "",
            date: date ?? Date(),
            teamA: teamA,
            teamB: teamB,
            scoreA: score_a,
            scoreB: score_b,
            winnerTeam: winner,
            likeCount: like_count ?? 0,
            commentCount: comment_count ?? 0
        )
    }
}

// game_participants
struct GameParticipantRow: Decodable {
    let game_id: String
    let user_id: String
    let team_side: String
    let display_order: Int?
}

struct GameMembershipRow: Decodable {
    let game_id: String
}

// scheduled_games
struct ScheduledGameRow: Decodable {
    let id: String
    let court_id: String
    let organizer_id: String
    let title: String
    let note: String?
    let start_time: Date?
    let max_players: Int
    let is_open_invite: Bool
    let status: String

    func toScheduledGame(
        participants: [ScheduledGameParticipantRow],
        organizer: ProfileSummaryRow?,
        court: CourtSummaryRow?,
        participantProfilesByID: [String: ProfileSummaryRow]
    ) -> ScheduledGame {
        let confirmed = participants.map { p -> PlayerRef in
            let profile = participantProfilesByID[p.user_id]
            return PlayerRef(
                id: p.user_id,
                displayName: profile?.display_name ?? "Player",
                avatarURL: profile?.avatar_url
            )
        }
        return ScheduledGame(
            id: id,
            courtID: court_id,
            courtName: court?.name ?? "",
            organizerID: organizer_id,
            organizerName: organizer?.display_name ?? "Organizer",
            date: start_time ?? Date(),
            maxPlayers: max_players,
            confirmedPlayers: confirmed,
            isOpenInvite: is_open_invite,
            title: title,
            note: note
        )
    }
}

// scheduled_game_participants
struct ScheduledGameParticipantRow: Decodable {
    let scheduled_game_id: String
    let user_id: String
    let rsvp_status: String

    var countsTowardAttendance: Bool {
        let normalized = rsvp_status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "confirmed" || normalized == "going"
    }
}
