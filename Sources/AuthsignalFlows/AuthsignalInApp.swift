import Foundation
import UIKit

public class AuthsignalInApp {
  private let api: InAppApiClient
  private let appCredentials: AppCredentialApiClient
  private let flow: FlowContext
  private let cache = TokenCache.shared
  private let keyManager = KeyManager(keySuffix: "in_app")
  private let pinManager = PinManager()

  init(tenantId: String, apiUrl: String, flow: FlowContext) {
    self.api = InAppApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.appCredentials = AppCredentialApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.flow = flow
  }

  public func getCredential(username: String? = nil) async throws -> AppCredential? {
    guard let publicKey = keyManager.getPublicKey(username: username) else {
      return nil
    }

    let response = try await api.getCredential(publicKey: publicKey)

    return AppCredential(
      credentialId: response.userAuthenticatorId,
      createdAt: response.verifiedAt,
      userId: response.userId,
      lastAuthenticatedAt: response.lastVerifiedAt,
      expiresAt: response.expiresAt
    )
  }

  public func addCredential(
    keychainAccess: KeychainAccess = .whenUnlockedThisDeviceOnly,
    userPresenceRequired: Bool = false,
    username: String? = nil
  ) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    guard let publicKey = keyManager.getOrCreatePublicKey(
      keychainAccess: keychainAccess,
      userPresenceRequired: userPresenceRequired,
      username: username
    ) else {
      throw AuthsignalError.unexpected(code: SdkErrorCodes.createKeyPairFailed, message: "Error creating key pair.")
    }

    let deviceName = await UIDevice.current.name

    let response = try await api.addCredential(
      challengeToken: challengeToken,
      publicKey: publicKey,
      deviceName: deviceName
    )

    try await flow.update(with: response)

    return response
  }

  public func removeCredential(username: String? = nil) async throws {
    guard let privateKey = keyManager.getKey(username: username),
          let publicKey = keyManager.getPublicKey(username: username)
    else {
      throw AuthsignalError.credentialNotFound
    }

    let signedRequest = try await appCredentials.createSignedRequest(
      credentialType: .inApp,
      publicKey: publicKey,
      privateKey: privateKey
    )

    _ = try await appCredentials.removeCredential(credentialType: .inApp, signedRequest: signedRequest)

    _ = keyManager.deleteKeyPair(username: username)
  }

  public func verify(username: String? = nil) async throws -> VerifyResponse {
    guard let privateKey = keyManager.getKey(username: username),
          let publicKey = keyManager.getPublicKey(username: username)
    else {
      throw AuthsignalError.credentialNotFound
    }

    let response = try await flow.withChallengeToken { challengeToken in
      let challengeResponse = try await api.challenge(challengeToken: challengeToken)

      let signature = try Signer.sign(message: challengeResponse.challenge, privateKey: privateKey)

      return try await api.verify(challengeToken: challengeToken, publicKey: publicKey, signature: signature)
    }

    try await flow.update(with: response)

    return response
  }

  public func createPin(pin: String, username: String) async throws -> VerifyResponse {
    guard pinManager.validateFormat(pin: pin) else {
      throw AuthsignalError.invalidPinFormat
    }

    let response = try await addCredential(username: username)

    pinManager.createPin(pin: pin, username: username)

    return response
  }

  public func verifyPin(pin: String, username: String) async throws -> VerifyResponse {
    guard pinManager.validatePin(pin: pin, username: username) else {
      throw AuthsignalError.invalidPin
    }

    return try await verify(username: username)
  }

  public func deletePin(username: String) async throws {
    do {
      try await removeCredential(username: username)
    } catch let error as AuthsignalError
      where error.code == SdkErrorCodes.credentialNotFound || error.code == SdkErrorCodes.invalidCredential
    {
      _ = keyManager.deleteKeyPair(username: username)
    }

    pinManager.deletePin(username: username)
  }

  public func getAllPinUsernames() -> [String] {
    return pinManager.getAllUsernames()
  }
}
