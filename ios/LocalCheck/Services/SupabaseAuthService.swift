import Foundation

actor SupabaseAuthService {
    static let shared = SupabaseAuthService()

    private let base = URL(string: SupabaseConfig.url)!

    private func headers(authToken: String? = nil) -> [String: String] {
        var result = [
            "apikey": SupabaseConfig.anonKey,
            "Content-Type": "application/json",
        ]
        if let authToken {
            result["Authorization"] = "Bearer \(authToken)"
        }
        return result
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        guard httpResponse.statusCode < 400 else {
            let message = parseErrorMessage(from: data)
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw AuthError.unauthorized(message)
            }
            throw AuthError.server(message)
        }
        return data
    }

    private func requestURL(path: String, query: [String: String] = [:]) -> URL {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(url: base.appendingPathComponent(normalizedPath), resolvingAgainstBaseURL: true)!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }

    private func post<T: Decodable>(
        path: String,
        query: [String: String] = [:],
        body: some Encodable,
        authToken: String? = nil
    ) async throws -> T {
        var request = URLRequest(url: requestURL(path: path, query: query))
        request.httpMethod = "POST"
        headers(authToken: authToken).forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONEncoder.supabase.encode(body)
        let data = try await responseData(for: request)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    private func postNoResponse(
        path: String,
        query: [String: String] = [:],
        authToken: String? = nil
    ) async throws {
        var request = URLRequest(url: requestURL(path: path, query: query))
        request.httpMethod = "POST"
        headers(authToken: authToken).forEach { request.setValue($1, forHTTPHeaderField: $0) }
        _ = try await responseData(for: request)
    }

    private func get<T: Decodable>(path: String, authToken: String) async throws -> T {
        var request = URLRequest(url: requestURL(path: path))
        headers(authToken: authToken).forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let data = try await responseData(for: request)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    private func persist(_ session: AuthSession?) throws {
        guard let session else {
            try SecureStore.delete(account: SupabaseConfig.sessionKeychainAccount)
            return
        }
        let data = try JSONEncoder.supabase.encode(session)
        try SecureStore.save(data, account: SupabaseConfig.sessionKeychainAccount)
    }

    private func storedSession() throws -> AuthSession? {
        guard let data = try SecureStore.load(account: SupabaseConfig.sessionKeychainAccount) else {
            return nil
        }
        return try JSONDecoder.supabase.decode(AuthSession.self, from: data)
    }

    func restoreSession() async throws -> AuthSession? {
        guard let session = try storedSession() else { return nil }

        if session.needsRefresh {
            return try await refreshSession(refreshToken: session.refreshToken)
        }

        do {
            let user = try await fetchUser(accessToken: session.accessToken)
            let validatedSession = AuthSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                tokenType: session.tokenType,
                expiresAt: session.expiresAt,
                user: user
            )
            try persist(validatedSession)
            return validatedSession
        } catch AuthError.unauthorized {
            return try await refreshSession(refreshToken: session.refreshToken)
        } catch {
            // Preserve a valid local session if the network is transiently unavailable.
            return session
        }
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        struct Body: Encodable {
            let email: String
            let password: String
        }

        let response: AuthResponseEnvelope = try await post(
            path: "/auth/v1/token",
            query: ["grant_type": "password"],
            body: Body(email: email, password: password)
        )

        guard let session = response.session else {
            throw AuthError.invalidResponse
        }

        try persist(session)
        return session
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthSignUpResult {
        struct Metadata: Encodable {
            let display_name: String
            let full_name: String
        }

        struct Body: Encodable {
            let email: String
            let password: String
            let data: Metadata
        }

        let response: AuthResponseEnvelope = try await post(
            path: "/auth/v1/signup",
            body: Body(
                email: email,
                password: password,
                data: Metadata(display_name: displayName, full_name: displayName)
            )
        )

        guard let user = response.user else {
            throw AuthError.invalidResponse
        }

        if let session = response.session {
            try persist(session)
        }

        return AuthSignUpResult(user: user, session: response.session)
    }

    func signInWithApple(idToken: String, rawNonce: String) async throws -> AuthSession {
        struct Body: Encodable {
            let provider: String
            let token: String
            let nonce: String
        }

        let response: AuthResponseEnvelope = try await post(
            path: "/auth/v1/token",
            query: ["grant_type": "id_token"],
            body: Body(provider: "apple", token: idToken, nonce: rawNonce)
        )

        guard let session = response.session else {
            throw AuthError.invalidResponse
        }

        try persist(session)
        return session
    }

    func refreshSession(refreshToken: String) async throws -> AuthSession {
        struct Body: Encodable {
            let refresh_token: String
        }

        let response: AuthResponseEnvelope = try await post(
            path: "/auth/v1/token",
            query: ["grant_type": "refresh_token"],
            body: Body(refresh_token: refreshToken)
        )

        guard let session = response.session else {
            throw AuthError.invalidResponse
        }

        try persist(session)
        return session
    }

    func fetchUser(accessToken: String) async throws -> AuthUser {
        try await get(path: "/auth/v1/user", authToken: accessToken)
    }

    func signOut(accessToken: String?) async {
        if let accessToken {
            try? await postNoResponse(path: "/auth/v1/logout", authToken: accessToken)
        }
        try? persist(nil)
    }

    func clearStoredSession() {
        try? persist(nil)
    }

    private func parseErrorMessage(from data: Data) -> String {
        if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let candidates = [
                decoded["msg"] as? String,
                decoded["message"] as? String,
                decoded["error_description"] as? String,
                decoded["error"] as? String,
            ]
            if let message = candidates.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) }).first,
               !message.isEmpty {
                return message
            }
        }

        if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }

        return "Authentication request failed."
    }
}

enum AuthError: LocalizedError {
    case invalidResponse
    case unauthorized(String)
    case server(String)
    case invalidIdentityToken
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Auth response was incomplete."
        case .unauthorized(let message), .server(let message):
            return message
        case .invalidIdentityToken:
            return "Apple Sign In did not return a valid identity token."
        case .cancelled:
            return nil
        }
    }
}
