import Foundation

struct StoredSession: Codable {
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Date

  init(tokens: SessionTokens) {
    accessToken = tokens.accessToken
    refreshToken = tokens.refreshToken
    accessTokenExpiresAt = Date().addingTimeInterval(TimeInterval(tokens.accessTokenExpiresInSeconds))
  }
}
