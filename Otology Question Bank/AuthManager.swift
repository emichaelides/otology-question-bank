import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthManager: ObservableObject {
    @Published var user: FirebaseAuth.User?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        user = Auth.auth().currentUser
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
            }
        }
    }

    // MARK: - Email Auth

    func signInWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await FirestoreSync.upsertUserDoc(user: result.user)
    }

    func createAccount(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        await FirestoreSync.upsertUserDoc(user: result.user, displayName: displayName)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Apple Sign In

    /// Call this before presenting the Apple Sign In sheet.
    /// Returns the hashed nonce to set on the ASAuthorizationAppleIDRequest.
    func prepareAppleRequest() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async throws {
        guard let nonce = currentNonce,
              let tokenData = credential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            throw AuthManagerError.invalidCredential
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        let result = try await Auth.auth().signIn(with: firebaseCredential)

        let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.filter { !$0.isEmpty }
        let displayName = nameParts.isEmpty
            ? (result.user.displayName ?? "Resident")
            : nameParts.joined(separator: " ")

        await FirestoreSync.upsertUserDoc(user: result.user, displayName: displayName)
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthManagerError: LocalizedError {
    case invalidCredential
    var errorDescription: String? { "Invalid Apple credential. Please try again." }
}
