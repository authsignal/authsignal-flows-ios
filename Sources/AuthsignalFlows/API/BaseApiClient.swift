import Foundation

class BaseApiClient {
  let tenantId: String 
  let apiUrl: String


  public init(tenantId: String, apiUrl: String) {
    self.apiUrl = apiUrl
    self.tenantId = tenantId
  }
  
  func postRequest<T: Decodable>(
    url: String,
    challengeToken: String
  ) async -> AuthsignalResponse<T> {
    var request = URLRequest(url: URL(string: url)!)

    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    request.setValue(challengeToken, forHTTPHeaderField: "X-Authsignal-Challenge-Token")

    applyDefaultHeaders(to: &request)

    return await performRequest(request: request)
  }

  
  func postRequest<T: Decodable, TBody: Encodable>(
    url: String,
    body: TBody,
    challengeToken: String
  ) async -> AuthsignalResponse<T> {
    var request = URLRequest(url: URL(string: url)!)

    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    request.setValue(challengeToken, forHTTPHeaderField: "X-Authsignal-Challenge-Token")

    let encoder = JSONEncoder()

    if let encodedBody = try? encoder.encode(body) {
      request.httpBody = encodedBody
    }

    applyDefaultHeaders(to: &request)

    return await performRequest(request: request)
  }

  private func applyDefaultHeaders(to request: inout URLRequest) {
    AuthsignalRequestMetadata.headers(tenantId: tenantId).forEach { name, value in
      request.setValue(value, forHTTPHeaderField: name)
    }
  }

  private func performRequest<T: Decodable>(request: URLRequest) async -> AuthsignalResponse<T> {
    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

      if let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode != 200
      {
        let errorCode = json?["errorCode"] as? String ?? "unexpected_error"
        let errorDescription = json?["errorDescription"] as? String ?? "Unexpected error."
        
         Logger.error("API response error code: \(errorCode)")
         Logger.error("API response error description: \(errorDescription)")

      
        if httpResponse.statusCode == 404 && errorCode == "unexpected_error" {
          return AuthsignalResponse(
            error: "API endpoint not found. Ensure your Authsignal base URL is valid.",
            errorCode: "api_error"
          )
        }
        
        return AuthsignalResponse(error: errorDescription, errorCode: errorCode)
      }

      let decoder = JSONDecoder()

      do {
        let decoded = try decoder.decode(T.self, from: data)

        return AuthsignalResponse(data: decoded)
      } catch let decodingError {
        let detail = Self.describe(decodingError)

        Logger.error("API response decoding error for \(T.self): \(detail)")

        return AuthsignalResponse(error: "Decoding error: \(detail)")
      }
    } catch {
      Logger.error("API request error: \(error).")

      return AuthsignalResponse(error: error.localizedDescription, errorCode: "network_error")
    }
  }

  private static func describe(_ error: Error) -> String {
    guard let decodingError = error as? DecodingError else {
      return error.localizedDescription
    }

    switch decodingError {
    case let .keyNotFound(key, context):
      return "missing key '\(key.stringValue)' at \(context.codingPath.pathString)"
    case let .typeMismatch(type, context):
      return "type mismatch, expected \(type) at \(context.codingPath.pathString): \(context.debugDescription)"
    case let .valueNotFound(type, context):
      return "missing value of type \(type) at \(context.codingPath.pathString)"
    case let .dataCorrupted(context):
      return "data corrupted at \(context.codingPath.pathString): \(context.debugDescription)"
    @unknown default:
      return decodingError.localizedDescription
    }
  }
}

extension Array where Element == CodingKey {
  fileprivate var pathString: String {
    isEmpty ? "root" : map(\.stringValue).joined(separator: ".")
  }
}
