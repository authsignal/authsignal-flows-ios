import Foundation
import Security
import UIKit

public class AuthsignalSms {
  private let api: SmsApiClient
  private let session: FlowSession
  private let cache = TokenCache.shared

  init(tenantId: String, apiUrl: String, session: FlowSession) {
    self.api = SmsApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.session = session
  }

  public func challenge(phoneNumber: String? = nil) async throws -> SmsChallengeResponse {
    return try await session.withChallengeToken { challengeToken in
      try await api.challenge(challengeToken: challengeToken, phoneNumber: phoneNumber)
    }
  }

  public func verify(verificationCode: String) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let verifyResponse = try await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)

    cache.update(with: verifyResponse)

    return verifyResponse
  }
}
