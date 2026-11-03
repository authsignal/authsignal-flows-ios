import Foundation
import Security
import UIKit

public class AuthsignalWhatsapp {
  private let api: WhatsappApiClient
  private let cache = TokenCache.shared

  public init(tenantId: String, apiUrl: String) {
    self.api = WhatsappApiClient(tenantId: tenantId, apiUrl: apiUrl)
  }

  public func challenge(phoneNumber: String? = nil) async throws -> WhatsappChallengeResponse {
    let challengeToken = try cache.requireChallengeToken()

    return try await api.challenge(challengeToken: challengeToken, phoneNumber: phoneNumber)
  }

  public func verify(verificationCode: String) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let verifyResponse = try await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)

    cache.update(with: verifyResponse)

    return verifyResponse
  }
}
