import Foundation

class PasskeyApiClient: BaseApiClient {
  func authenticationOptions(challengeToken: String) async throws -> PasskeyAuthenticationOptionsResponse {
    let url = "\(apiUrl)/v1/client/flows/challenge/passkey"

    return try await postRequest(url: url, challengeToken: challengeToken)
  }

  func verify(challengeToken: String, credential: PasskeyAuthenticationCredential) async throws -> VerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/verify/passkey"

    let body = PasskeyVerifyRequest(authenticationResponse: credential)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}
