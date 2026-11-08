import Foundation
import Security

class SessionStore {
  private let service = "authsignal_session"
  private let account = "default"
  private let installedKey = "@as_session_store_installed"

  init() {
    if !UserDefaults.standard.bool(forKey: installedKey) {
      clear()

      UserDefaults.standard.set(true, forKey: installedKey)
    }
  }

  func load() -> StoredSession? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess, let data = result as? Data else {
      return nil
    }

    return try? JSONDecoder().decode(StoredSession.self, from: data)
  }

  func save(_ session: StoredSession) {
    guard let sessionData = try? JSONEncoder().encode(session) else {
      Logger.error("Error encoding session.")

      return
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: sessionData,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemAdd(query as CFDictionary, nil)

    if status == errSecDuplicateItem {
      let updateQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account
      ]

      let updateAttributes: [String: Any] = [
        kSecValueData as String: sessionData
      ]

      SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
    } else if status != errSecSuccess {
      Logger.error("Error saving session to keychain: \(status).")
    }
  }

  func clear() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]

    SecItemDelete(query as CFDictionary)
  }
}
