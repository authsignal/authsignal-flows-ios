import Foundation
import UIKit

public class AuthsignalPush {
  private let api: PushApiClient
  private let appCredentials: AppCredentialApiClient
  private let flow: FlowContext
  private let cache = TokenCache.shared
  private let keyManager = KeyManager(keySuffix: "push")

  init(tenantId: String, apiUrl: String, flow: FlowContext) {
    self.api = PushApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.appCredentials = AppCredentialApiClient(tenantId: tenantId, apiUrl: apiUrl)
    self.flow = flow
  }

  public func challenge() async throws -> PushChallengeResponse {
    let challengeToken = try cache.requireChallengeToken()

    return try await api.challenge(challengeToken: challengeToken)
  }

  public func verify() async throws -> PushVerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    let response = try await api.verify(challengeToken: challengeToken)

    if response.status == .approved,
       let action = response.action,
       let updatedChallengeToken = response.challengeToken,
       let user = response.user
    {
      try await flow.update(with: VerifyResponse(action: action, challengeToken: updatedChallengeToken, user: user))
    }

    return response
  }

  public func getCredential() async throws -> AppCredential? {
    guard let publicKey = keyManager.getPublicKey() else {
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
    pushToken: String? = nil,
    keychainAccess: KeychainAccess = .whenUnlockedThisDeviceOnly,
    userPresenceRequired: Bool = false
  ) async throws -> VerifyResponse {
    let challengeToken = try cache.requireChallengeToken()

    guard let publicKey = keyManager.getOrCreatePublicKey(
      keychainAccess: keychainAccess,
      userPresenceRequired: userPresenceRequired
    ) else {
      throw AuthsignalError.unexpected(code: SdkErrorCodes.createKeyPairFailed, message: "Error creating key pair.")
    }

    let deviceName = await UIDevice.current.name

    let response = try await api.addCredential(
      challengeToken: challengeToken,
      publicKey: publicKey,
      deviceName: deviceName,
      pushToken: pushToken
    )

    try await flow.update(with: response)

    return response
  }

  public func removeCredential() async throws {
    let (privateKey, publicKey) = try requireKey()

    let signedRequest = try await appCredentials.createSignedRequest(
      credentialType: .push,
      publicKey: publicKey,
      privateKey: privateKey
    )

    _ = try await appCredentials.removeCredential(credentialType: .push, signedRequest: signedRequest)

    _ = keyManager.deleteKeyPair()
  }

  public func updateCredential(pushToken: String? = nil, resetExpiry: Bool = false) async throws {
    let (privateKey, publicKey) = try requireKey()

    let signingMessage = try await api.getSigningMessage(publicKey: publicKey)

    guard let challengeId = signingMessage.challengeId, let message = signingMessage.message else {
      throw AuthsignalError.apiError(message: "Invalid signing message response.")
    }

    let signature = try Signer.sign(message: message, privateKey: privateKey)

    _ = try await api.updateCredential(
      UpdatePushCredentialRequest(
        challengeId: challengeId,
        publicKey: publicKey,
        signature: signature,
        pushToken: pushToken,
        resetExpiry: resetExpiry ? true : nil
      )
    )
  }

  public func getChallenge() async throws -> PushChallenge? {
    let (privateKey, publicKey) = try requireKey()

    let signedRequest = try await appCredentials.createSignedRequest(
      credentialType: .push,
      publicKey: publicKey,
      privateKey: privateKey
    )

    let response = try await api.getPendingChallenge(signedRequest)

    guard let challengeId = response.challengeId else {
      return nil
    }

    return PushChallenge(
      challengeId: challengeId,
      actionCode: response.actionCode,
      deviceId: response.deviceId,
      userAgent: response.userAgent,
      ipAddress: response.ipAddress,
      expiresAt: response.expiresAt
    )
  }

  public func updateChallenge(challengeId: String, approved: Bool, verificationCode: String? = nil) async throws {
    let (privateKey, publicKey) = try requireKey()

    let signature = try Signer.sign(message: challengeId, privateKey: privateKey)

    _ = try await api.respondToChallenge(
      RespondToPushChallengeRequest(
        publicKey: publicKey,
        challengeId: challengeId,
        signature: signature,
        approved: approved,
        verificationCode: verificationCode
      )
    )
  }

  private func requireKey() throws -> (SecKey, String) {
    guard let privateKey = keyManager.getKey(), let publicKey = keyManager.getPublicKey() else {
      throw AuthsignalError.credentialNotFound
    }

    return (privateKey, publicKey)
  }
}
