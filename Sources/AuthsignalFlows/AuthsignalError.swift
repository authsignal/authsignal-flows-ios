import Foundation


public enum AuthsignalError: Error, LocalizedError {
  case flowNotInitialized
  case sessionExpired
  case networkError(message: String)
  case apiError(message: String)
  case decodingError(message: String)
  case unexpected(code: String, message: String)
  case invalidCode(message: String)
  case userCanceled
  case matchedExcludedCredential

  public var code: String {
    switch self {
    case .flowNotInitialized: return "flow_not_initialized"
    case .sessionExpired: return "session_expired"
    case .invalidCode: return "invalid_code"
    case .userCanceled: return "user_canceled"
    case .matchedExcludedCredential: return "matched_excluded_credential"
    case .networkError: return "network_error"
    case .apiError: return "api_error"
    case .decodingError: return "decoding_error"
    case .unexpected(let code, _): return code
    }
  }

  public var errorDescription: String? {
    switch self {
    case .flowNotInitialized:
      return "The flow has not been initialized. Provide a client ID or call 'setChallengeToken' first."
    case .sessionExpired:
      return "The session has expired. Start a new challenge to continue."
    case .invalidCode(let message):
      return message
    case .userCanceled:
      return "The request was canceled by the user or the device has no passkeys available."
    case .matchedExcludedCredential:
      return "An existing credential is already available for this device."
    case .networkError(let message),
         .apiError(let message),
         .decodingError(let message),
         .unexpected(_, let message):
      return message
    }
  }

  static func fromApi(code: String, message: String) -> AuthsignalError {
    switch code {
    case "invalid_code":
      return .invalidCode(message: message)
    case "invalid_token":
      return .sessionExpired
    default:
      return .unexpected(code: code, message: message)
    }
  }
}
