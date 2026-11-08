public struct UpdatePushCredentialRequest: Codable {
  public let challengeId: String
  public let publicKey: String
  public let signature: String
  public let pushToken: String?
  public let resetExpiry: Bool?
}

struct SigningMessageResponse: Codable {
  let challengeId: String?
  let message: String?
}

struct UpdatePushCredentialResponse: Codable {
  let userAuthenticatorId: String
}
