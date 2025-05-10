import Foundation
import CoreTelephony

/// A public interface to interact with the Authmatech SDK, enabling data-cellular based connectivity.
@available(iOS 12.0, *)
public final class AuthmatechSDK {

    private static var sharedInstance: AuthmatechSDK?

    public static func initialize() {
        if sharedInstance == nil {
            sharedInstance = AuthmatechSDK()
        }
    }

    public static func getInstance() -> AuthmatechSDK {
        guard let sdk = sharedInstance else {
            fatalError("AuthmatechSDK is not initialized. Call AuthmatechSDK.initialize() first.")
        }
        return sdk
    }

    // MARK: - Properties

    private let connectionManager: ConnectionManager
    private let operators: String?

    // MARK: - Initializers

    /// Creates a new instance with the default cellular connection manager.
    public convenience init() {
        self.init(connectionManager: CellularConnectionManager())
    }

    /// Creates a new instance with a custom connection timeout.
    /// - Parameter connectionTimeout: Timeout for the connection in seconds.
    public convenience init(connectionTimeout: Double) {
        self.init(connectionManager: CellularConnectionManager(connectionTimeout: connectionTimeout))
    }

    /// Internal initializer with dependency injection (for testing or mocking).
    /// - Parameter connectionManager: A custom connection manager conforming to `ConnectionManager`.
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager

        // Get MCCMNCs from all available cellular providers
        let telephonyInfo = CTTelephonyNetworkInfo()
        let mccMncs: [String] = telephonyInfo.serviceSubscriberCellularProviders?.compactMap { _, carrier in
            if let mcc = carrier.mobileCountryCode, let mnc = carrier.mobileNetworkCode {
                return "\(mcc)\(mnc)".trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        } ?? []

        self.operators = mccMncs.isEmpty ? nil : mccMncs.joined(separator: ",")
    }

    // MARK: - Public Methods

    /// Opens a URL over data-cellular connection, with optional debug mode enabled.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - debug: Flag to enable debug and trace info.
    ///   - completion: A closure called on completion with response as a dictionary.
    public func openWithDataCellular(
        url: URL,
        debug: Bool,
        completion: @escaping ([String: Any]) -> Void
    ) {
        connectionManager.open(
            url: url,
            accessToken: nil,
            debug: debug,
            operators: operators,
            completion: { response in
                completion(AuthmatechSDK.mapResponseFields(response))
            }
        )
    }

    /// Opens a URL over data-cellular connection using an optional bearer access token.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - accessToken: Optional Bearer token.
    ///   - debug: Flag to enable debug and trace info.
    ///   - completion: A closure called on completion with response as a dictionary.
    public func openWithDataCellularAndAccessToken(
        url: URL,
        accessToken: String?,
        debug: Bool,
        completion: @escaping ([String: Any]) -> Void
    ) {
        connectionManager.open(
            url: url,
            accessToken: accessToken,
            debug: debug,
            operators: operators,
            completion: { response in
                completion(AuthmatechSDK.mapResponseFields(response))
            }
        )
    }

    /// Deprecated: Performs a POST request using data-cellular connection. Will be removed in future releases.
    @available(*, deprecated, message: "This method is deprecated and will be removed in the next release.")
    public func postWithCellularData(
        url: URL,
        headers: [String: Any],
        body: String?,
        completion: @escaping ([String: Any]) -> Void
    ) {
        connectionManager.post(
            url: url,
            headers: headers,
            body: body,
            completion: completion
        )
    }

    // MARK: - Private Helpers

    private static func mapResponseFields(_ original: [String: Any]) -> [String: Any] {
        var mapped = original

        if var body = mapped["response_body"] as? [String: Any] {
            if let msisdn = body["encMSISDN"] {
                body["authmatechCode"] = msisdn
                body.removeValue(forKey: "encMSISDN")
            }
            if let opId = body["opId"] {
                body["MNOID"] = opId
                body.removeValue(forKey: "opId")
            }
            mapped["response_body"] = body
        }

        return mapped
    }
}
