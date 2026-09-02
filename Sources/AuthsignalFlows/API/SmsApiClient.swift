import Foundation

class SmsApiClient: BaseApiClient {
  func challenge(
    challengeToken: String,
    phoneNumber: String?
  ) async throws -> SmsChallengeResponse {
    let url = "\(apiUrl)/v1/client/flows/challenge/sms"

    let body = SmsChallengeRequest(phoneNumber: phoneNumber)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }

  func verify(
    challengeToken: String,
    verificationCode: String
  ) async throws -> VerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/verify/sms"

    let body = SmsVerifyRequest(verificationCode: verificationCode)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}
