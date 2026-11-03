import Foundation
import Security
import UIKit

public class AuthsignalFlows {
  public let email: AuthsignalEmail
  public let sms: AuthsignalSms
  public let whatsapp: AuthsignalWhatsapp
  public let passkey: AuthsignalPasskey

  public init(tenantId: String, apiUrl: String, clientId: String? = nil) {
    let session = FlowSession(tenantId: tenantId, apiUrl: apiUrl, clientId: clientId)

    email = AuthsignalEmail(tenantId: tenantId, apiUrl: apiUrl, session: session)
    sms = AuthsignalSms(tenantId: tenantId, apiUrl: apiUrl, session: session)
    whatsapp = AuthsignalWhatsapp(tenantId: tenantId, apiUrl: apiUrl)
    passkey = AuthsignalPasskey(tenantId: tenantId, apiUrl: apiUrl, session: session)
  }

  public func setChallengeToken(challengeToken: String) {
    TokenCache.shared.challengeToken = challengeToken
    TokenCache.shared.codeVerifier = nil
  }
}
