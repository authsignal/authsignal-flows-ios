struct SigningChallengeRequest: Codable {
  let publicKey: String
}

struct SigningChallengeResponse: Codable {
  let signingChallengeId: String
  let message: String
}

struct SignedRequest: Codable {
  let publicKey: String
  let signingChallengeId: String
  let signature: String
}
