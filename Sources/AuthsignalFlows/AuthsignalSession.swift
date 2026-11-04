import Foundation

public actor AuthsignalSession {
  private static let refreshLeewaySeconds: TimeInterval = 30

  private let api: SessionApiClient
  private let store = SessionStore()
  private var refreshTask: Task<StoredSession?, Error>?

  init(tenantId: String, apiUrl: String) {
    api = SessionApiClient(tenantId: tenantId, apiUrl: apiUrl)
  }

  /// Returns a valid access token, refreshing it first if it's about to expire.
  ///
  /// - Returns: `nil` if there is no session, or if the session can no longer be refreshed.
  /// - Throws: `AuthsignalError.networkError` if a refresh fails to reach the API. The session is kept.
  public func getAccessToken() async throws -> String? {
    if let refreshTask {
      return try await refreshTask.value?.accessToken
    }

    guard let storedSession = store.load() else {
      return nil
    }

    if storedSession.accessTokenExpiresAt.timeIntervalSinceNow > Self.refreshLeewaySeconds {
      return storedSession.accessToken
    }

    return try await refresh(storedSession)?.accessToken
  }

  /// Ends the session. Local state is always cleared, even if the session can't be revoked on the server.
  public func revoke() async {
    _ = try? await refreshTask?.value

    guard let storedSession = store.load() else {
      return
    }

    store.clear()

    do {
      try await api.revoke(refreshToken: storedSession.refreshToken)
    } catch {
      Logger.error("Error revoking session: \(error.localizedDescription)")
    }
  }

  func save(_ tokens: SessionTokens) {
    store.save(StoredSession(tokens: tokens))
  }

  private func refresh(_ storedSession: StoredSession) async throws -> StoredSession? {
    let task = Task { try await performRefresh(storedSession) }

    refreshTask = task

    defer { refreshTask = nil }

    return try await task.value
  }

  private func performRefresh(_ storedSession: StoredSession) async throws -> StoredSession? {
    do {
      let tokens = try await api.refresh(refreshToken: storedSession.refreshToken)

      let refreshedSession = StoredSession(tokens: tokens)

      store.save(refreshedSession)

      return refreshedSession
    } catch AuthsignalError.flowExpired {
      // The API reports a revoked or expired refresh token as 'invalid_token'
      store.clear()

      return nil
    }
  }
}
