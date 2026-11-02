// The subset of the server's UserVerificationEventType enum this SDK emits. The endpoint validates
// `type` against the full enum and returns 400 for unknown values, so only add members it accepts.
enum UserVerificationEventType: String, Encodable {
  case passkeyCeremonyCancel = "PASSKEY_CEREMONY_CANCEL"
  case passkeyNotAvailable = "PASSKEY_NOT_AVAILABLE"
  case passkeyAlreadyRegistered = "PASSKEY_ALREADY_REGISTERED"
  case passkeyError = "PASSKEY_ERROR"
}

enum EventDataValue: Encodable {
  case string(String)
  case int(Int)
  case bool(Bool)

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .string(let value): try container.encode(value)
    case .int(let value): try container.encode(value)
    case .bool(let value): try container.encode(value)
    }
  }
}

struct AppendEventRequest: Encodable {
  let type: UserVerificationEventType
  let verificationMethod: String?
  let data: [String: EventDataValue]?
}

struct AppendEventResponse: Decodable {
  let type: String
}
