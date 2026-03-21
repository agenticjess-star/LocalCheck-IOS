import Foundation

struct AuthSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresAt: Date?
    let user: AuthUser

    var needsRefresh: Bool {
        guard let expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow < 120
    }
}

struct AuthUser: Codable, Sendable {
    let id: String
    let email: String?
    let userMetadata: AuthUserMetadata?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
    }

    var displayNameCandidate: String? {
        userMetadata?.displayName ??
        userMetadata?.fullName ??
        [userMetadata?.givenName, userMetadata?.familyName]
            .compactMap { $0?.trimmedNonEmpty }
            .joined(separator: " ")
            .trimmedNonEmpty ??
        email?.emailLocalPart?
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
            .trimmedNonEmpty
    }

    var usernameCandidate: String? {
        userMetadata?.username ??
        userMetadata?.preferredUsername ??
        email?.emailLocalPart
    }
}

struct AuthUserMetadata: Codable, Sendable {
    let displayName: String?
    let fullName: String?
    let givenName: String?
    let familyName: String?
    let username: String?
    let preferredUsername: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case fullName = "full_name"
        case givenName = "given_name"
        case familyName = "family_name"
        case username
        case preferredUsername = "preferred_username"
    }
}

struct AuthSignUpResult: Sendable {
    let user: AuthUser
    let session: AuthSession?

    var requiresEmailConfirmation: Bool {
        session == nil
    }
}

struct AuthResponseEnvelope: Decodable {
    let access_token: String?
    let refresh_token: String?
    let token_type: String?
    let expires_in: Int?
    let expires_at: Int?
    let user: AuthUser?

    var session: AuthSession? {
        guard let access_token, let refresh_token, let user else { return nil }
        let expiresAtDate: Date?
        if let expires_at {
            expiresAtDate = Date(timeIntervalSince1970: TimeInterval(expires_at))
        } else if let expires_in {
            expiresAtDate = Date().addingTimeInterval(TimeInterval(expires_in))
        } else {
            expiresAtDate = nil
        }

        return AuthSession(
            accessToken: access_token,
            refreshToken: refresh_token,
            tokenType: token_type ?? "bearer",
            expiresAt: expiresAtDate,
            user: user
        )
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var emailLocalPart: String? {
        guard let part = split(separator: "@").first else { return nil }
        let candidate = String(part).trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate.isEmpty ? nil : candidate
    }
}
