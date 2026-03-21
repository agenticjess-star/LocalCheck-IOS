import Foundation

enum SampleData {
    static let currentPlayer = Player(
        id: "player-me",
        displayName: "Marcus Chen",
        username: "mchen",
        avatarURL: nil,
        eloRating: 1247,
        wins: 48,
        losses: 31,
        localCourtID: "court-1",
        joinDate: Date().addingTimeInterval(-86400 * 120),
        totalCourtTimeMinutes: 4320
    )

    static let players: [Player] = [
        currentPlayer,
        Player(id: "p2", displayName: "Jaylen Thomas", username: "jthomas", avatarURL: nil, eloRating: 1385, wins: 67, losses: 22, localCourtID: "court-1", joinDate: Date().addingTimeInterval(-86400 * 200), totalCourtTimeMinutes: 6200),
        Player(id: "p3", displayName: "DeAndre Williams", username: "dwilliams", avatarURL: nil, eloRating: 1312, wins: 54, losses: 28, localCourtID: "court-1", joinDate: Date().addingTimeInterval(-86400 * 180), totalCourtTimeMinutes: 5100),
        Player(id: "p4", displayName: "Chris Park", username: "cpark", avatarURL: nil, eloRating: 1198, wins: 39, losses: 35, localCourtID: "court-1", joinDate: Date().addingTimeInterval(-86400 * 90), totalCourtTimeMinutes: 2800),
        Player(id: "p5", displayName: "Andre Mitchell", username: "amitchell", avatarURL: nil, eloRating: 1156, wins: 32, losses: 30, localCourtID: "court-1", joinDate: Date().addingTimeInterval(-86400 * 150), totalCourtTimeMinutes: 3400),
        Player(id: "p6", displayName: "Tyler Brooks", username: "tbrooks", avatarURL: nil, eloRating: 1289, wins: 51, losses: 27, localCourtID: "court-1", joinDate: Date().addingTimeInterval(-86400 * 170), totalCourtTimeMinutes: 4900),
        Player(id: "p7", displayName: "Kevin Okafor", username: "kokafor", avatarURL: nil, eloRating: 1134, wins: 28, losses: 34, localCourtID: "court-1", joinDate: Date().addingTimeInterval(-86400 * 60), totalCourtTimeMinutes: 1900),
        Player(id: "p8", displayName: "Ryan Santos", username: "rsantos", avatarURL: nil, eloRating: 1220, wins: 42, losses: 33, localCourtID: "court-1", joinDate: Date().addingTimeInterval(-86400 * 130), totalCourtTimeMinutes: 3700),
    ]

    static let courts: [Court] = [
        Court(id: "court-1", name: "Riverside Park Courts", address: "450 Riverside Dr, New York, NY", latitude: 40.8075, longitude: -73.9626, sportType: .basketball, addedBy: "p2", addedDate: Date().addingTimeInterval(-86400 * 365), imageURL: nil, localPlayerCount: 24, isConfirmed: true),
        Court(id: "court-2", name: "Rucker Park", address: "155th St & Frederick Douglass Blvd", latitude: 40.8295, longitude: -73.9368, sportType: .basketball, addedBy: "p3", addedDate: Date().addingTimeInterval(-86400 * 300), imageURL: nil, localPlayerCount: 67, isConfirmed: true),
        Court(id: "court-3", name: "The Cage - W 4th St", address: "W 4th St & 6th Ave, New York, NY", latitude: 40.7318, longitude: -74.0003, sportType: .basketball, addedBy: "player-me", addedDate: Date().addingTimeInterval(-86400 * 250), imageURL: nil, localPlayerCount: 42, isConfirmed: true),
        Court(id: "court-4", name: "Central Park North Meadow", address: "Central Park, New York, NY", latitude: 40.7968, longitude: -73.9530, sportType: .basketball, addedBy: "p5", addedDate: Date().addingTimeInterval(-86400 * 180), imageURL: nil, localPlayerCount: 18, isConfirmed: true),
        Court(id: "court-5", name: "Prospect Park Courts", address: "Prospect Park, Brooklyn, NY", latitude: 40.6602, longitude: -73.9690, sportType: .basketball, addedBy: "p4", addedDate: Date().addingTimeInterval(-86400 * 120), imageURL: nil, localPlayerCount: 31, isConfirmed: true),
        Court(id: "court-6", name: "Astoria Park Hoops", address: "Astoria Park, Queens, NY", latitude: 40.7786, longitude: -73.9230, sportType: .basketball, addedBy: "p7", addedDate: Date().addingTimeInterval(-86400 * 30), imageURL: nil, localPlayerCount: 3, isConfirmed: false),
        Court(id: "court-7", name: "McCarren Park", address: "McCarren Park, Brooklyn, NY", latitude: 40.7200, longitude: -73.9512, sportType: .basketball, addedBy: "p8", addedDate: Date().addingTimeInterval(-86400 * 15), imageURL: nil, localPlayerCount: 2, isConfirmed: false),
    ]

    static var localCourt: Court {
        courts[0]
    }

    static let checkIns: [CheckIn] = [
        CheckIn(id: "ci1", playerID: "p2", playerName: "Jaylen Thomas", playerAvatarURL: nil, courtID: "court-1", timestamp: Date().addingTimeInterval(-600), note: "Running 5s, need one more", isActive: true),
        CheckIn(id: "ci2", playerID: "p3", playerName: "DeAndre Williams", playerAvatarURL: nil, courtID: "court-1", timestamp: Date().addingTimeInterval(-1800), note: nil, isActive: true),
        CheckIn(id: "ci3", playerID: "p5", playerName: "Andre Mitchell", playerAvatarURL: nil, courtID: "court-1", timestamp: Date().addingTimeInterval(-2400), note: "Shooting around, down for runs", isActive: true),
        CheckIn(id: "ci4", playerID: "p7", playerName: "Kevin Okafor", playerAvatarURL: nil, courtID: "court-1", timestamp: Date().addingTimeInterval(-3600), note: nil, isActive: true),
    ]

    static let courtFeed: [FeedPost] = [
        FeedPost(id: "fp1", authorID: "p2", authorName: "Jaylen Thomas", authorAvatarURL: nil, courtID: "court-1", courtName: "Riverside Park Courts", content: "Running 5s, need one more. Court 2 is open.", timestamp: Date().addingTimeInterval(-600), type: .checkIn, likeCount: 3),
        FeedPost(id: "fp2", authorID: "p6", authorName: "Tyler Brooks", authorAvatarURL: nil, courtID: "court-1", courtName: "Riverside Park Courts", content: "Nets on both rims got replaced today. Finally.", timestamp: Date().addingTimeInterval(-7200), type: .note, likeCount: 12),
        FeedPost(id: "fp3", authorID: "p3", authorName: "DeAndre Williams", authorAvatarURL: nil, courtID: "court-1", courtName: "Riverside Park Courts", content: "Good runs this morning. 4 games deep. See y'all tomorrow.", timestamp: Date().addingTimeInterval(-14400), type: .note, likeCount: 8),
        FeedPost(id: "fp4", authorID: "p4", authorName: "Chris Park", authorAvatarURL: nil, courtID: "court-1", courtName: "Riverside Park Courts", content: "Court is wet from the rain, might clear up by 4pm", timestamp: Date().addingTimeInterval(-28800), type: .note, likeCount: 5),
        FeedPost(id: "fp5", authorID: "p8", authorName: "Ryan Santos", authorAvatarURL: nil, courtID: "court-1", courtName: "Riverside Park Courts", content: "Checked in for evening runs", timestamp: Date().addingTimeInterval(-36000), type: .checkIn, likeCount: 2),
    ]

    static let recentGames: [Game] = [
        Game(id: "g1", courtID: "court-1", courtName: "Riverside Park Courts", date: Date().addingTimeInterval(-3600),
             teamA: [PlayerRef(id: "player-me", displayName: "Marcus Chen", avatarURL: nil), PlayerRef(id: "p2", displayName: "Jaylen Thomas", avatarURL: nil)],
             teamB: [PlayerRef(id: "p3", displayName: "DeAndre Williams", avatarURL: nil), PlayerRef(id: "p4", displayName: "Chris Park", avatarURL: nil)],
             scoreA: 21, scoreB: 17, winnerTeam: .teamA, likeCount: 6, commentCount: 2),
        Game(id: "g2", courtID: "court-1", courtName: "Riverside Park Courts", date: Date().addingTimeInterval(-7200),
             teamA: [PlayerRef(id: "p5", displayName: "Andre Mitchell", avatarURL: nil), PlayerRef(id: "p6", displayName: "Tyler Brooks", avatarURL: nil)],
             teamB: [PlayerRef(id: "player-me", displayName: "Marcus Chen", avatarURL: nil), PlayerRef(id: "p7", displayName: "Kevin Okafor", avatarURL: nil)],
             scoreA: 21, scoreB: 19, winnerTeam: .teamA, likeCount: 4, commentCount: 1),
        Game(id: "g3", courtID: "court-1", courtName: "Riverside Park Courts", date: Date().addingTimeInterval(-86400),
             teamA: [PlayerRef(id: "p2", displayName: "Jaylen Thomas", avatarURL: nil), PlayerRef(id: "p8", displayName: "Ryan Santos", avatarURL: nil)],
             teamB: [PlayerRef(id: "p3", displayName: "DeAndre Williams", avatarURL: nil), PlayerRef(id: "p5", displayName: "Andre Mitchell", avatarURL: nil)],
             scoreA: 15, scoreB: 21, winnerTeam: .teamB, likeCount: 9, commentCount: 3),
        Game(id: "g4", courtID: "court-3", courtName: "The Cage - W 4th St", date: Date().addingTimeInterval(-86400 * 2),
             teamA: [PlayerRef(id: "player-me", displayName: "Marcus Chen", avatarURL: nil), PlayerRef(id: "p6", displayName: "Tyler Brooks", avatarURL: nil)],
             teamB: [PlayerRef(id: "p4", displayName: "Chris Park", avatarURL: nil), PlayerRef(id: "p8", displayName: "Ryan Santos", avatarURL: nil)],
             scoreA: 21, scoreB: 12, winnerTeam: .teamA, likeCount: 11, commentCount: 5),
        Game(id: "g5", courtID: "court-1", courtName: "Riverside Park Courts", date: Date().addingTimeInterval(-86400 * 3),
             teamA: [PlayerRef(id: "p7", displayName: "Kevin Okafor", avatarURL: nil), PlayerRef(id: "player-me", displayName: "Marcus Chen", avatarURL: nil)],
             teamB: [PlayerRef(id: "p2", displayName: "Jaylen Thomas", avatarURL: nil), PlayerRef(id: "p3", displayName: "DeAndre Williams", avatarURL: nil)],
             scoreA: 18, scoreB: 21, winnerTeam: .teamB, likeCount: 7, commentCount: 2),
    ]

    static let scheduledGames: [ScheduledGame] = [
        ScheduledGame(id: "sg1", courtID: "court-1", courtName: "Riverside Park Courts", organizerID: "p2", organizerName: "Jaylen Thomas", date: Date().addingTimeInterval(3600 * 3), maxPlayers: 10, confirmedPlayers: [
            PlayerRef(id: "p2", displayName: "Jaylen Thomas", avatarURL: nil),
            PlayerRef(id: "player-me", displayName: "Marcus Chen", avatarURL: nil),
            PlayerRef(id: "p3", displayName: "DeAndre Williams", avatarURL: nil),
            PlayerRef(id: "p5", displayName: "Andre Mitchell", avatarURL: nil),
            PlayerRef(id: "p6", displayName: "Tyler Brooks", avatarURL: nil),
            PlayerRef(id: "p8", displayName: "Ryan Santos", avatarURL: nil),
        ], isOpenInvite: true, title: "Evening 5v5 Runs", note: "Full court. Winners stay."),
        ScheduledGame(id: "sg2", courtID: "court-1", courtName: "Riverside Park Courts", organizerID: "p4", organizerName: "Chris Park", date: Date().addingTimeInterval(86400 + 3600 * 10), maxPlayers: 8, confirmedPlayers: [
            PlayerRef(id: "p4", displayName: "Chris Park", avatarURL: nil),
            PlayerRef(id: "p7", displayName: "Kevin Okafor", avatarURL: nil),
            PlayerRef(id: "player-me", displayName: "Marcus Chen", avatarURL: nil),
        ], isOpenInvite: true, title: "Morning Shootaround", note: "Light work. 3v3 half court."),
        ScheduledGame(id: "sg3", courtID: "court-3", courtName: "The Cage - W 4th St", organizerID: "p6", organizerName: "Tyler Brooks", date: Date().addingTimeInterval(86400 * 2 + 3600 * 16), maxPlayers: 10, confirmedPlayers: [
            PlayerRef(id: "p6", displayName: "Tyler Brooks", avatarURL: nil),
            PlayerRef(id: "p2", displayName: "Jaylen Thomas", avatarURL: nil),
        ], isOpenInvite: false, title: "Competitive 5s", note: "Invite only. Bring your A-game."),
        ScheduledGame(id: "sg4", courtID: "court-1", courtName: "Riverside Park Courts", organizerID: "player-me", organizerName: "Marcus Chen", date: Date().addingTimeInterval(86400 * 4 + 3600 * 14), maxPlayers: 6, confirmedPlayers: [
            PlayerRef(id: "player-me", displayName: "Marcus Chen", avatarURL: nil),
        ], isOpenInvite: true, title: "3v3 King of the Court", note: nil),
    ]

    static let topOpponents: [(Player, Int)] = [
        (players[1], 18),
        (players[2], 14),
        (players[5], 11),
        (players[3], 9),
        (players[7], 7),
    ]
}
