import Foundation

class PasskeyApiClient: BaseApiClient {
  func authenticationOptions(challengeToken: String) async -> AuthsignalResponse<PasskeyAuthenticationOptionsResponse> {
    let url = "\(apiUrl)/v1/client/flows/challenge/passkey"

    return await postRequest(url: url, challengeToken: challengeToken)
  }

  func verify(challengeToken: String, credential: PasskeyAuthenticationCredential) async -> AuthsignalResponse<VerifyResponse> {
    let url = "\(apiUrl)/v1/client/flows/verify/passkey"

    let body = PasskeyVerifyRequest(authenticationResponse: credential)

    return await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}

