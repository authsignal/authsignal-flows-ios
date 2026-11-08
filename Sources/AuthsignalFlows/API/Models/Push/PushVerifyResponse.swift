public struct PushVerifyResponse: Codable {
  public let status: PushChallengeStatus
  public let action: FlowAction?
  public let challengeToken: String?
  public let user: FlowUser?
}

public enum PushChallengeStatus: String, Codable {
  case pending = "PENDING"
  case approved = "APPROVED"
  case rejected = "REJECTED"
}
