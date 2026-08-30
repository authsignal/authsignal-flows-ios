import Foundation

class EmailApiClient: BaseApiClient {
  func challenge(
    challengeToken: String,
    email: String? = nil
  ) async -> AuthsignalResponse<EmailChallengeResponse> {
    let url = "\(apiUrl)/v1/client/flows/challenge/email-otp"

    return await postRequest(url: url, challengeToken: challengeToken)
  }

  func verify(
    challengeToken: String,
    verificationCode: String
  ) async -> AuthsignalResponse<VerifyResponse> {
    let url = "\(apiUrl)/v1/client/flows/verify/email-otp"

    let body = EmailVerifyRequest(verificationCode: verificationCode)

    return await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}
    