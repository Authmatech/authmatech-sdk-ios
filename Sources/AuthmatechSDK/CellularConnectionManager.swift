#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif
import Network
import os

typealias ResultHandler = (ConnectionResult) -> Void

let AuthmatechSdkVersion = "1.0.0"

@available(iOS 12.0, *)
class CellularConnectionManager: ConnectionManager {

    private var connection: NWConnection?
    private var timer: Timer?
    private var CONNECTION_TIME_OUT = 5.0
    private let MAX_REDIRECTS = 10
    private var pathMonitor: NWPathMonitor?
    private var checkResponseHandler: ResultHandler!
    private var debugInfo = DebugInfo()

    lazy var traceCollector: TraceCollector = {
        TraceCollector()
    }()

    public convenience init(connectionTimeout: Double) {
        self.init()
        self.CONNECTION_TIME_OUT = connectionTimeout
    }

    func open(url: URL, accessToken: String?, debug: Bool, operators: String?, completion: @escaping ([String : Any]) -> Void) {
        if debug {
            traceCollector.isDebugInfoCollectionEnabled = true
            traceCollector.isConsoleLogsEnabled = true
            traceCollector.startTrace()
        }

        let requestId = UUID().uuidString

        guard let _scheme = url.scheme, let _ = url.host else {
            completion(convertNetworkErrorToDictionary(err: .other("No scheme or host found"), debug: debug))
            return
        }

        guard _scheme.lowercased() == "https" else {
            completion([
                "error": "invalid_scheme",
                "error_description": "Only HTTPS URLs are allowed. Please use HTTPS instead of HTTP."
            ])
            return
        }

        var redirectCount = 0
        checkResponseHandler = { [weak self] response in
            guard let self = self else {
                completion(["error": "sdk_error", "error_description": "Unable to carry on"])
                return
            }

            switch response {
            case .follow(let redirectResult):
                if let url = redirectResult.url {
                    redirectCount += 1
                    if redirectCount <= self.MAX_REDIRECTS {
                        self.traceCollector.addDebug(log: "Redirect found: \(url.absoluteString)")
                        self.traceCollector.addTrace(log: "\nfound redirect: \(url) - \(self.traceCollector.now())")
                        self.createTimer()
                        self.activateConnectionForDataFetch(url: url, accessToken: nil, operators: nil, cookies: redirectResult.cookies, requestId: requestId, completion: self.checkResponseHandler)
                    } else {
                        self.traceCollector.addDebug(log: "MAX Redirects reached \(self.MAX_REDIRECTS)")
                        self.cleanUp()
                        completion(self.convertNetworkErrorToDictionary(err: .tooManyRedirects, debug: debug))
                    }
                } else {
                    self.traceCollector.addDebug(log: "Redirect NOT FOUND")
                    self.cleanUp()
                }
            case .err(let error):
                self.cleanUp()
                self.traceCollector.addDebug(log: "Open completed with \(error.localizedDescription)")
                completion(self.convertNetworkErrorToDictionary(err: error, debug: debug))
            case .dataOK(let connResp):
                self.cleanUp()
                self.traceCollector.addDebug(log: "Data Ok received")
                completion(self.convertConnectionResponseToDictionary(resp: connResp, debug: debug))
            case .dataErr(let connResp):
                self.cleanUp()
                self.traceCollector.addDebug(log: "Data err received")
                completion(self.convertConnectionResponseToDictionary(resp: connResp, debug: debug))
            }
        }

        self.traceCollector.addDebug(log: "url: \(url) - \(self.traceCollector.now())")
        DispatchQueue.main.async {
            self.startMonitoring()
            self.createTimer()
            self.activateConnectionForDataFetch(url: url, accessToken: accessToken, operators: operators, cookies: nil, requestId: requestId, completion: self.checkResponseHandler)
        }
    }

    func convertConnectionResponseToDictionary(resp: ConnectionResponse, debug: Bool) -> [String : Any] {
        var json: [String : Any] = ["http_status": resp.status]

        if debug {
            let ti = traceCollector.traceInfo()
            json["debug"] = [
                "device_info": ti.debugInfo.deviceString(),
                "url_trace": ti.trace
            ]
            traceCollector.stopTrace()
        }

        do {
            if let body = resp.body {
                let rawString = String(data: body, encoding: .utf8) ?? "❌ Unable to decode"
                print("📦 Raw body string:\n\(rawString)")

                if let stripped = stripChunkedEncoding(from: body),
                   let raw = try? JSONSerialization.jsonObject(with: stripped, options: .mutableContainers) as? [String : Any] {
                    let mappedResponse: [String: Any] = [
                        "authmatechCode": raw["encMSISDN"] ?? "",
                        "MNOID": raw["opId"] ?? "",
                        "errorCode": raw["errorCode"] ?? "-1",
                        "errorDesc": raw["errorDesc"] ?? "No description"
                    ]
                    json["response_body"] = mappedResponse
                    return json
                }
            }

            if let trace = json["debug"] as? [String: Any],
               let traceLog = trace["url_trace"] as? String,
               let fallbackParsed = parseUrlTraceForJson(traceLog) {
                print("⚠️ No response body — using fallback JSON from trace")
                json["response_body"] = fallbackParsed
            } else {
                print("❌ Response body & trace parsing both failed")
            }
        } catch {
            if let body = resp.body {
                json["response_raw_body"] = body
            } else {
                return convertNetworkErrorToDictionary(err: .other("JSON deserialization failed"), debug: debug)
            }
        }

        return json
    }
    
    func convertNetworkErrorToDictionary(err: NetworkError, debug: Bool) -> [String : Any] {
        var json = [String : Any]()
        switch err {
        case .invalidRedirectURL(let string):
            json["error"] = "sdk_redirect_error"
            json["error_description"] = string
        case .tooManyRedirects:
            json["error"] = "sdk_redirect_error"
            json["error_description"] = "Too many redirects"
        case .connectionFailed(let string):
            json["error"] = "sdk_connection_error"
            json["error_description"] = string
        case .connectionCantBeCreated(let string):
            json["error"] = "sdk_connection_error"
            json["error_description"] = string
        case .other(let string):
            json["error"] = "sdk_error"
            json["error_description"] = string
        }
        if (debug) {
            let ti = self.traceCollector.traceInfo()
            var json_debug: [String : Any] = [:]
            json_debug["device_info"] = ti.debugInfo.deviceString()
            json_debug["url_trace"] = ti.trace
            json["debug"] = json_debug
            self.traceCollector.stopTrace()
        }
        return json
    }
    
    
    // MARK: - Internal
    func cancelExistingConnection() {
        if self.connection != nil {
            self.connection?.cancel() // This should trigger a state update
            self.connection = nil
        }
    }
    
    func createConnectionUpdateHandler(completion: @escaping ResultHandler,
                                       readyStateHandler: @escaping ()-> Void)
    -> (NWConnection.State) -> Void {
        return { [weak self] newState in
            switch newState {
            case .setup:
                self?.traceCollector.addDebug(log: "Connection State: Setup\n")
                
            case .preparing:
                self?.traceCollector.addDebug(log: "Connection State: Preparing\n")
                
            case .ready:
                let msg = self?.connection.debugDescription ?? "No connection details"
                self?.traceCollector.addDebug(log: "Connection State: Ready \(msg)\n")
                readyStateHandler()
                
            case .waiting(let error):
                let desc = error.localizedDescription
                self?.traceCollector.addDebug(log: "Connection State: Waiting \(desc)\n")
                if desc.contains("Network is down") {
                    completion(.err(.other("Data connectivity not available")))
                }
                
            case .cancelled:
                self?.traceCollector.addDebug(log: "Connection State: Cancelled\n")
                
            case .failed(let error):
                self?.traceCollector.addDebug(type: .error,
                                              log: "Connection State: Failed -> \(error.localizedDescription)")
                completion(.err(.other("Connection State: Failed \(error.localizedDescription)")))
                
            @unknown default:
                self?.traceCollector.addDebug(log: "Connection ERROR State not defined\n")
                completion(.err(.other("Connection State: Unknown \(newState)")))
            }
        }
    }
    
    // MARK: - Utility methods
    func createHttpCommand(url: URL, accessToken: String?, operators: String?, cookies: [HTTPCookie]?, requestId: String?) -> String? {
        guard let host = url.host, let scheme = url.scheme  else {
            return nil
        }
        var path = url.path
        // the path method is stripping ending / so adding it back
        if (url.absoluteString.hasSuffix("/") && !url.path.hasSuffix("/")) {
            path += "/"
        }

        if (path.count == 0) {
            path = "/"
        }

        var cmd = String(format: "GET %@", path)
        
        if let q = url.query {
            cmd += String(format:"?%@", q)
        }
        
        cmd += String(format:" HTTP/1.1\r\nHost: %@", host)
        if (scheme.starts(with:"https") && url.port != nil && url.port != 443) {
            cmd += String(format:":%d", url.port!)
        } else if (scheme.starts(with:"http") && url.port != nil && url.port != 80) {
            cmd += String(format:":%d", url.port!)
        }
        if let token = accessToken {
            cmd += "\r\nAuthorization: Bearer \(String(describing: token)) "
        }
        if let req = requestId {
            cmd += "\r\nx-authmatech-sdk-request: \(String(describing: req)) "
        }
        if let op = operators {
            cmd += "\r\nx-authmatech-ops: \(String(describing: op)) "
        }
        #if targetEnvironment(simulator)
        cmd += "\r\nx-authmatech-mode: sandbox"
        #endif
        if let cookies = cookies {
            var cookieCount = 0
            var cookieString = String()
            for i in 0..<cookies.count {
                if (((cookies[i].isSecure && scheme == "https") || (!cookies[i].isSecure)) && (cookies[i].domain == "" || (cookies[i].domain != "" && host.contains(cookies[i].domain))) && (cookies[i].path == "" ||  path.starts(with: cookies[i].path))) {
                    if (cookieCount > 0) {
                        cookieString += "; "
                    }
                    cookieString += String(format:"%@=%@", cookies[i].name, cookies[i].value)
                    cookieCount += 1
                }
            }
            if (cookieString.count > 0) {
                cmd += "\r\nCookie: \(String(describing: cookieString))"
            }
        }
        cmd += "\r\nUser-Agent: \(debugInfo.userAgent(sdkVersion: AuthmatechSdkVersion)) "
        cmd += "\r\nAccept: text/html,application/xhtml+xml,application/xml,*/*"
        cmd += "\r\nConnection: close\r\n\r\n"
        return cmd
    }
    
    func createConnection(scheme: String, host: String, port: Int? = nil) -> NWConnection? {
        if scheme.isEmpty ||
            host.isEmpty ||
            !(scheme.hasPrefix("http") ||
              scheme.hasPrefix("https")) {
            return nil
        }
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 5 //Secs
        tcpOptions.enableKeepalive = false
        
        var tlsOptions: NWProtocolTLS.Options?
        var fport = (port != nil ? NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port!)) : NWEndpoint.Port.http)
        
        if (scheme.starts(with:"https")) {
            fport = (port != nil ? NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port!)) : NWEndpoint.Port.https)
            tlsOptions = .init()
            tcpOptions.enableFastOpen = true //Save on tcp round trip by using first tls packet
        }
        
        let params = NWParameters(tls: tlsOptions , tcp: tcpOptions)
        params.serviceClass = .responsiveData
#if !targetEnvironment(simulator)
        // force network connection to cellular only
        params.requiredInterfaceType = .cellular
        params.prohibitExpensivePaths = false
        params.prohibitedInterfaceTypes = [.wifi, .loopback, .wiredEthernet]
        self.traceCollector.addTrace(log: "Start connection \(host) \(fport.rawValue) \(scheme) \(self.traceCollector.now())\n")
        self.traceCollector.addDebug(log: "connection scheme \(scheme) \(String(fport.rawValue))")
#else
        self.traceCollector.addTrace(log: "Start connection on simulator \(host) \(fport.rawValue) \(scheme) \(self.traceCollector.now())\n")
        self.traceCollector.addDebug(log: "connection scheme on simulator \(scheme) \(String(fport.rawValue))")
#endif
        
        connection = NWConnection(host: NWEndpoint.Host(host), port: fport, using: params)
        
        return connection
    }
    
    func parseHttpStatusCode(response: String) -> Int {
        let status = response[response.index(response.startIndex, offsetBy: 9)..<response.index(response.startIndex, offsetBy: 12)]
        return Int(status) ?? 0
    }
    
    /// Decodes a response, first attempting with UTF8 and then fallback to ascii
    /// - Parameter data: Data which contains the response
    /// - Returns: decoded response as String
    func decodeResponse(data: Data) -> String? {
        guard let response = String(data: data, encoding: .utf8) else {
            return String(data: data, encoding: .ascii)
        }
        return response
    }
    
    func parseRedirect(requestUrl: URL, response: String, cookies: [HTTPCookie]?) -> RedirectResult? {
        guard let _ = requestUrl.host else {
            return nil
        }
        //header could be named "Location" or "location"
        if let range = response.range(of: #"ocation: (.*)\r\n"#, options: .regularExpression) {
            let location = response[range]
            let redirect = location[location.index(location.startIndex, offsetBy: 9)..<location.index(location.endIndex, offsetBy: -1)]
            // some location header are not properly encoded
            let cleanRedirect = redirect.replacingOccurrences(of: " ", with: "+")
            if let redirectURL =  URL(string: String(cleanRedirect)) {
                return RedirectResult(url: redirectURL.host == nil ? URL(string: redirectURL.description, relativeTo: requestUrl)! : redirectURL, cookies: self.parseCookies(url:requestUrl, response: response, existingCookies: cookies))
            } else {
                self.traceCollector.addDebug(log: "URL malformed \(cleanRedirect)")
                return nil
            }
        }
        return nil
    }
    
    func parseCookies(url: URL, response: String, existingCookies: [HTTPCookie]?) -> [HTTPCookie]? {
        var cookies = [HTTPCookie]()
        if let existing = existingCookies {
            for i in 0..<existing.count {
                cookies.append(existing[i])
            }
        }
        var position = response.startIndex
        while let range = response.range(of: #"ookie: (.*)\r\n"#, options: .regularExpression, range: position..<response.endIndex) {
            let line = response[range]
            let optCookieString:Substring? = line[line.index(line.startIndex, offsetBy: 7)..<line.index(line.endIndex, offsetBy: -1)]
            if let cookieString = optCookieString {
                self.traceCollector.addDebug(log:"parseCookies \(cookieString)")
                let optCs: [HTTPCookie]? = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": String(cookieString)], for: url)
                if let cs = optCs {
                    for i in 0..<cs.count {
                        cookies.append(cs[i])
                    }
                }
            }
            position = range.upperBound
        }
        return cookies.count > 0 ? cookies : nil
    }
    
    func createTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: CONNECTION_TIME_OUT, target: self, selector: #selector(self.connectionTimedOut), userInfo: nil, repeats: false)
    }
    
    @objc func connectionTimedOut() {
        self.traceCollector.addDebug(log: "Connection timed out")
        self.cancelExistingConnection()
        self.checkResponseHandler(.err(NetworkError.connectionFailed("Connection timed out")))
    }
    
    func cleanUp() {
        self.timer?.invalidate()
        self.timer = nil
        self.cancelExistingConnection()
        self.stopMonitoring()
    }
    
    func startMonitoring() {
        self.pathMonitor = NWPathMonitor(requiredInterfaceType: .cellular)
        self.pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied {
                self.traceCollector.addDebug(log: "Cellular data available")
            } else {
                // 2) immediate failure when cellular is off
                self.traceCollector.addDebug(log: "We do not have a cellular path")
                self.cleanUp()
                let errorDict: [String: Any] = [
                    "error": "sdk_no_data_connectivity",
                    "error_description": "Data connectivity not available"
                ]
                DispatchQueue.main.async {
                    self.checkResponseHandler(.err(.other("Data connectivity not available")))
                    // or, if you want to bypass NetworkError enum entirely:
                    // completion(errorDict)
                }
            }
        }
        let queue = DispatchQueue(label: "CellularMonitor")
        self.pathMonitor?.start(queue: queue)
    }

    
    func stopMonitoring() {
        if (self.pathMonitor != nil) {
            self.pathMonitor?.cancel()
            self.pathMonitor = nil
        }
    }
    
    func post(url: URL, headers: [String : Any], body: String?, completion: @escaping ([String : Any]) -> Void) {
        completion(["error": "sdk_error", "error_description": "This method is deprecated and will be removed in the next release. It will not be replaced."])
    }
    
    func activateConnectionForDataFetch(url: URL, accessToken: String?, operators: String?, cookies: [HTTPCookie]?, requestId: String?, completion: @escaping ResultHandler) {
        guard let host = url.host, let scheme = url.scheme else {
            completion(.err(NetworkError.other("No scheme or host found")))
            return
        }
        
        self.cancelExistingConnection()
        
        guard let connection = self.createConnection(scheme: scheme, host: host, port: url.port) else {
            completion(.err(NetworkError.connectionCantBeCreated("Connection can't be created")))
            return
        }
        
        guard let httpCommand = self.createHttpCommand(url: url, accessToken: accessToken, operators: operators, cookies: cookies, requestId: requestId) else {
            completion(.err(NetworkError.other("HTTP command can't be created")))
            return
        }
        
        self.traceCollector.addDebug(log: "HTTP Command: \(httpCommand)")
        
        var responseData = Data()
        
        let readyStateHandler = { [weak self] in
            guard let self = self else {
                return
            }
            
            let commandData = httpCommand.data(using: .utf8)!
            
            connection.send(content: commandData, completion: .contentProcessed({ error in
                if let error = error {
                    self.traceCollector.addDebug(log: "Send error: \(error)")
                    completion(.err(NetworkError.connectionFailed("Send error: \(error)")))
                    return
                }
                
                self.traceCollector.addDebug(log: "Send completed")
                
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536, completion: { (data, context, isComplete, error) in
                    if let error = error {
                        self.traceCollector.addDebug(log: "Receive error: \(error)")
                        completion(.err(NetworkError.connectionFailed("Receive error: \(error)")))
                        return
                    }
                    
                    if let data = data, !data.isEmpty {
                        responseData.append(data)
                    }
                    
                    if isComplete {
                        self.traceCollector.addDebug(log: "Receive completed")
                        
                        if let response = self.decodeResponse(data: responseData) {
                            self.traceCollector.addTrace(log: "Received response \(self.traceCollector.now())\n")
                            
                            if response.starts(with: "HTTP") {
                                let statusCode = self.parseHttpStatusCode(response: response)
                                self.traceCollector.addDebug(log: "Status code: \(statusCode)")
                                
                                if statusCode >= 300 && statusCode < 400 {
                                    if let redirectResult = self.parseRedirect(requestUrl: url, response: response, cookies: cookies) {
                                        completion(.follow(redirectResult))
                                    } else {
                                        completion(.err(NetworkError.invalidRedirectURL("Invalid redirect URL")))
                                    }
                                } else {
                                    let connectionResponse = ConnectionResponse(status: statusCode, body: responseData)
                                    if statusCode >= 200 && statusCode < 300 {
                                        completion(.dataOK(connectionResponse))
                                    } else {
                                        completion(.dataErr(connectionResponse))
                                    }
                                }
                            } else {
                                completion(.err(NetworkError.other("Invalid HTTP response")))
                            }
                        } else {
                            completion(.err(NetworkError.other("Unable to decode response")))
                        }
                    } else {
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536, completion: { (data, context, isComplete, error) in
                            if let error = error {
                                self.traceCollector.addDebug(log: "Receive error: \(error)")
                                completion(.err(NetworkError.connectionFailed("Receive error: \(error)")))
                                return
                            }
                            
                            if let data = data, !data.isEmpty {
                                responseData.append(data)
                            }
                            
                            if isComplete {
                                self.traceCollector.addDebug(log: "Receive completed")
                                
                                if let response = self.decodeResponse(data: responseData) {
                                    self.traceCollector.addTrace(log: "Received response \(self.traceCollector.now())\n")
                                    
                                    if response.starts(with: "HTTP") {
                                        let statusCode = self.parseHttpStatusCode(response: response)
                                        self.traceCollector.addDebug(log: "Status code: \(statusCode)")
                                        
                                        if statusCode >= 300 && statusCode < 400 {
                                            if let redirectResult = self.parseRedirect(requestUrl: url, response: response, cookies: cookies) {
                                                completion(.follow(redirectResult))
                                            } else {
                                                completion(.err(NetworkError.invalidRedirectURL("Invalid redirect URL")))
                                            }
                                        } else {
                                            let connectionResponse = ConnectionResponse(status: statusCode, body: responseData)
                                            if statusCode >= 200 && statusCode < 300 {
                                                completion(.dataOK(connectionResponse))
                                            } else {
                                                completion(.dataErr(connectionResponse))
                                            }
                                        }
                                    } else {
                                        completion(.err(NetworkError.other("Invalid HTTP response")))
                                    }
                                } else {
                                    completion(.err(NetworkError.other("Unable to decode response")))
                                }
                            } else {
                                self.traceCollector.addDebug(log: "Receive not complete, but no more receive calls")
                                completion(.err(NetworkError.other("Receive not complete, but no more receive calls")))
                            }
                        })
                    }
                })
            }))
        }
        
        connection.stateUpdateHandler = self.createConnectionUpdateHandler(completion: completion, readyStateHandler: readyStateHandler)
        connection.start(queue: DispatchQueue.main)
    }
    
    /// Fallback: Parse JSON from url_trace debug log if response body is missing
    func parseUrlTraceForJson(_ trace: String) -> [String: Any]? {
        let pattern = #"\{[^}]*\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let range = NSRange(location: 0, length: trace.utf16.count)
        if let match = regex.firstMatch(in: trace, options: [], range: range),
           let swiftRange = Range(match.range, in: trace) {
            let jsonString = String(trace[swiftRange])
            print("🧪 [Trace URL JSON Fallback] raw JSON: \(jsonString)")
            if let data = jsonString.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                var result: [String: Any] = [:]
                result["authmatechCode"] = parsed["encMSISDN"] ?? ""
                result["MNOID"] = parsed["opId"] ?? ""
                result["errorCode"] = parsed["errorCode"] ?? "0"
                result["heId"] = parsed["heId"] ?? ""
                result["errorDesc"] = parsed["errorDesc"] ?? "Authmatech Code successfully fetched"
                
                return result
            }
        }
        return nil
    }
    
    /// Strips HTTP chunked transfer encoding from the response body data
    private func stripChunkedEncoding(from data: Data) -> Data? {
        guard let raw = String(data: data, encoding: .utf8) else { return nil }

        // Find the first "{" and last "}" to isolate the JSON payload
        if let startIndex = raw.firstIndex(of: "{"),
           let endIndex = raw.lastIndex(of: "}") {
            let jsonString = String(raw[startIndex...endIndex])
            return jsonString.data(using: .utf8)
        }

        print("❌ Failed to extract JSON from chunked response")
        return nil
    }
    
    
    
}
