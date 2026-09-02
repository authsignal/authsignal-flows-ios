import Foundation
import Security
import UIKit

public class AuthsignalSms {
  private let api: SmsApiClient
  private let cache = TokenCache.shared

  public init(tenantId: String, apiUrl: String) {
    self.api = SmsApiClient(tenantId: tenantId, apiUrl: apiUrl)
  }

  public func challenge(phoneNumber: String? = nil) async throws -> SmsChallengeResponse {
    let challengeToken = try cache.requireChallengeToken()

    return try await api.challenge(challengeToken: challengeToken, phoneNumber: phoneNumber)
  }

  public func verify(verificationCode: String) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let verifyResponse = try await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)

    cache.challengeToken = verifyResponse.challengeToken

    return verifyResponse
  }
}
