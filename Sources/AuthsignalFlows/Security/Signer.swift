import Foundation
import Security

enum Signer {
  private static let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256

  static func sign(message: String, privateKey: SecKey) throws -> String {
    let messageData = Data(message.utf8) as CFData

    guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
      throw AuthsignalError.unexpected(code: "signing_error", message: "Algorithm not supported on this device.")
    }

    var error: Unmanaged<CFError>?

    guard let signature = SecKeyCreateSignature(privateKey, algorithm, messageData, &error) else {
      if let cfError = error?.takeRetainedValue(), CFErrorGetCode(cfError) == errSecUserCanceled {
        throw AuthsignalError.userCanceled
      }

      throw AuthsignalError.unexpected(code: "signing_error", message: "Error signing message.")
    }

    return (signature as Data).base64EncodedString()
  }
}
