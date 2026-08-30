import Foundation

class EmailApiClient: BaseApiClient {
  func challenge(
    challengeToken: String,
    email: String? = nil
  ) async throws -> EmailChallengeResponse {
    let url = "\(apiUrl)/v1/client/flows/challenge/email-otp"

    return try await postRequest(url: url, challengeToken: challengeToken)
  }

  func verify(
    challengeToken: String,
    verificationCode: String
  ) async throws -> VerifyResponse {
    let url = "\(apiUrl)/v1/client/flows/verify/email-otp"

    let body = EmailVerifyRequest(verificationCode: verificationCode)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}
