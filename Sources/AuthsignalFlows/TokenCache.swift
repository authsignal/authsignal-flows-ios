import Foundation

public class TokenCache {
  private var _challengeToken: String? = nil

  public var challengeToken: String? {
    get { return _challengeToken }
    set {
      if (!(newValue ?? "").isEmpty) {
        _challengeToken = newValue
      }
    }
  }

  var codeVerifier: String? = nil

  public static let shared = TokenCache()

  func requireChallengeToken() throws -> String {
    guard let challengeToken else {
      Logger.error("Error: A challenge token has not been set. Call 'setChallengeToken' first.")

      throw AuthsignalError.flowNotInitialized
    }

    return challengeToken
  }
}
