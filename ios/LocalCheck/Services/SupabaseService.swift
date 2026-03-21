// ============================================================
// File: ios/LocalCheck/Services/SupabaseService.swift
// ============================================================
// Pure URLSession REST client. Zero dependencies.
// Schema verified against live Supabase project 2026-03-20.
// ============================================================

import Foundation

// MARK: - Config
// IMPORTANT: Replace CURRENT_USER_ID at runtime with Supabase auth UID
// For now it falls back to the seeded profile ID for development

enum SupabaseConfig {
    static let url = "https://jzclwnzcektqhgkkdeje.supabase.co"
    static let anonKey = "sb_publishable_oL6OFCLyIPWUuxv27tqZUQ_1i7WYcHS"
    // TODO: Replace with Supabase Auth → get currentUser.id on sign-in
    static var currentUserID: String = "7d9c399c-9672-4277-9aa3-5acebab78e4e"
}

// MARK: - SupabaseService
actor SupabaseService {
    static let shared = SupabaseService()
    private let base = URL(string: SupabaseConfig.url)!
    private var headers: [String: String] {
        ["apikey": SupabaseConfig.anonKey,
         "Authorization": "Bearer \(SupabaseConfig.anonKey)",
         "Content-Type": "application/json",
         "Prefer": "return=representation"]
    }

    // MARK: - HTTP helpers
    private func get<T: Decodable>(_ table: String, query: [String: String] = [:]) async throws -> T {
        var comps = URLComponents(url: base.appendingPathComponent("/rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var req = URLRequest(url: comps.url!)
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw AppError.server("HTTP \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
        }
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ table: String, body: some Encodable) async throws -> T {
        var req = URLRequest(url: base.appendingPathComponent("/rest/v1/\(table)"))
        req.httpMethod = "POST"
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder.supabase.encode(body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    private func patch(_ table: String, matching: [String: String], body: some Encodable) async throws {
        var comps = URLComponents(url: base.appendingPathComponent("/rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        comps.queryItems = matching.map { URLQueryItem(name: $0.key, value: "eq.\($0.value)") }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "PATCH"
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder.supabase.encode(body)
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Profiles
    func fetchCurrentPlayer() async throws -> Player {
        let rows: [ProfileRow] = try await get("profiles", query: [
            "id": "eq.\(SupabaseConfig.currentUserID)", "select": "*"
        ])
        guard let row = rows.first else { throw AppError.notFound("profile") }
        return row.toPlayer()
    }

    func fetchPlayers(localCourtID: String? = nil) async throws -> [Player] {
        var q: [String: String] = ["select": "*", "order": "elo_rating.desc"]
        if let id = localCourtID { q["local_court_id"] = "eq.\(id)" }
        let rows: [ProfileRow] = try await get("profiles", query: q)
        return rows.map { $0.toPlayer() }
    }

    // MARK: - Courts (use the view which includes stats)
    func fetchCourts() async throws -> [Court] {
        let rows: [CourtWithStatsRow] = try await get("courts_with_stats", query: [
            "select": "*", "order": "local_player_count.desc"
        ])
        return rows.map { $0.toCourt() }
    }

    func fetchLocalCourt() async throws -> Court? {
        let rows: [ProfileRow] = try await get("profiles", query: [
            "id": "eq.\(SupabaseConfig.currentUserID)", "select": "local_court_id"
        ])
        guard let courtID = rows.first?.local_court_id else { return nil }
        let courts: [CourtWithStatsRow] = try await get("courts_with_stats", query: [
            "id": "eq.\(courtID)", "select": "*"
        ])
        return courts.first?.toCourt()
    }

    // MARK: - Check-ins (use the active_check_ins view)
    func fetchActiveCheckIns(courtID: String) async throws -> [CheckIn] {
        let rows: [ActiveCheckInRow] = try await get("active_check_ins", query: [
            "court_id": "eq.\(courtID)", "select": "*", "order": "timestamp.desc"
        ])
        return rows.map { $0.toCheckIn() }
    }

    func checkIn(courtID: String, note: String?) async throws {
        struct Body: Encodable {
            let user_id: String; let court_id: String; let note: String?
        }
        let _: [[String: String]] = try await post("check_ins", body: Body(
            user_id: SupabaseConfig.currentUserID,
            court_id: courtID,
            note: note
        ))
    }

    func checkOut(userID: String, courtID: String) async throws {
        struct Body: Encodable { let checked_out_at: String }
        try await patch("check_ins",
            matching: ["user_id": userID, "court_id": courtID, "checked_out_at": "null"],
            body: Body(checked_out_at: ISO8601DateFormatter().string(from: Date()))
        )
    }

    // MARK: - Feed (use the view which includes author/court names + like counts)
    func fetchCourtFeed(courtID: String) async throws -> [FeedPost] {
        let rows: [FeedPostWithCountsRow] = try await get("feed_posts_with_counts", query: [
            "court_id": "eq.\(courtID)", "select": "*", "order": "timestamp.desc", "limit": "30"
        ])
        return rows.map { $0.toFeedPost() }
    }

    func postToFeed(courtID: String, content: String, type: FeedPost.PostType) async throws {
        struct Body: Encodable {
            let author_id: String; let court_id: String; let content: String; let post_type: String
        }
        let _: [[String: String]] = try await post("feed_posts", body: Body(
            author_id: SupabaseConfig.currentUserID,
            court_id: courtID,
            content: content,
            post_type: type.rawValue
        ))
    }

    // MARK: - Games (use games_with_counts view + participants separately)
    func fetchRecentGames(courtID: String? = nil) async throws -> [Game] {
        var q: [String: String] = ["select": "*", "order": "date.desc", "limit": "20"]
        if let id = courtID { q["court_id"] = "eq.\(id)" }
        let gameRows: [GameWithCountsRow] = try await get("games_with_counts", query: q)
        // Fetch participants for these games
        let gameIDs = gameRows.map { $0.id }.joined(separator: ",")
        guard !gameIDs.isEmpty else { return [] }
        let participants: [GameParticipantRow] = try await get("game_participants", query: [
            "game_id": "in.(\(gameIDs))", "select": "*,profiles(display_name,avatar_url)"
        ])
        return gameRows.map { row in row.toGame(participants: participants.filter { $0.game_id == row.id }) }
    }

    // MARK: - Scheduled games
    func fetchScheduledGames() async throws -> [ScheduledGame] {
        let now = ISO8601DateFormatter().string(from: Date())
        let rows: [ScheduledGameRow] = try await get("scheduled_games", query: [
            "start_time": "gte.\(now)", "select": "*,profiles(display_name),courts(name)",
            "order": "start_time.asc", "status": "neq.cancelled"
        ])
        // Fetch participants
        let ids = rows.map { $0.id }.joined(separator: ",")
        guard !ids.isEmpty else { return rows.map { $0.toScheduledGame(participants: []) } }
        let participants: [ScheduledGameParticipantRow] = try await get("scheduled_game_participants", query: [
            "scheduled_game_id": "in.(\(ids))",
            "rsvp_status": "eq.confirmed",
            "select": "*,profiles(display_name,avatar_url)"
        ])
        return rows.map { row in row.toScheduledGame(participants: participants.filter { $0.scheduled_game_id == row.id }) }
    }

    func rsvpToGame(gameID: String) async throws {
        struct Body: Encodable {
            let scheduled_game_id: String; let user_id: String; let rsvp_status: String
        }
        let _: [[String: String]] = try await post("scheduled_game_participants", body: Body(
            scheduled_game_id: gameID,
            user_id: SupabaseConfig.currentUserID,
            rsvp_status: "confirmed"
        ))
    }

    func createScheduledGame(courtID: String, title: String, note: String?, startTime: Date, maxPlayers: Int, isOpenInvite: Bool) async throws {
        struct Body: Encodable {
            let court_id: String; let organizer_id: String; let title: String; let note: String?
            let start_time: Date; let max_players: Int; let is_open_invite: Bool; let status: String
        }
        let _: [[String: String]] = try await post("scheduled_games", body: Body(
            court_id: courtID, organizer_id: SupabaseConfig.currentUserID,
            title: title, note: note, start_time: startTime,
            max_players: maxPlayers, is_open_invite: isOpenInvite, status: "scheduled"
        ))
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
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"
            ]
            let f = DateFormatter()
            for fmt in fmts {
                f.dateFormat = fmt
                if let d = f.date(from: s) { return d }
            }
            if let d = ISO8601DateFormatter().date(from: s) { return d }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Cannot decode date: \(s)")
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
        case .notFound(let s): return "Not found: \(s)"
        case .server(let s): return "Server error: \(s)"
        }
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
    let id: String; let name: String; let address: String
    let latitude: Double; let longitude: Double; let sport_type: String
    let added_by: String; let created_at: Date
    let image_url: String?; let local_player_count: Int?; let is_confirmed: Bool?

    func toCourt() -> Court {
        Court(
            id: id, name: name, address: address,
            latitude: latitude, longitude: longitude,
            sportType: SportType(rawValue: sport_type.capitalized) ?? .basketball,
            addedBy: added_by, addedDate: created_at,
            imageURL: image_url,
            localPlayerCount: local_player_count ?? 0,
            isConfirmed: is_confirmed ?? false
        )
    }
}

// active_check_ins view
struct ActiveCheckInRow: Decodable {
    let id: String; let player_id: String; let player_name: String?
    let player_avatar_url: String?; let court_id: String
    let timestamp: Date?; let note: String?; let is_active: Bool?

    func toCheckIn() -> CheckIn {
        CheckIn(
            id: id, playerID: player_id,
            playerName: player_name ?? "Player",
            playerAvatarURL: player_avatar_url,
            courtID: court_id,
            timestamp: timestamp ?? Date(),
            note: note, isActive: is_active ?? true
        )
    }
}

// feed_posts_with_counts view
struct FeedPostWithCountsRow: Decodable {
    let id: String; let author_id: String; let author_name: String?
    let author_avatar_url: String?; let court_id: String; let court_name: String?
    let post_type: String; let content: String; let timestamp: Date?; let like_count: Int?

    func toFeedPost() -> FeedPost {
        FeedPost(
            id: id, authorID: author_id,
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
    let id: String; let court_id: String; let court_name: String?
    let date: Date?; let score_a: Int; let score_b: Int
    let winner_side: String?; let like_count: Int?; let comment_count: Int?

    func toGame(participants: [GameParticipantRow]) -> Game {
        let teamA = participants.filter { $0.team_side == "A" }.map {
            PlayerRef(id: $0.user_id, displayName: $0.profiles?.display_name ?? "Player", avatarURL: $0.profiles?.avatar_url)
        }
        let teamB = participants.filter { $0.team_side == "B" }.map {
            PlayerRef(id: $0.user_id, displayName: $0.profiles?.display_name ?? "Player", avatarURL: $0.profiles?.avatar_url)
        }
        return Game(
            id: id, courtID: court_id, courtName: court_name ?? "",
            date: date ?? Date(), teamA: teamA, teamB: teamB,
            scoreA: score_a, scoreB: score_b,
            winnerTeam: winner_side == "A" ? .teamA : .teamB,
            likeCount: like_count ?? 0, commentCount: comment_count ?? 0
        )
    }
}

// game_participants
struct GameParticipantRow: Decodable {
    let game_id: String; let user_id: String; let team_side: String
    let profiles: ProfileEmbed?
    struct ProfileEmbed: Decodable { let display_name: String?; let avatar_url: String? }
}

// scheduled_games
struct ScheduledGameRow: Decodable {
    let id: String; let court_id: String; let organizer_id: String
    let title: String; let note: String?; let start_time: Date?
    let max_players: Int; let is_open_invite: Bool; let status: String
    let profiles: OrganizerEmbed?; let courts: CourtEmbed?

    struct OrganizerEmbed: Decodable { let display_name: String? }
    struct CourtEmbed: Decodable { let name: String }

    func toScheduledGame(participants: [ScheduledGameParticipantRow]) -> ScheduledGame {
        let confirmed = participants.map {
            PlayerRef(id: $0.user_id, displayName: $0.profiles?.display_name ?? "Player", avatarURL: $0.profiles?.avatar_url)
        }
        return ScheduledGame(
            id: id, courtID: court_id, courtName: courts?.name ?? "",
            organizerID: organizer_id, organizerName: profiles?.display_name ?? "Organizer",
            date: start_time ?? Date(), maxPlayers: max_players,
            confirmedPlayers: confirmed, isOpenInvite: is_open_invite,
            title: title, note: note
        )
    }
}

// scheduled_game_participants
struct ScheduledGameParticipantRow: Decodable {
    let scheduled_game_id: String; let user_id: String; let rsvp_status: String
    let profiles: ProfileEmbed?
    struct ProfileEmbed: Decodable { let display_name: String?; let avatar_url: String? }
}
