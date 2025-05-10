import Foundation

/// Protocol defining connection behavior for the Authmatech SDK.
@available(iOS 12.0, *)
public protocol ConnectionManager {
    
    /// Performs an HTTP GET request over cellular data.
    /// - Parameters:
    ///   - url: Target URL.
    ///   - accessToken: Optional bearer token for authentication.
    ///   - debug: Enables debug trace logging.
    ///   - operators: MCCMNC string for operator-specific logic.
    ///   - completion: Completion handler with response payload.
    func open(
        url: URL,
        accessToken: String?,
        debug: Bool,
        operators: String?,
        completion: @escaping ([String: Any]) -> Void
    )

    /// Performs an HTTP POST request (deprecated).
    /// - Note: This method is deprecated and will be removed in future releases.
    func post(
        url: URL,
        headers: [String: Any],
        body: String?,
        completion: @escaping ([String: Any]) -> Void
    )
}

/// Result of an HTTP redirect during the connection lifecycle.
public struct RedirectResult {
    public let url: URL?
    public let cookies: [HTTPCookie]?
    
    public init(url: URL?, cookies: [HTTPCookie]?) {
        self.url = url
        self.cookies = cookies
    }
}

/// Custom error type representing various network errors encountered by the SDK.
public enum NetworkError: Error, Equatable {
    case invalidRedirectURL(String)
    case tooManyRedirects
    case connectionFailed(String)
    case connectionCantBeCreated(String)
    case other(String)
}

/// Enum representing the outcome of the connection process.
public enum ConnectionResult {
    case follow(RedirectResult)
    case dataOK(ConnectionResponse)
    case dataErr(ConnectionResponse)
    case err(NetworkError)
}

/// Struct representing an HTTP response returned from the server.
public struct ConnectionResponse {
    public let status: Int
    public let body: Data?
    
    public init(status: Int, body: Data?) {
        self.status = status
        self.body = body
    }
}
