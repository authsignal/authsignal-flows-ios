public struct StartSessionRequest: Codable {
  public let actionCode: String
  public let clientId: String
  public let codeChallenge: String
}
