import Foundation
import Security
import UIKit

public class AuthsignalWhatsapp {
  private let api: WhatsappApiClient
  private let flow: FlowContext
  private let cache = TokenCache.shared

  init(tenantId: String, apiUrl: String, flow: FlowContext) {
    self.api = WhatsappApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.flow = flow
  }

  public func challenge(phoneNumber: String? = nil) async throws -> WhatsappChallengeResponse {
    let challengeToken = try cache.requireChallengeToken()

    return try await api.challenge(challengeToken: challengeToken, phoneNumber: phoneNumber)
  }

  public func verify(verificationCode: String) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let verifyResponse = try await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)

    try await flow.update(with: verifyResponse)

    return verifyResponse
  }
}
