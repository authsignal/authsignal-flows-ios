public struct RespondToPushChallengeRequest: Codable {
  public let publicKey: String
  public let challengeId: String
  public let signature: String
  public let approved: Bool
  public let verificationCode: String?
}

struct RespondToPushChallengeResponse: Codable {
  let isVerified: Bool
}
