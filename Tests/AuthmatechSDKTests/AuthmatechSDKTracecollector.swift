
//
//  AuthmatechTraceCollectorTests.swift
//  AuthmatechSDKTests
//
//  Adapted from TruSDK trace collector tests for Authmatech
//

import XCTest
@testable import AuthmatechSDK

final class AuthmatechTraceCollectorTests: XCTestCase {

    var connectionManager: CellularConnectionManager!

    static var allTests = [
        ("testTraceCollector_TimeZone", testTraceCollector_ShouldComplete_WithoutErrors),
    ]

    override func setUpWithError() throws {
        connectionManager = CellularConnectionManager()
    }

    override func tearDownWithError() throws {
        // Clean up if needed
    }
}

extension AuthmatechTraceCollectorTests {
    func testTraceCollector_ShouldComplete_WithoutErrors() {
        let dateUtils = DateUtils()
        let dateFormatter = dateUtils.df
        let abv = dateFormatter.timeZone.abbreviation()
        print("Default: \(String(describing: abv)) vs current:\(TimeZone.current)")
        XCTAssertEqual("GMT", abv)
    }
}
