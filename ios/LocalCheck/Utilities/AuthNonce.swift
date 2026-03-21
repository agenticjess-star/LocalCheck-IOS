import CryptoKit
import Foundation
import Security

enum AuthNonce {
    static func randomString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        while result.count < length {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess {
                fatalError("Could not generate a secure nonce. OSStatus \(status)")
            }

            if random < charset.count {
                result.append(charset[Int(random)])
            }
        }

        return result
    }

    static func sha256(_ value: String) -> String {
        let data = Data(value.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
