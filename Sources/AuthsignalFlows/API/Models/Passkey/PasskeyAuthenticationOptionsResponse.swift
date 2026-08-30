public struct PasskeyAuthenticationOptionsResponse: Codable {
  public let authenticationOptions: PasskeyAuthenticationOptions
}

public struct PasskeyAuthenticationOptions: Codable {
  public let challenge: String
  public let rpId: String
  public let allowCredentials: [PasskeyAuthenticationOptionsCredential]
}

public struct PasskeyAuthenticationOptionsCredential: Codable {
  public let id: String
  public let type: String
}