import CryptoKit
import Foundation
import Security

final class FlowSession {
  // Temporary until the sign-in action code can be configured on the app client
  private static let actionCode = "signInOrSignUpV2"

  private let api: SessionApiClient
  private let clientId: String?
  private let cache = TokenCache.shared

  init(tenantId: String, apiUrl: String, clientId: String?) {
    self.api = SessionApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.clientId = clientId
  }

  func withChallengeToken<T>(_ operation: (String) async throws -> T) async throws -> T {
    let challengeToken = try await currentOrNewChallengeToken()

    do {
      return try await operation(challengeToken)
    } catch AuthsignalError.sessionExpired {
      guard let clientId else {
        throw AuthsignalError.sessionExpired
      }

      Logger.info("The session has expired. Starting a new session.")

      return try await operation(try await startSession(clientId: clientId))
    }
  }

  private func currentOrNewChallengeToken() async throws -> String {
    if let challengeToken = cache.challengeToken, !cache.isCompleted {
      return challengeToken
    }

    guard let clientId else {
      return try cache.requireChallengeToken()
    }

    return try await startSession(clientId: clientId)
  }

  private func startSession(clientId: String) async throws -> String {
    let codeVerifier = try Self.generateCodeVerifier()

    let response = try await api.start(
      actionCode: Self.actionCode,
      clientId: clientId,
      codeChallenge: Self.codeChallenge(for: codeVerifier)
    )

    cache.challengeToken = response.challengeToken
    cache.codeVerifier = codeVerifier
    cache.isCompleted = false

    return response.challengeToken
  }

  private static func generateCodeVerifier() throws -> String {
    var bytes = [UInt8](repeating: 0, count: 32)

    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    guard status == errSecSuccess else {
      throw AuthsignalError.unexpected(code: "unexpected_error", message: "Unable to generate a code verifier.")
    }

    return Data(bytes).base64URLEncodedString()
  }

  private static func codeChallenge(for codeVerifier: String) -> String {
    return Data(SHA256.hash(data: Data(codeVerifier.utf8))).base64URLEncodedString()
  }
}
