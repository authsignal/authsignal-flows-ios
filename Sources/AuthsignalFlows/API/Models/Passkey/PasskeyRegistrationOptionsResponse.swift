public struct PasskeyRegistrationOptionsResponse: Codable {
  public let registrationOptions: PasskeyRegistrationOptions
}

public struct PasskeyRegistrationOptions: Codable {
  public let challenge: String
  public let rp: PasskeyRegistrationOptionsRelyingParty
  public let user: PasskeyRegistrationOptionsUser
  public let excludeCredentials: [PasskeyRegistrationOptionsCredential]
}

public struct PasskeyRegistrationOptionsRelyingParty: Codable {
  public let id: String
}

public struct PasskeyRegistrationOptionsUser: Codable {
  public let id: String
  public let name: String
  public let displayName: String
}

public struct PasskeyRegistrationOptionsCredential: Codable {
  public let id: String
  public let type: String
}
