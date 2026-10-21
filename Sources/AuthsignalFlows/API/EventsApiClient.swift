import Foundation

class EventsApiClient: BaseApiClient {
  func appendEvent(challengeToken: String, event: AppendEventRequest) async throws -> AppendEventResponse {
    let url = "\(apiUrl)/v1/client/flows/challenge/events"

    return try await postRequest(url: url, body: event, challengeToken: challengeToken)
  }

  func appendEventInBackground(
    challengeToken: String,
    type: UserVerificationEventType,
    verificationMethod: String? = nil,
    data: [String: EventDataValue]? = nil
  ) {
    let event = AppendEventRequest(type: type, verificationMethod: verificationMethod, data: data)

    Task {
      do {
        _ = try await appendEvent(challengeToken: challengeToken, event: event)
      } catch {
        Logger.info("Failed to append \(type.rawValue) event: \(error.localizedDescription)")
      }
    }
  }
}
