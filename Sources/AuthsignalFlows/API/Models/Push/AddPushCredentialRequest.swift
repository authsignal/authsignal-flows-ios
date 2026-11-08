public struct AddPushCredentialRequest: Codable {
  public let publicKey: String
  public let deviceName: String
  public let devicePlatform: String
  public let pushToken: String?
}
