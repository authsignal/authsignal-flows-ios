import Foundation
import Security

enum AppCredentialType: String {
  case inApp = "in-app"
  case push = "push"
}

class AppCredentialApiClient: BaseApiClient {
  func createSignedRequest(
    credentialType: AppCredentialType,
    publicKey: String,
    privateKey: SecKey
  ) async throws -> SignedRequest {
    let url = "\(apiUrl)/v1/client/flows/user-authenticators/\(credentialType.rawValue)/sign"

    let challenge: SigningChallengeResponse = try await postRequest(
      url: url,
      body: SigningChallengeRequest(publicKey: publicKey)
    )

    let signature = try Signer.sign(message: challenge.message, privateKey: privateKey)

    return SignedRequest(publicKey: publicKey, signingChallengeId: challenge.signingChallengeId, signature: signature)
  }

  func removeCredential(
    credentialType: AppCredentialType,
    signedRequest: SignedRequest
  ) async throws -> RemoveCredentialResponse {
    let url = "\(apiUrl)/v1/client/flows/user-authenticators/\(credentialType.rawValue)/remove"

    return try await postRequest(url: url, body: signedRequest)
  }
}
