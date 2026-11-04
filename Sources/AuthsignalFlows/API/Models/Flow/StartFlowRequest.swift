public struct StartFlowRequest: Codable {
  public let actionCode: String
  public let clientId: String
  public let codeChallenge: String
}
