import Foundation

class WhatsappApiClient: BaseApiClient {
  func challenge(
    challengeToken: String,
    phoneNumber: String?
  ) async throws -> WhatsappChallengeResponse {
    let url = "\(apiUrl)/v1/client/flows/challenge/whatsapp"

    let body = WhatsappChallengeRequest(phoneNumber: phoneNumber)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }

  func verify(
    challengeToken: String,
    verificationCode: String
  ) async throws -> VerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/verify/whatsapp"

    let body = WhatsappVerifyRequest(verificationCode: verificationCode)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}
