import Foundation
import Security
import UIKit

public class AuthsignalEmail {
  private let api: EmailApiClient
  private let session: FlowSession
  private let cache = TokenCache.shared

  init(tenantId: String, apiUrl: String, session: FlowSession) {
    self.api = EmailApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.session = session
  }

  public func challenge(email: String? = nil) async throws -> EmailChallengeResponse {
    return try await session.withChallengeToken { challengeToken in
      try await api.challenge(challengeToken: challengeToken, email: email)
    }
  }

  public func verify(verificationCode: String) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let verifyResponse = try await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)

    cache.challengeToken = verifyResponse.challengeToken

    return verifyResponse
  }
}
