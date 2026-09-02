import Foundation
import Security
import UIKit

public class AuthsignalEmail {
  private let api: EmailApiClient
  private let cache = TokenCache.shared

  public init(tenantId: String, apiUrl: String) {
    self.api = EmailApiClient(tenantId: tenantId, apiUrl: apiUrl)
  }

  public func challenge(email: String? = nil) async throws -> EmailChallengeResponse {
    let challengeToken = try cache.requireChallengeToken()

    return try await api.challenge(challengeToken: challengeToken, email: email)
  }

  public func verify(verificationCode: String) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let verifyResponse = try await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)

    cache.challengeToken = verifyResponse.challengeToken

    return verifyResponse
  }
}
