import Foundation
import Security
import UIKit

public class AuthsignalEmail {
  private let api: EmailApiClient
  private let cache = TokenCache.shared

  public init(tenantId: String, apiUrl: String) {
    self.api = EmailApiClient(tenantId: tenantId, apiUrl: apiUrl)
  }
  
  public func challenge() async -> AuthsignalResponse<EmailChallengeResponse> {
    guard let challengeToken = cache.challengeToken else { return cache.handleTokenNotSetError() }
    
    return await api.challenge(challengeToken: challengeToken)
  }
  
  public func verify(verificationCode: String) async -> AuthsignalResponse<VerifyResponse> {
    guard let challengeToken = cache.challengeToken else { return cache.handleTokenNotSetError() }
    
    let verifyResponse = await api.verify(challengeToken: challengeToken, verificationCode: verificationCode)
    
    if let responseToken = verifyResponse.data?.challengeToken {
      cache.challengeToken = responseToken
    }
    
    return verifyResponse
  }
}
