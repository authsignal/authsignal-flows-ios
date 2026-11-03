import Foundation
import Security
import UIKit

public class AuthsignalPasskey {
  private let api: PasskeyApiClient
  private let events: EventsApiClient
  private let passkeyManager: PasskeyManager
  private let passkeySignalManager = PasskeySignalManager()
  private let passkeyLocalKey = "@as_passkey_credential_id"
  private let session: FlowSession
  private let cache = TokenCache.shared
  private var isCancelRequested = false

  init(tenantId: String, apiUrl: String, session: FlowSession) {
    api = PasskeyApiClient(tenantId: tenantId, apiUrl: apiUrl)
    events = EventsApiClient(tenantId: tenantId, apiUrl: apiUrl)
    passkeyManager = PasskeyManager()
    self.session = session
  }

  public func register(
    username: String? = nil,
    displayName: String? = nil
  ) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    if !isSupported() {
      events.appendEventInBackground(
        challengeToken: challengeToken,
        type: .passkeyNotAvailable,
        verificationMethod: "PASSKEY",
        data: ["reason": .string("NOT_SUPPORTED")]
      )

      throw AuthsignalError.apiError(message: "iOS version not supported.")
    }

    let opts = try await api.registrationOptions(
      challengeToken: challengeToken,
      username: username,
      displayName: displayName
    )

    let options = opts.registrationOptions

    isCancelRequested = false

    let startedAt = Date()

    let credential: PasskeyRegistrationCredential

    do {
      credential = try await passkeyManager.register(
        relyingPartyId: options.rp.id,
        challenge: options.challenge,
        userId: options.user.id,
        displayName: options.user.displayName.isEmpty ? options.user.name : options.user.displayName,
        existingCredentialIds: options.excludeCredentials.map { $0.id }
      )
    } catch {
      appendCeremonyFailureEvent(
        error: error,
        challengeToken: challengeToken,
        startedAt: startedAt,
        data: [:]
      )

      throw error
    }

    let registerResponse = try await api.register(challengeToken: challengeToken, credential: credential)

    storeCredentialId(credentialId: credential.rawId, username: options.user.name)

    cache.update(with: registerResponse)

    return registerResponse
  }

  public func verify(
    autofill: Bool = false,
    preferImmediatelyAvailableCredentials: Bool = true,
    syncCredentials: Bool = false
  ) async throws -> VerifyResponse {
    let opts = try await session.withChallengeToken { challengeToken in
      if !isSupported() || (autofill && !isAutofillSupported()) {
        events.appendEventInBackground(
          challengeToken: challengeToken,
          type: .passkeyNotAvailable,
          verificationMethod: "PASSKEY",
          data: ["reason": .string("NOT_SUPPORTED"), "autofill": .bool(autofill)]
        )

        throw AuthsignalError.apiError(message: "iOS version not supported.")
      }

      return try await api.authenticationOptions(challengeToken: challengeToken)
    }

    let challengeToken = try cache.requireChallengeToken()

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
        data: [
          "autofill": .bool(autofill),
          "preferImmediatelyAvailableCredentials": .bool(preferImmediatelyAvailableCredentials),
        ]
      )

      throw error
    }

    let verifyResponse = try await api.verify(challengeToken: challengeToken, credential: credential)

    storeCredentialId(credentialId: credential.rawId, username: verifyResponse.user.username)

    cache.update(with: verifyResponse)

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
    data extraData: [String: EventDataValue]
  ) {
    var data = extraData

    data["durationMs"] = .int(Int(Date().timeIntervalSince(startedAt) * 1000))

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

    if case AuthsignalError.matchedExcludedCredential = error {
      events.appendEventInBackground(
        challengeToken: challengeToken,
        type: .passkeyAlreadyRegistered,
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
