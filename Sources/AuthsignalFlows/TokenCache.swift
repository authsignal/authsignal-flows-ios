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
  
  public static let shared = TokenCache()
  
  func handleTokenNotSetError<T: Decodable>() -> AuthsignalResponse<T> {
    let error = "A challenge token has not been set. Call 'setChallengeToken' first."
    let errorCode = "token_not_set"
    
    Logger.error("Error: \(error)")
    
    return AuthsignalResponse(error: error, errorCode: errorCode)
  }
}
