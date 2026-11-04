import Foundation

class SessionApiClient: BaseApiClient {
  func refresh(refreshToken: String) async throws -> SessionTokens {
    let url = "\(apiUrl)/v1/client/sessions/refresh"

    let body = RefreshTokenRequest(refreshToken: refreshToken)

    return try await postRequest(url: url, body: body)
  }

  func revoke(refreshToken: String) async throws {
    let url = "\(apiUrl)/v1/client/sessions/revoke"

    let body = RefreshTokenRequest(refreshToken: refreshToken)

    try await postRequestWithoutResponse(url: url, body: body)
  }
}
