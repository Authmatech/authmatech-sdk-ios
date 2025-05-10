//
//  AuthmatechAllTests.swift
//  AuthmatechSDKTests
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AuthmatechHTTPCommandTests.allTests),
        testCase(AuthmatechParseRedirectTests.allTests),
        testCase(AuthmatechCheckTests.allTests),
        testCase(AuthmatechDecodeTests.allTests),
        testCase(AuthmatechTraceCollectorTests.allTests)
    ]
}
#endif
