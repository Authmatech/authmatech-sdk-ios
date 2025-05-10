//
//  AuthmatechDecodeTests.swift
//
//

import XCTest
@testable import AuthmatechSDK

final class AuthmatechDecodeTests: XCTestCase {

    var connectionManager: CellularConnectionManager!

    static var allTests = [
        ("testDecode_Given_ResponseWithUTF8Encoding_ShouldReturn_Response", testDecode_Given_ResponseWithUTF8Encoding_ShouldReturn_Response),
        ("testDecode_Given_ResponseWithNonUTF8Encoding_ShouldFallbackTo_ASCII", testDecode_Given_ResponseWithNonUTF8Encoding_ShouldFallbackTo_ASCII)
    ]

    override func setUpWithError() throws {
        connectionManager = CellularConnectionManager()
    }

    override func tearDownWithError() throws {
        // Optional teardown logic
    }
}

extension AuthmatechDecodeTests {

    func testDecode_Given_ResponseWithUTF8Encoding_ShouldReturn_Response() {
        let data = "🙃".data(using: .utf8)
        let decodedReponse = connectionManager.decodeResponse(data: data!)
        XCTAssertNotNil(decodedReponse)
        XCTAssertEqual("🙃", decodedReponse)
    }

    func testDecode_Given_ResponseWithNonUTF8Encoding_ShouldFallbackTo_ASCII() {
        let data = generateNONEncodedData()
        let decodedReponse = connectionManager.decodeResponse(data: data)
        XCTAssertNotNil(decodedReponse)
    }
}

func generateASCIIEncodedData() -> Data {
    let response = """
    HTTP/1.1 400 Bad Request
    Server: Apache
    Date: Tue, 22 Apr 2025 15:57:49 GMT
    Content-Language: en
    Content-Type: text/html;charset=utf-8
    Content-Length: 435
    Connection: close
    """
    return response.data(using: .ascii)!
}

func generateNONEncodedData() -> Data {
    let response = "7ビット及び8ビットの2バイト情報交換用符号化漢字集合"
    return response.data(using: .japaneseEUC)!
}
