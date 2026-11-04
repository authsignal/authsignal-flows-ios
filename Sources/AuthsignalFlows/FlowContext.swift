import CryptoKit
import Foundation
import Security

final class FlowContext {
  // Temporary until the sign-in action code can be configured on the app client
  private static let actionCode = "signInOrSignUpV2"

  private let api: FlowApiClient
  private let clientId: String?
  private let session: AuthsignalSession
  private let cache = TokenCache.shared

  init(tenantId: String, apiUrl: String, clientId: String?, session: AuthsignalSession) {
    self.api = FlowApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.clientId = clientId
    self.session = session
  }

  func withChallengeToken<T>(_ operation: (String) async throws -> T) async throws -> T {
    let challengeToken = try await currentOrNewChallengeToken()

    do {
      return try await operation(challengeToken)
    } catch AuthsignalError.flowExpired {
      // Only flows started by the SDK have a code verifier; others came from 'setChallengeToken'
      guard let clientId, cache.codeVerifier != nil else {
        throw AuthsignalError.flowExpired
      }

      Logger.info("The flow has expired. Starting a new flow.")

      return try await operation(try await startFlow(clientId: clientId))
    }
  }

  func update(with response: VerifyResponse) async throws {
    cache.update(with: response)

    // Flows started with 'setChallengeToken' are verified by the integrator's backend
    guard response.action.state == .challengeSucceeded, let codeVerifier = cache.codeVerifier else {
      return
    }

    let verifyResponse = try await api.verify(challengeToken: response.challengeToken, codeVerifier: codeVerifier)

    guard let tokens = verifyResponse.session else {
      throw AuthsignalError.unexpected(code: "session_unavailable", message: "The flow completed without a session.")
    }

    await session.save(tokens)
  }

  private func currentOrNewChallengeToken() async throws -> String {
    if let challengeToken = cache.challengeToken, !cache.isCompleted {
      return challengeToken
    }

    guard let clientId else {
      return try cache.requireChallengeToken()
    }

    return try await startFlow(clientId: clientId)
  }

  private func startFlow(clientId: String) async throws -> String {
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
