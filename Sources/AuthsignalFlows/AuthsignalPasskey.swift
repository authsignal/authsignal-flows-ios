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
  ) async -> AuthsignalResponse<VerifyResponse> {
    guard let challengeToken = cache.challengeToken else {
      return buildFlowNotInitializedResponse()
    }

    let optsResponse = await api.authenticationOptions(
      challengeToken: challengeToken
    )

    guard let optsData = optsResponse.data else {
      return AuthsignalResponse(
        error: optsResponse.error ?? "Authentication options error.",
        errorCode: optsResponse.errorCode
      )
    }

    let credentialResponse = await passkeyManager.auth(
      relyingPartyId: optsData.authenticationOptions.rpId,
      challenge: optsData.authenticationOptions.challenge,
      autofill: autofill,
      preferImmediatelyAvailableCredentials:
        preferImmediatelyAvailableCredentials
    )

    if let errorCode = credentialResponse.errorCode {
      return AuthsignalResponse(
        error: "Credential response error.",
        errorCode: errorCode
      )
    }

    if let error = credentialResponse.error {
      return AuthsignalResponse(error: error)
    }

    guard let credential = credentialResponse.data else {
      return AuthsignalResponse(error: nil)
    }

    let verifyResponse = await api.verify(
      challengeToken: challengeToken,
      credential: credential
    )

    guard let verifyResponseData = verifyResponse.data else {
      return AuthsignalResponse(
        error: verifyResponse.error ?? "Verify error.",
        errorCode: verifyResponse.errorCode
      )
    }

    storeCredentialId(
      credentialId: credential.rawId,
      username: verifyResponseData.user.username
    )

    cache.challengeToken = verifyResponseData.challengeToken

    return AuthsignalResponse(data: verifyResponseData)
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

  private func buildFlowNotInitializedResponse() -> AuthsignalResponse<
    VerifyResponse
  > {
    return AuthsignalResponse(
      error: "The flow has not been initialized.",
      errorCode: "flow_not_initialized"
    )
  }
}
