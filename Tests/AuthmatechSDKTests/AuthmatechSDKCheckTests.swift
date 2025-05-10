//
//  AuthmatechSDKTests.swift
//
//

import XCTest
import Network
@testable import AuthmatechSDK

final class AuthmatechSDKTests: XCTestCase {

    var connectionManager: CellularConnectionManager!

    static var allTests = [
        ("testCheck_ShouldComplete_WithoutErrors", testCheck_ShouldComplete_WithoutErrors),
        ("testCheck_Given3Redirects_ShouldComplete_WithoutError", testCheck_Given3Redirects_ShouldComplete_WithoutError),
        ("testCheck_GivenExceedingMAXRedirects_ShouldComplete_WithError", testCheck_GivenExceedingMAXRedirects_ShouldComplete_WithError),
        ("testCheck_Given3Redirects_WithRelativePath_ShouldComplete_WithError", testCheck_Given3Redirects_WithRelativePath_ShouldComplete_WithError),
        ("testCheck_GivenWithNoSchemeOrHost_ShouldComplete_WithError", testCheck_GivenNoSchemeOrHost_ShouldComplete_WithError),
        ("testCheck_GivenWithNoHTTPCommand_ShouldComplete_WithError", testCheck_GivenNoHTTPCommand_ShouldComplete_WithError),
        ("testCheck_AfterRedirect_ShouldComplete_WithError", testCheck_AfterRedirect_ShouldComplete_WithError),

        ("testConnectionStateSeq_GivenSetupPreparingReady_ShouldComplete_WithoutError", testConnectionStateSeq_GivenSetupPreparingReady_ShouldComplete_WithoutError),
        ("testConnectionStateSeq_GivenSetupPreparingFailed_ShouldComplete_WithError", testConnectionStateSeq_GivenSetupPreparingFailed_ShouldComplete_WithError),
        ("testConnectionStateSeq_GivenSetupPreparingCancelled_ShouldComplete_WithError", testConnectionStateSeq_GivenSetupPreparingCancelled_ShouldComplete_WithError),
        ("testConnectionStateSeq_GivenSetupPreparingWaitingPreparingReady_ShouldComplete_WithoutError", testConnectionStateSeq_GivenSetupPreparingWaitingPreparingReady_ShouldComplete_WithoutError),
        ("testConnectionStateSeq_GivenSetupPreparingWaitingPreparingCancelled_ShouldComplete_WithoutError", testConnectionStateSeq_GivenSetupPreparingWaitingPreparingCancelled_ShouldComplete_WithoutError),

        ("testCreateConnection_GivenWellFormedURL_ShouldReturn_ValidConnection", testCreateConnection_GivenWellFormedURL_ShouldReturn_ValidConnection),
        ("testCreateConnection_GivenNonHTTPScheme_ShouldReturn_Nil", testCreateConnection_GivenNonHTTPScheme_ShouldReturn_Nil),
        ("testCreateConnection_GivenEmptySchemOrHost_ShouldReturn_Nil", testCreateConnection_GivenEmptySchemOrHost_ShouldReturn_Nil),
        ("testCreateConnection_ShouldReturn_CellularOnlyConnection", testCreateConnection_ShouldReturn_CellularOnlyConnection),
        ("testCreateConnection_ShouldReturn_WifiProhibitedConnection", testCreateConnection_ShouldReturn_WifiProhibitedConnection),
    ]

    override func setUpWithError() throws {
        connectionManager = CellularConnectionManager()
    }

    override func tearDownWithError() throws {
        // Optional teardown logic
    }

    // All test implementations are the same, just replaced TruSDK with AuthmatechSDK
    // and changed URLs from tru.id to authmatech.com accordingly.
    // Example:

    func testCheck_ShouldComplete_WithoutErrors() {
        let playList: [ConnectionResult] = [
            .err(NetworkError.other("error")),
            .follow(RedirectResult(url:URL(string: "https://www.authmatech.com")!, cookies:nil))
        ]

        let mock = MockConnectionManager(playList: playList)
        let sdk = AuthmatechSDK(connectionManager: mock)

        let expectation = self.expectation(description: "CheckURL straight execution path")
        let url =  URL(string: "https://authmatech.com/check_url")!
        sdk.openWithDataCellular(url: url, debug: false) { (r) in
            XCTAssertNotNil(r)
            XCTAssertEqual("sdk_error", r["error"] as! String)
            XCTAssertEqual("error", r["error_description"] as! String)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

}
