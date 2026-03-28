import SwiftUI
import CommonCrypto
import Security

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated: Bool = false
    @Published var currentUserEmail: String?
    @Published var emailVerified: Bool = false

    private let userDefaultsSuite = UserDefaults.standard
    private let keychainService = "com.screentime.auth"

    private init() {
        checkExistingSession()
    }

    // MARK: - Public API

    func signIn(email: String, password: String) async throws {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }

        guard let storedHash = userDefaultsSuite.string(forKey: passwordKey(for: trimmedEmail)),
              let storedSalt = userDefaultsSuite.string(forKey: saltKey(for: trimmedEmail)) else {
            throw AuthError.invalidCredentials
        }

        let inputHash = hashPassword(password, salt: storedSalt)
        guard inputHash == storedHash else {
            throw AuthError.invalidCredentials
        }

        saveSessionToken(for: trimmedEmail)
        isAuthenticated = true
        currentUserEmail = trimmedEmail
        emailVerified = userDefaultsSuite.bool(forKey: emailVerifiedKey(for: trimmedEmail))
    }

    func register(email: String, password: String, name: String) async throws {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, password.count >= 8, !name.isEmpty else {
            throw AuthError.invalidInput
        }

        guard userDefaultsSuite.string(forKey: passwordKey(for: trimmedEmail)) == nil else {
            throw AuthError.emailAlreadyRegistered
        }

        let salt = generateSalt()
        let hashed = hashPassword(password, salt: salt)

        userDefaultsSuite.set(hashed, forKey: passwordKey(for: trimmedEmail))
        userDefaultsSuite.set(salt, forKey: saltKey(for: trimmedEmail))
        userDefaultsSuite.set(name, forKey: nameKey(for: trimmedEmail))

        saveSessionToken(for: trimmedEmail)
        isAuthenticated = true
        currentUserEmail = trimmedEmail
        emailVerified = false
        userDefaultsSuite.set(false, forKey: emailVerifiedKey(for: trimmedEmail))
    }

    func oauthSignIn(token: String, userId: String, email: String, emailVerified: Bool = true) {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        saveSessionToken(for: trimmedEmail)
        saveJWTToken(token)
        isAuthenticated = true
        currentUserEmail = trimmedEmail
        self.emailVerified = emailVerified
        userDefaultsSuite.set(emailVerified, forKey: emailVerifiedKey(for: trimmedEmail))
    }

    func signOut() {
        deleteSessionToken()
        let jwtQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "jwt"
        ]
        SecItemDelete(jwtQuery as CFDictionary)
        isAuthenticated = false
        currentUserEmail = nil
        emailVerified = false
    }

    func checkExistingSession() {
        if let email = loadSessionToken() {
            isAuthenticated = true
            currentUserEmail = email
            emailVerified = userDefaultsSuite.bool(forKey: emailVerifiedKey(for: email))
        }
    }

    // MARK: - Password Hashing (SHA-256 + salt)

    private func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func hashPassword(_ password: String, salt: String) -> String {
        let input = "\(salt)\(password)"
        guard let data = input.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain Session Token

    private func saveSessionToken(for email: String) {
        deleteSessionToken()
        guard let data = email.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "session",
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func saveJWTToken(_ token: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "jwt"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "jwt",
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadSessionToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "session",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteSessionToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "session"
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - UserDefaults Keys

    private func passwordKey(for email: String) -> String { "auth.hash.\(email)" }
    private func saltKey(for email: String) -> String { "auth.salt.\(email)" }
    private func nameKey(for email: String) -> String { "auth.name.\(email)" }
    private func emailVerifiedKey(for email: String) -> String { "auth.emailVerified.\(email)" }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidInput
    case invalidCredentials
    case emailAlreadyRegistered

    var errorDescription: String? {
        switch self {
        case .invalidInput: return "Please fill in all fields correctly."
        case .invalidCredentials: return "Invalid email or password."
        case .emailAlreadyRegistered: return "An account with this email already exists."
        }
    }
}
