import Foundation
import Security
import UIKit

public class AuthsignalEmail {
  private let api: EmailApiClient
  private let flow: FlowContext
  private let cache = TokenCache.shared

  init(tenantId: String, apiUrl: String, flow: FlowContext) {
    self.api = EmailApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.flow = flow
  }

  public func challenge(email: String? = nil) async throws -> EmailChallengeResponse {
    return try await flow.withChallengeToken { challengeToken in
      try await api.challenge(challengeToken: challengeToken, email: email)
    }
  }

  public func verify(verificationCode: String) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let verifyResponse = try await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)

    try await flow.update(with: verifyResponse)

    return verifyResponse
  }
}
