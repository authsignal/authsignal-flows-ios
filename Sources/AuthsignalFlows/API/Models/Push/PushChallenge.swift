public struct PushChallenge: Codable {
  public let challengeId: String
  public let actionCode: String?
  public let deviceId: String?
  public let userAgent: String?
  public let ipAddress: String?
  public let expiresAt: Int?
}

struct PendingPushChallengeResponse: Codable {
  let challengeId: String?
  let actionCode: String?
  let deviceId: String?
  let userAgent: String?
  let ipAddress: String?
  let expiresAt: Int?
}
