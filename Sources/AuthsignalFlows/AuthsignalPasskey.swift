import Foundation
import Security
import UIKit

public class AuthsignalPasskey {
  private let api: PasskeyApiClient
  private let passkeyManager: PasskeyManager
  private let passkeySignalManager = PasskeySignalManager()
  private let passkeyLocalKey = "@as_passkey_credential_id"
  private let cache = TokenCache.shared

  public init(tenantId: String, apiUrl: String) {
    api = PasskeyApiClient(tenantId: tenantId, apiUrl: apiUrl)
    passkeyManager = PasskeyManager()
  }

  public func verify(
    autofill: Bool = false,
    preferImmediatelyAvailableCredentials: Bool = true,
    syncCredentials: Bool = false
  ) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let opts = try await api.authenticationOptions(challengeToken: challengeToken)

    let credential = try await passkeyManager.auth(
      relyingPartyId: opts.authenticationOptions.rpId,
      challenge: opts.authenticationOptions.challenge,
      autofill: autofill,
      preferImmediatelyAvailableCredentials: preferImmediatelyAvailableCredentials
    )

    let verifyResponse = try await api.verify(challengeToken: challengeToken, credential: credential)

    storeCredentialId(credentialId: credential.rawId, username: verifyResponse.user.username)

    cache.challengeToken = verifyResponse.challengeToken

    return verifyResponse
  }

  public func cancel() {
    passkeyManager.cancelRequest()
  }

  public func isSupported() -> Bool {
    if #available(iOS 15.0, *) {
      return true
    } else {
      return false
    }
  }

  private func storeCredentialId(credentialId: String, username: String?) {
    UserDefaults.standard.set(credentialId, forKey: passkeyLocalKey)

    if let username = username {
      UserDefaults.standard.set(
        credentialId,
        forKey: "\(passkeyLocalKey)_\(username)"
      )
    }
  }
}
