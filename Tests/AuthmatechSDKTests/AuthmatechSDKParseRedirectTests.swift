//
//  AuthmatechParseRedirectTests.swift
//  AuthmatechSDKTests
//
//  Adapted from TruSDK redirect parser tests for Authmatech
//

import XCTest
@testable import AuthmatechSDK
#if canImport(UIKit)
import UIKit
#endif

final class AuthmatechParseRedirectTests: XCTestCase {

    var connectionManager: CellularConnectionManager!

    static var allTests = [
        ("testParseRedirect_ShouldReturn_CorrectRedirectURL", testParseRedirect_ShouldReturn_CorrectRedirectURL),
        ("testParseRedirect_ShouldReturn_Nil_WhenReponseIsNot3XX", testParseRedirect_ShouldReturn_Nil_WhenReponseIsNot3XX),
        ("testParseRedirect_ShouldReturn_Nil_WhenRequestURLHasNoHost", testParseRedirect_ShouldReturn_Nil_WhenRequestURLHasNoHost),
        ("testParseRedirect_ShouldReturn_Nil_WhenResponseIsNotARedirect", testParseRedirect_ShouldReturn_Nil_WhenResponseIsNotARedirect),
        ("testParseRedirect_ShouldReturn_Nil_WhenThereIsNoLocation", testParseRedirect_ShouldReturn_Nil_WhenThereIsNoLocation),
        ("testParseRedirect_ShouldReturn_URL_WhenLocationHeaderHasVariations", testParseRedirect_ShouldReturn_URL_WhenLocationHeaderHasVariations),
        ("testParseRedirect_ShouldReturn_Nil_WhenLocationIsNotAURL", testParseRedirect_ShouldReturn_Nil_WhenLocationIsNotAURL),
        ("testParseRedirect_ShouldReturn_URL_WhenLocationIsRelative", testParseRedirect_ShouldReturn_URL_WhenLocationIsRelative)
    ]

    override func setUpWithError() throws {
        connectionManager = CellularConnectionManager()
    }

    override func tearDownWithError() throws {
        // Clean up if needed
    }
}

extension AuthmatechParseRedirectTests {

    func testParseRedirect_ShouldReturn_CorrectRedirectURL() {
        let expectedRedirectURL = "https://www.authmatech.com/uk"
        let response = http3XXResponse(code: .movedPermanently, url: expectedRedirectURL)
        let actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "https://authmatech.com")!, response: response, cookies: nil)
        XCTAssertNotNil(actualRedirectURL)
        XCTAssertEqual(actualRedirectURL?.url?.absoluteString, expectedRedirectURL)
    }

    func testParseRedirect_ShouldReturn_Nil_WhenReponseIsNot3XX() {
        let response = http500Response()
        let actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "https://authmatech.com")!, response: response, cookies: nil)
        XCTAssertNil(actualRedirectURL)
    }

    func testParseRedirect_ShouldReturn_Nil_WhenRequestURLHasNoHost() {
        let expectedRedirectURL = "https://authmatech.com"
        let response = http3XXResponse(code: .movedPermanently, url: expectedRedirectURL)
        let actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "/uk")!, response: response, cookies: nil)
        XCTAssertNil(actualRedirectURL)
    }

    func testParseRedirect_ShouldReturn_Nil_WhenResponseIsNotARedirect() {
        let response = http2xxResponse()
        let actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "https://authmatech.com/uk")!, response: response, cookies: nil)
        XCTAssertNil(actualRedirectURL)
    }

    func testParseRedirect_ShouldReturn_Nil_WhenThereIsNoLocation() {
        var response = http3XXResponseWith(code: .movedPermanently, locationString: "")
        var actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "/uk")!, response: response, cookies: nil)
        XCTAssertNil(actualRedirectURL)

        response = http3XXResponseWith(code: .movedPermanently, locationString: "Location: ")
        actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "/uk")!, response: response, cookies: nil)
        XCTAssertNil(actualRedirectURL)
    }

    func testParseRedirect_ShouldReturn_URL_WhenLocationHeaderHasVariations() {
        let expectedURL = "https://authmatech.com"
        var response = http3XXResponseWith(code: .movedPermanently, locationString: "location: \(expectedURL)")
        var actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "https://authmatech.com/uk")!, response: response, cookies: nil)
        XCTAssertEqual(actualRedirectURL!.url?.absoluteString, expectedURL)

        response = http3XXResponseWith(code: .movedPermanently, locationString: "Location: \(expectedURL)")
        actualRedirectURL = connectionManager.parseRedirect(requestUrl: URL(string: "https://authmatech.com/uk")!, response: response, cookies: nil)
        XCTAssertEqual(actualRedirectURL!.url?.absoluteString, expectedURL)
    }

    func testParseRedirect_ShouldReturn_Nil_WhenLocationIsNotAURL() {
        let requestURL = URL(string: "https://authmatech.com")!
        var response = http3XXResponseWith(code: .movedPermanently, locationString: "location: ")
        var actualRedirectURL = connectionManager.parseRedirect(requestUrl: requestURL, response: response, cookies: nil)
        XCTAssertNil(actualRedirectURL)

        response = http3XXResponseWith(code: .movedPermanently, locationString: "location: http://authmatech.com/?{}><\\")
        actualRedirectURL = connectionManager.parseRedirect(requestUrl: requestURL, response: response, cookies: nil)
        XCTAssertNil(actualRedirectURL)
    }

    func testParseRedirect_ShouldReturn_URL_WhenLocationIsRelative() {
        let requestURL = URL(string: "https://authmatech.com")!
        let expectedRedirectURL = URL(string: "https://authmatech.com/uk")!
        let response = http3XXResponseWith(code: .movedPermanently, locationString: "location: /uk")
        let actualRedirectURL = connectionManager.parseRedirect(requestUrl: requestURL, response: response, cookies: nil)
        XCTAssertEqual(actualRedirectURL?.url?.absoluteString, expectedRedirectURL.absoluteString)
    }
}
