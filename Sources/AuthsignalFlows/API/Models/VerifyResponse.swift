public struct VerifyResponse: Codable {
  public let action: FlowAction
  public let challengeToken: String
  public let user: FlowUser
}

public struct FlowAction: Codable {
  public let state: FlowState
  public let nextStep: ActionStep?
  public let completedSteps: [CompletedActionStep]?
}

public struct ActionStep: Codable {
  public let stepType: ActionStepType
  public let verificationMethods: [VerificationMethod]
}

public struct CompletedActionStep: Codable {
  public let stepType: ActionStepType
  public let verificationMethod: VerificationMethod?
  public let userAuthenticatorId: String?
}

public struct FlowUser: Codable {
  public let userId: String
  public let email: String?
  public let phoneNumber: String?
  public let username: String?
  public let displayName: String?
  public let authenticators: [FlowUserAuthenticator]
}

public struct FlowUserAuthenticator: Codable {
  public let userAuthenticatorId: String
  public let verificationMethod: VerificationMethod
  public let email: String?
  public let phoneNumber: String?
  public let username: String?
  public let displayName: String?
}

public enum ActionStepType: String, Codable {
    case verificationRequired = "VERIFICATION_REQUIRED"
    case enrollmentRequired = "ENROLLMENT_REQUIRED"
    case enrollmentOptional = "ENROLLMENT_OPTIONAL"
}

public enum VerificationMethod: String, Codable {
    case emailOtp = "EMAIL_OTP"
    case sms = "SMS"
    case whatsapp = "WHATSAPP"
    case passkey = "PASSKEY"
    case inapp = "IN_APP"
    case qrCode = "QR_CODE"
    case push = "PUSH"
    case authenticatorApp = "AUTHENTICATOR_APP"
}

public enum FlowState: String, Codable {
    case challengeRequired = "CHALLENGE_REQUIRED"
    case challengeFailed = "CHALLENGE_FAILED"
    case challengeSucceeded = "CHALLENGE_SUCCEEDED"
}
