import Foundation

class InAppApiClient: BaseApiClient {
  func getCredential(publicKey: String) async throws -> CredentialResponse {
    let encodedKey = Data(publicKey.utf8).base64URLEncodedString()

    let url = "\(apiUrl)/v1/client/user-authenticators/in-app?publicKey=\(encodedKey)"

    return try await getRequestWithBasicAuth(url: url)
  }

  func addCredential(challengeToken: String, publicKey: String, deviceName: String) async throws -> VerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/user-authenticators/in-app"

    let body = AddInAppCredentialRequest(publicKey: publicKey, deviceName: deviceName, devicePlatform: "ios")

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }

  func challenge(challengeToken: String) async throws -> InAppChallengeResponse {
    let url = "\(apiUrl)/v1/client/flows/challenge/in-app"

    return try await postRequest(url: url, challengeToken: challengeToken)
  }

  func verify(challengeToken: String, publicKey: String, signature: String) async throws -> VerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/verify/in-app"

    let body = SignedCredentialRequest(publicKey: publicKey, signature: signature)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}
