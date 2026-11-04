public struct SessionTokens: Codable {
  public let accessToken: String
  public let refreshToken: String
  public let accessTokenExpiresInSeconds: Int
}
