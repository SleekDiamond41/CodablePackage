import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CodableDataTests.allTests),
        testCase(FilterTests.allTests),
    ]
}
#endif
