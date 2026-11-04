import Foundation

class FlowApiClient: BaseApiClient {
  func start(
    actionCode: String,
    clientId: String,
    codeChallenge: String
  ) async throws -> StartFlowResponse {
    let url = "\(apiUrl)/v1/client/flows/start"

    let body = StartFlowRequest(actionCode: actionCode, clientId: clientId, codeChallenge: codeChallenge)

    return try await postRequest(url: url, body: body)
  }

  func verify(challengeToken: String, codeVerifier: String) async throws -> VerifyFlowResponse {
    let url = "\(apiUrl)/v1/client/flows/verify"

    let body = VerifyFlowRequest(codeVerifier: codeVerifier)

    return try await postRequest(url: url, body: body, challengeToken: challengeToken)
  }
}
