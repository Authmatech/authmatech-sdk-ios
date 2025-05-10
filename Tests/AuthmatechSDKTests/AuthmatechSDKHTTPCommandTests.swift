
//
//  AuthmatechHTTPCommandTests.swift
//  AuthmatechSDKTests
//
//  Adapted from TruSDK HTTP Command Tests
//

import XCTest
@testable import AuthmatechSDK
#if canImport(UIKit)
import UIKit
#endif

final class AuthmatechHTTPCommandTests: XCTestCase {

    var connectionManager: CellularConnectionManager!

    static var allTests = [
        ("testCreateHTTPCommand_ShouldReturn_URL", testCreateHTTPCommand_ShouldReturn_URL),
        ("testCreateHTTPCommand_URLWithQuery_ShouldReturn_URL", testCreateHTTPCommand_URLWithQuery_ShouldReturn_URL),
        ("testCreateHTTPCommand_PathOnlyURL_ShouldReturn_Nil", testCreateHTTPCommand_PathOnlyURL_ShouldReturn_Nil),
        ("testCreateHTTPCommand_SchemeOnlyURL_ShouldReturn_Nil", testCreateHTTPCommand_SchemeOnlyURL_ShouldReturn_Nil),
        ("testCreateHTTPCommand_URLWithOutAHost_ShouldReturn_Nil", testCreateHTTPCommand_URLWithOutAHost_ShouldReturn_Nil),
        ("testHTTPStatus_ShouldReturn_200", testHTTPStatus_ShouldReturn_200),
        ("testHTTPStatus_ShouldReturn_302", testHTTPStatus_ShouldReturn_302),
        ("testHTTPStatus_ShouldReturn_0_WhenResponseIsCorrupt", testHTTPStatus_ShouldReturn_0_WhenResponseIsCorrupt)
    ]

    override func setUpWithError() throws {
        connectionManager = CellularConnectionManager()
    }

    override func tearDownWithError() throws {
        // Cleanup logic if needed
    }
}

// MARK: - Unit Tests for createHttpCommand(..)
extension AuthmatechHTTPCommandTests {

    func testCreateHTTPCommand_ShouldReturn_URL() {
        let urlString = "https://authmatech.com"
        let url = URL(string: urlString)!
        let expectation = httpCommand(url: url, sdkVersion: AuthmatechSdkVersion)

        let httpCommand = connectionManager.createHttpCommand(url: url, accessToken: nil, operators: nil, cookies: nil, requestId: nil)
        XCTAssertEqual(expectation, httpCommand)
    }

    func testCreateHTTPCommand_URLWithQuery_ShouldReturn_URL() {
        let urlString = "https://authmatech.com/verify?token=abc123"
        let url = URL(string: urlString)!
        let expectation = httpCommand(url: url, sdkVersion: AuthmatechSdkVersion)

        let httpCommand = connectionManager.createHttpCommand(url: url, accessToken: nil, operators: nil, cookies: nil, requestId: nil)
        XCTAssertEqual(expectation, httpCommand)
    }

    func testCreateHTTPCommand_PathOnlyURL_ShouldReturn_Nil() {
        let urlString = "/"
        let url = URL(string: urlString)!
        let httpCommand = connectionManager.createHttpCommand(url: url, accessToken: nil, operators: nil, cookies: nil, requestId: nil)
        XCTAssertNil(httpCommand)
    }

    func testCreateHTTPCommand_SchemeOnlyURL_ShouldReturn_Nil() {
        let urlString = "http://"
        let url = URL(string: urlString)!
        let httpCommand = connectionManager.createHttpCommand(url: url, accessToken: nil, operators: nil, cookies: nil, requestId: nil)
        XCTAssertNil(httpCommand)
    }

    func testCreateHTTPCommand_URLWithOutAHost_ShouldReturn_Nil() {
        let urlString = "/auth"
        let url = URL(string: urlString)!
        let httpCommand = connectionManager.createHttpCommand(url: url, accessToken: nil, operators: nil, cookies: nil, requestId: nil)
        XCTAssertNil(httpCommand)
    }
}

// MARK: - Unit tests for httpStatusCode(..)
extension AuthmatechHTTPCommandTests {

    func testHTTPStatus_ShouldReturn_200() {
        let response = "HTTP/1.1 200 OK"
        let actualStatus = connectionManager.parseHttpStatusCode(response: response)
        XCTAssertEqual(200, actualStatus)
    }

    func testHTTPStatus_ShouldReturn_302() {
        let response = "HTTP/1.1 302 Found"
        let actualStatus = connectionManager.parseHttpStatusCode(response: response)
        XCTAssertEqual(302, actualStatus)
    }

    func testHTTPStatus_ShouldReturn_0_WhenResponseIsCorrupt() {
        let response = "INVALID_RESPONSE"
        let actualStatus = connectionManager.parseHttpStatusCode(response: response)
        XCTAssertEqual(0, actualStatus)
    }
}

// Helper method (mocked expected command)
private func httpCommand(url: URL, sdkVersion: String) -> String {
    var path = url.path
    if path.isEmpty { path = "/" }

    var cmd = "GET \(path)"
    if let query = url.query { cmd += "?\(query)" }

    cmd += " HTTP/1.1\r\nHost: \(url.host!)"
    cmd += "\r\nUser-Agent: authmatech-sdk-ios/\(sdkVersion) iOS/TEST"
    cmd += "\r\nAccept: text/html,application/xhtml+xml,application/xml,*/*"
    cmd += "\r\nConnection: close\r\n\r\n"
    return cmd
}
