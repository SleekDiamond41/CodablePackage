import XCTest
@testable import CodableData

final class CodableDataTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CodableData().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
