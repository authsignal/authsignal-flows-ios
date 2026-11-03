import Foundation

class SessionApiClient: BaseApiClient {
  func start(
    actionCode: String,
    clientId: String,
    codeChallenge: String
  ) async throws -> StartSessionResponse {
    let url = "\(apiUrl)/v1/client/flows/start"

    let body = StartSessionRequest(actionCode: actionCode, clientId: clientId, codeChallenge: codeChallenge)

    return try await postRequest(url: url, body: body)
  }
}
