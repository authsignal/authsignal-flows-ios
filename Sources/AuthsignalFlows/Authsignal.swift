import Foundation
import Security
import UIKit

public class AuthsignalFlows {
  public let email: AuthsignalEmail
  public let sms: AuthsignalSms
  public let whatsapp: AuthsignalWhatsapp
  public let passkey: AuthsignalPasskey
  public let session: AuthsignalSession

  public init(tenantId: String, apiUrl: String, clientId: String? = nil) {
    session = AuthsignalSession(tenantId: tenantId, apiUrl: apiUrl)

    let flow = FlowContext(tenantId: tenantId, apiUrl: apiUrl, clientId: clientId, session: session)

    email = AuthsignalEmail(tenantId: tenantId, apiUrl: apiUrl, flow: flow)
    sms = AuthsignalSms(tenantId: tenantId, apiUrl: apiUrl, flow: flow)
    whatsapp = AuthsignalWhatsapp(tenantId: tenantId, apiUrl: apiUrl, flow: flow)
    passkey = AuthsignalPasskey(tenantId: tenantId, apiUrl: apiUrl, flow: flow)
  }

  public func setChallengeToken(challengeToken: String) {
    TokenCache.shared.challengeToken = challengeToken
    TokenCache.shared.codeVerifier = nil
    TokenCache.shared.isCompleted = false
  }
}
