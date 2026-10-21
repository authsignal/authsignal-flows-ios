import Foundation
import Security
import UIKit

public class AuthsignalPasskey {
  private let api: PasskeyApiClient
  private let events: EventsApiClient
  private let passkeyManager: PasskeyManager
  private let passkeySignalManager = PasskeySignalManager()
  private let passkeyLocalKey = "@as_passkey_credential_id"
  private let cache = TokenCache.shared
  private var isCancelRequested = false

  public init(tenantId: String, apiUrl: String) {
    api = PasskeyApiClient(tenantId: tenantId, apiUrl: apiUrl)
    events = EventsApiClient(tenantId: tenantId, apiUrl: apiUrl)
    passkeyManager = PasskeyManager()
  }

  public func verify(
    autofill: Bool = false,
    preferImmediatelyAvailableCredentials: Bool = true,
    syncCredentials: Bool = false
  ) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    if !isSupported() || (autofill && !isAutofillSupported()) {
      events.appendEventInBackground(
        challengeToken: challengeToken,
        type: .passkeyNotAvailable,
        verificationMethod: "PASSKEY",
        data: ["reason": .string("NOT_SUPPORTED"), "autofill": .bool(autofill)]
      )

      throw AuthsignalError.apiError(message: "iOS version not supported.")
    }

    let opts = try await api.authenticationOptions(challengeToken: challengeToken)

    isCancelRequested = false

    let startedAt = Date()

    let credential: PasskeyAuthenticationCredential

    do {
      credential = try await passkeyManager.auth(
        relyingPartyId: opts.authenticationOptions.rpId,
        challenge: opts.authenticationOptions.challenge,
        autofill: autofill,
        preferImmediatelyAvailableCredentials: preferImmediatelyAvailableCredentials
      )
    } catch {
      appendCeremonyFailureEvent(
        error: error,
        challengeToken: challengeToken,
        startedAt: startedAt,
        autofill: autofill,
        preferImmediatelyAvailableCredentials: preferImmediatelyAvailableCredentials
      )

      throw error
    }

    let verifyResponse = try await api.verify(challengeToken: challengeToken, credential: credential)

    storeCredentialId(credentialId: credential.rawId, username: verifyResponse.user.username)

    cache.challengeToken = verifyResponse.challengeToken

    return verifyResponse
  }

  public func cancel() {
    isCancelRequested = true

    passkeyManager.cancelRequest()
  }

  public func isSupported() -> Bool {
    if #available(iOS 15.0, *) {
      return true
    } else {
      return false
    }
  }

  private func isAutofillSupported() -> Bool {
    if #available(iOS 16.0, *) {
      return true
    } else {
      return false
    }
  }

  private func appendCeremonyFailureEvent(
    error: Error,
    challengeToken: String,
    startedAt: Date,
    autofill: Bool,
    preferImmediatelyAvailableCredentials: Bool
  ) {
    var data: [String: EventDataValue] = [
      "durationMs": .int(Int(Date().timeIntervalSince(startedAt) * 1000)),
      "autofill": .bool(autofill),
      "preferImmediatelyAvailableCredentials": .bool(preferImmediatelyAvailableCredentials),
    ]

    if case AuthsignalError.userCanceled = error {
      if isCancelRequested {
        return
      }

      events.appendEventInBackground(
        challengeToken: challengeToken,
        type: .passkeyCeremonyCancel,
        verificationMethod: "PASSKEY",
        data: data
      )

      return
    }

    data["code"] = .string((error as? AuthsignalError)?.code ?? "unexpected_error")
    data["message"] = .string(error.localizedDescription)

    events.appendEventInBackground(
      challengeToken: challengeToken,
      type: .passkeyError,
      verificationMethod: "PASSKEY",
      data: data
    )
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
