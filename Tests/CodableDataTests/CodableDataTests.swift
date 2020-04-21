import XCTest
@testable import CodableData

final class CodableDataTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()

        do {
            let db = try Database()

            for model in try db.get(filter: Filter<Name>()) {
                try db.delete(model)
            }
        } catch {
            XCTFail(String(reflecting: error))
        }
    }

    func testCreateDatabase() {
        XCTAssertNoThrow(try Database(filename: "Testing"))
    }

    func testFilter() {
        var filter = Filter<Name>()
        XCTAssertEqual(filter.query, "")
        XCTAssertEqual(filter.bindings.count, 0)

        filter = Filter<Name>(\.age, is: .equal(to: 3))
        XCTAssertEqual(filter.query, "WHERE age IS ?")
        XCTAssertEqual(filter.bindings.count, 1)

        filter = Filter<Name>()
        filter = filter.and(\.first, is: .equal(to: "Michael")).limit(10)
        XCTAssertEqual(filter.query, "WHERE first LIKE ? LIMIT 10")
        XCTAssertEqual(filter.bindings.count, 1)

        filter = filter.and(\.last, is: .like("Arrington")).limit(50, page: 3)
        XCTAssertEqual(filter.query, "WHERE first LIKE ? AND last LIKE ? LIMIT 50 OFFSET 150")
        XCTAssertEqual(filter.bindings.count, 2)

        let otherFilter = Filter<Name>(\.age, is: .between(18, and: 30))
        filter = filter.or(otherFilter)
        // FIXME: look into logical ways to make complex AND/ORs split up in an appropriate way
        XCTAssertEqual(filter.query, "WHERE (first LIKE ? AND last LIKE ?) OR (age BETWEEN ? AND ?) LIMIT 50 OFFSET 150")
        XCTAssertEqual(filter.bindings.count, 4)
    }
	
	func testSorting() {
		let filter = Filter<Name>()
			.sorting(by: \.age)
			.sorting(by: \.first, ascending: true)
			.sorting(by: \.last, ascending: false)
		
		XCTAssertEqual(filter.query, "ORDER BY age ASC, first ASC, last DESC")
	}

    func testDatabase() {

        do {
            let db = try Database()

            XCTAssertEqual(try db.count(with: Filter<Name>()), 0)

            let model = Name(id: UUID(), first: "Michael", last: "Arrington")

            XCTAssertNoThrow(try db.save(model))

            XCTAssertEqual(try db.count(with: Filter<Name>()), 1)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
