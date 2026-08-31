import Foundation
import Security
import UIKit

public class AuthsignalFlows {
  public let email: AuthsignalEmail
  public let sms: AuthsignalSms
  public let whatsapp: AuthsignalWhatsapp
  public let passkey: AuthsignalPasskey

  public init(tenantId: String, apiUrl: String) {
    email = AuthsignalEmail(tenantId: tenantId, apiUrl: apiUrl)
    sms = AuthsignalSms(tenantId: tenantId, apiUrl: apiUrl)
    whatsapp = AuthsignalWhatsapp(tenantId: tenantId, apiUrl: apiUrl)
    passkey = AuthsignalPasskey(tenantId: tenantId, apiUrl: apiUrl)
  }

  public func setChallengeToken(challengeToken: String) {
    TokenCache.shared.challengeToken = challengeToken
  }
}
