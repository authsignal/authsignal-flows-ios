import Foundation

class PushApiClient: BaseApiClient {
  func getCredential(publicKey: String) async throws -> CredentialResponse {
    let url = "\(apiUrl)/v1/client/user-authenticators/push?publicKey=\(encode(publicKey))"

    return try await getRequestWithBasicAuth(url: url)
  }

  func addCredential(
    challengeToken: String,
    publicKey: String,
    deviceName: String,
    pushToken: String?
  ) async throws -> VerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/user-authenticators/push"

    let body = AddPushCredentialRequest(
      publicKey: publicKey,
      deviceName: deviceName,
      devicePlatform: "ios",
      pushToken: pushToken
    )

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }

  func getSigningMessage(publicKey: String) async throws -> SigningMessageResponse {
    let url = "\(apiUrl)/v1/client/user-authenticators/push/sign?publicKey=\(encode(publicKey))"

    return try await postRequestWithBasicAuth(url: url)
  }

  func updateCredential(_ body: UpdatePushCredentialRequest) async throws -> UpdatePushCredentialResponse {
    let url = "\(apiUrl)/v1/client/user-authenticators/push"

    return try await patchRequestWithBasicAuth(url: url, body: body)
  }

  func challenge(challengeToken: String) async throws -> PushChallengeResponse {
    let url = "\(apiUrl)/v1/client/flows/challenge/push"

    return try await postRequest(url: url, challengeToken: challengeToken)
  }

  func verify(challengeToken: String) async throws -> PushVerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/verify/push"

    return try await postRequest(url: url, challengeToken: challengeToken)
  }

  func getPendingChallenge(_ signedRequest: SignedRequest) async throws -> PendingPushChallengeResponse {
    let publicKey = encode(signedRequest.publicKey)

    let url =
      "\(apiUrl)/v1/client/flows/user-authenticators/push/challenge?publicKey=\(publicKey)&signingChallengeId=\(signedRequest.signingChallengeId)"

    return try await getRequest(url: url, headers: ["X-Authsignal-Signature": signedRequest.signature])
  }

  func respondToChallenge(_ body: RespondToPushChallengeRequest) async throws -> RespondToPushChallengeResponse {
    let url = "\(apiUrl)/v1/client/flows/user-authenticators/push/challenge"

    return try await postRequest(url: url, body: body)
  }

  private func encode(_ publicKey: String) -> String {
    return Data(publicKey.utf8).base64URLEncodedString()
  }
}
