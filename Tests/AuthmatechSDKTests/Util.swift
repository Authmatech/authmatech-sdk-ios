//
//  AuthmatechUtil.swift
//  AuthmatechSDKTests
//
//  Adapted for Authmatech SDK by replacing TruSDK references
//

import XCTest
import Network

@testable import AuthmatechSDK

private var debugInfo = DebugInfo()

func httpCommand(url: URL, sdkVersion: String) -> String {
    var query = ""
    if let q = url.query {
        query = "?\(q)"
    }

    let system = UIDevice.current.systemName + "/" + UIDevice.current.systemVersion

    let expectation = """
    GET \(url.path)\(query) HTTP/1.1\
    \r\nHost: \(url.host!)\
    \r\nx-authmatech-mode: sandbox\
    \r\nUser-Agent: \(debugInfo.userAgent(sdkVersion: sdkVersion)) \
    \r\nAccept: text/html,application/xhtml+xml,application/xml,*/*\
    \r\nConnection: close\r\n\r\n
    """

    return expectation
}

enum HTTPStatus: Int {
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case switchProxy = 306
    case temporaryRedirect = 307
    case permenantRedirect = 308

    var statusMessage: String {
        switch self {
        case .multipleChoices: return "Multiple Choice"
        case .movedPermanently: return "Moved Permanently"
        case .found: return "Found"
        case .seeOther: return "See Other"
        case .notModified: return "Not Modified"
        case .useProxy: return "Use Proxy"
        case .temporaryRedirect: return "Temporary Redirect"
        case .permenantRedirect: return "Permanent Redirect"
        case .switchProxy: return "Switch Proxy"
        }
    }
}

// MARK: - Default HTTP Responses
func http2xxResponse() -> String {
    return """
    HTTP/1.1 200 OK\r\n \
    Date: Mon, 19 April 2021 22:04:35 GMT\r\n\
    Server: Apache/2.2.8 (Ubuntu) mod_ssl/2.2.8 OpenSSL/0.9.8g\r\n\
    Last-Modified: Mon, 19 April 2021 22:04:35 GMT\r\n\
    ETag: \"45b6-834-49130cc1182c0\"\r\n\
    Accept-Ranges: bytes\r\n\
    Content-Length: 12\r\n\
    Connection: close\r\n\
    Content-Type: text/html\r\n\
    \r\n\
    Hello world!\r\n
    """
}

func http3XXResponse(code: HTTPStatus, url: String) -> String {
    return """
    HTTP/1.1 \(code.rawValue) \(code.statusMessage)\r\n\
    Server: AkamaiGHost\r\n \
    Content-Length: 0\r\n\
    Location: \(url)\r\n\
    Date: Thu, 15 Apr 2021 19:09:15 GMT\r\n\
    Connection: keep-alive\r\n\
    Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0\r\n\r\n
    """
}

func http3XXResponseWith(code: HTTPStatus, locationString: String) -> String {
    return """
    HTTP/1.1 \(code.rawValue) \(code.statusMessage)\r\n\
    Server: AkamaiGHost\r\n \
    Content-Length: 0\r\n\
    \(locationString)\r\n\
    Date: Thu, 15 Apr 2021 19:09:15 GMT\r\n\
    Connection: keep-alive\r\n\
    Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0\r\n\r\n
    """
}

func http400Response() -> String { return "" }
func http500Response() -> String { return "" }

func corruptHTTPResponse() -> String {
    return """
    Accept-Ranges: bytes\r\n\
    WWEHTTP><><>/1.1 sdkasdh OK203\r\n \
    il 2021 22:0Date: Mon, 19 Apr4:35 GMT\r\n\
    Server: Apac19 April 2021 22:04:35 GMT\r\n\
    ETag: \"45b6-834-4913he/2.2.8 (Ubuntu) mod_ssl/2.2.8 OpenSSL/0.9.8g\r\n\
    Last-Modified: Mon, 0cc1182c0\"\r\n\
    asd;lkasdk,
    asdk;lasd
    kqeiqwe
    \r\n\
    Hello world!\r\n
    """
}
