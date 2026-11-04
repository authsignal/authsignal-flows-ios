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
  ) async throws -> T {
    var request = URLRequest(url: URL(string: url)!)

    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    request.setValue(challengeToken, forHTTPHeaderField: "X-Authsignal-Challenge-Token")

    applyDefaultHeaders(to: &request)

    return try await performRequest(request: request)
  }


  func postRequest<T: Decodable, TBody: Encodable>(
    url: String,
    body: TBody,
    challengeToken: String
  ) async throws -> T {
    var request = URLRequest(url: URL(string: url)!)

    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    request.setValue(challengeToken, forHTTPHeaderField: "X-Authsignal-Challenge-Token")

    let encoder = JSONEncoder()

    if let encodedBody = try? encoder.encode(body) {
      request.httpBody = encodedBody
    }

    applyDefaultHeaders(to: &request)

    return try await performRequest(request: request)
  }

  func postRequest<T: Decodable, TBody: Encodable>(
    url: String,
    body: TBody
  ) async throws -> T {
    let request = buildTenantRequest(url: url, body: body)

    return try await performRequest(request: request)
  }

  func postRequestWithoutResponse<TBody: Encodable>(
    url: String,
    body: TBody
  ) async throws {
    let request = buildTenantRequest(url: url, body: body)

    _ = try await send(request: request)
  }

  func getRequestWithBasicAuth<T: Decodable>(url: String) async throws -> T {
    var request = URLRequest(url: URL(string: url)!)

    request.httpMethod = "GET"

    request.setValue(basicAuth(), forHTTPHeaderField: "Authorization")

    applyDefaultHeaders(to: &request)

    return try await performRequest(request: request)
  }

  func postRequestWithBasicAuth<T: Decodable, TBody: Encodable>(url: String, body: TBody) async throws -> T {
    var request = URLRequest(url: URL(string: url)!)

    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    request.setValue(basicAuth(), forHTTPHeaderField: "Authorization")

    if let encodedBody = try? JSONEncoder().encode(body) {
      request.httpBody = encodedBody
    }

    applyDefaultHeaders(to: &request)

    return try await performRequest(request: request)
  }

  private func basicAuth() -> String {
    return "Basic \(Data("\(tenantId):".utf8).base64EncodedString())"
  }

  private func buildTenantRequest<TBody: Encodable>(url: String, body: TBody) -> URLRequest {
    var request = URLRequest(url: URL(string: url)!)

    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    request.setValue(tenantId, forHTTPHeaderField: "X-Authsignal-Tenant")

    let encoder = JSONEncoder()

    if let encodedBody = try? encoder.encode(body) {
      request.httpBody = encodedBody
    }

    applyDefaultHeaders(to: &request)

    return request
  }

  private func applyDefaultHeaders(to request: inout URLRequest) {
    AuthsignalRequestMetadata.headers(tenantId: tenantId).forEach { name, value in
      request.setValue(value, forHTTPHeaderField: name)
    }
  }

  private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
    let data = try await send(request: request)

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch let decodingError {
      let detail = Self.describe(decodingError)

      Logger.error("API response decoding error for \(T.self): \(detail)")

      throw AuthsignalError.decodingError(message: "Decoding error: \(detail)")
    }
  }

  private func send(request: URLRequest) async throws -> Data {
    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await URLSession.shared.data(for: request)
    } catch {
      Logger.error("API request error: \(error).")

      throw AuthsignalError.networkError(message: error.localizedDescription)
    }

    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

    if let httpResponse = response as? HTTPURLResponse,
      !(200..<300).contains(httpResponse.statusCode)
    {
      let errorCode = json?["errorCode"] as? String ?? "unexpected_error"
      let errorDescription = json?["errorDescription"] as? String ?? "Unexpected error."

       Logger.error("API response error code: \(errorCode)")
       Logger.error("API response error description: \(errorDescription)")

      if httpResponse.statusCode == 404 && errorCode == "unexpected_error" {
        throw AuthsignalError.apiError(
          message: "API endpoint not found. Ensure your Authsignal base URL is valid."
        )
      }

      throw AuthsignalError.fromApi(code: errorCode, message: errorDescription)
    }

    return data
  }

  private static func describe(_ error: Error) -> String {
    guard let decodingError = error as? DecodingError else {
      return error.localizedDescription
    }

    switch decodingError {
    case let .keyNotFound(key, context):
      return "Missing key '\(key.stringValue)' at \(context.codingPath.pathString)"
    case let .typeMismatch(type, context):
      return "Type mismatch, expected \(type) at \(context.codingPath.pathString): \(context.debugDescription)"
    case let .valueNotFound(type, context):
      return "Missing value of type \(type) at \(context.codingPath.pathString)"
    case let .dataCorrupted(context):
      return "Data corrupted at \(context.codingPath.pathString): \(context.debugDescription)"
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
