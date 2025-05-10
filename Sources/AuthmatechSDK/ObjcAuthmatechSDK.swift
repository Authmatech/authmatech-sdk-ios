import Foundation
import CoreTelephony

/// A bridged Objective-C wrapper for the Swift-native AuthmatechSDK.
/// Designed for compatibility with Kotlin Multiplatform Mobile (KMM) and Objective-C environments.
@objcMembers
@available(iOS 12.0, *)
public class ObjcAuthmatechSDK: NSObject {
    
    private let sdk: AuthmatechSDK

    // MARK: - Initializers

    /// Initialize with default connection manager (CellularConnectionManager with default timeout)
     public override init() {
        self.sdk = AuthmatechSDK()
        super.init()
    }

    /// Initialize with a specific connection timeout (in seconds)
     public init(connectionTimeout: Double) {
        self.sdk = AuthmatechSDK(connectionTimeout: connectionTimeout)
        super.init()
    }

    // MARK: - Public Methods

    /// Performs an HTTP GET request using cellular data without access token
     public func openWithDataCellular(url: URL, debug: Bool, completion: @escaping (NSDictionary) -> Void) {
        sdk.openWithDataCellular(url: url, debug: debug) { result in
            completion(result as NSDictionary)
        }
    }

    /// Performs an HTTP GET request using cellular data with optional access token
     public func openWithDataCellularAndAccessToken(url: URL, accessToken: String?, debug: Bool, completion: @escaping (NSDictionary) -> Void) {
        sdk.openWithDataCellularAndAccessToken(url: url, accessToken: accessToken, debug: debug) { result in
            completion(result as NSDictionary)
        }
    }

    /// Deprecated: Performs a POST over cellular data (will be removed in the next release)
    @available(*, deprecated, message: "This method will be removed in the next release.")
     public func postWithCellularData(url: URL, headers: NSDictionary, body: String?, completion: @escaping (NSDictionary) -> Void) {
        let convertedHeaders = headers as? [String: Any] ?? [:]
        sdk.postWithCellularData(url: url, headers: convertedHeaders, body: body) { result in
            completion(result as NSDictionary)
        }
    }
}
