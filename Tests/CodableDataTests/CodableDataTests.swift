import XCTest
@testable import CodableData


final class CodableDataTests: XCTestCase {
	
	var db: Database!

    override func setUp() {
        super.setUp()
		
		db = try! Database(filename: "CodableDataTests")
    }

    override func tearDown() {
		try? db?.deleteWithoutReconnecting()
		db = nil
		
		super.tearDown()
    }

    func testCreateDatabase() {
		do {
			let db = try Database(filename: "TestCreateDatabase")
			try db.deleteWithoutReconnecting()
		} catch {
			XCTFail(String(describing: error))
		}
    }

    func testFilter() {
        var filter = Filter<Name>()
        XCTAssertEqual(filter.query, "")
        XCTAssertEqual(filter.bindings.count, 0)

        filter = Filter<Name>(\.age, is: .equal(to: 3))
        XCTAssertEqual(filter.query, "WHERE \"age\" IS ?")
        XCTAssertEqual(filter.bindings.count, 1)

        filter = Filter<Name>()
        filter = filter.and(\.first, is: .equal(to: "Michael")).limit(10)
        XCTAssertEqual(filter.query, "WHERE \"first\" LIKE ? LIMIT 10")
        XCTAssertEqual(filter.bindings.count, 1)

        filter = filter.and(\.last, is: .like("Arrington")).limit(50, page: 3)
        XCTAssertEqual(filter.query, "WHERE \"first\" LIKE ? AND \"last\" LIKE ? LIMIT 50 OFFSET 150")
        XCTAssertEqual(filter.bindings.count, 2)

        let otherFilter = Filter<Name>(\.age, is: .between(18, and: 30))
        filter = filter.or(otherFilter)
        // FIXME: look into logical ways to make complex AND/ORs split up in an appropriate way
        XCTAssertEqual(filter.query, "WHERE (\"first\" LIKE ? AND \"last\" LIKE ?) OR (\"age\" BETWEEN ? AND ?) LIMIT 50 OFFSET 150")
        XCTAssertEqual(filter.bindings.count, 4)
    }
	
	func testSorting() {
		let filter = Filter<Name>()
			.sorting(by: \.age)
			.sorting(by: \.first, direction: .ascending)
			.sorting(by: \.last, direction: .descending)
		
		XCTAssertEqual(filter.query, "ORDER BY age ASC, first ASC, last DESC")
	}
	
	func testCount() {
		XCTAssertEqual(try db.count(with: Filter<Name>()), 0)
		
		let model = Name(id: UUID(), first: "Michael", last: "Arrington")

		try! db.save(model)
		
		XCTAssertEqual(try db.count(with: Filter<Name>()), 1)
	}
	
	func testDistinct() {
		XCTAssertEqual(try db.distinct(\Name.age), [])
		
		let one = Name(id: UUID(), first: "Michael", last: "Arrington", age: 47)
		let two = Name(id: UUID(), first: "Michael", last: "Arrington", age: 25)
		
		try! db.save(one)
		try! db.save(two)
		
		XCTAssertEqual(try db.distinct(\Name.age), [47, 25])
		XCTAssertEqual(try db.distinct(\Name.age, by: .ascending), [25, 47])
		
		let three = Name(id: UUID(), first: "Michael", last: "Arrington", age: 32)
		
		try! db.save(three)
		
		XCTAssertEqual(try db.distinct(\Name.age, by: .descending), [47, 32, 25])
	}
	
	func testDistinctCount() {
		XCTAssertEqual(try db.distinctCount(\Name.age), 0)
		
		let model = Name(id: UUID(), first: "Michael", last: "Arrington")

		try! db.save(model)
		
		XCTAssertEqual(try db.distinctCount(\Name.age), 1)
	}

    func testDatabase() {
		
		XCTAssertEqual(try db.count(with: Filter<Name>()), 0)

		let model = Name(id: UUID(), first: "Michael", last: "Arrington")

		XCTAssertNoThrow(try db.save(model))

		XCTAssertEqual(try db.count(with: Filter<Name>()), 1)
		
		XCTAssertNoThrow(try db.deleteTheWholeDangDatabase())
    }
	
	func test_savingUnicodeCharacters() {
		
		let unicodeCharacters = "😳😳😬"
		let model = Name(id: UUID(), first: unicodeCharacters, last: "")
		
		XCTAssertNoThrow(try db.save(model))
		
		let filter = Filter<Name>()
			.limit(1)
		
		XCTAssertNoThrow(try db.get(with: filter))
		
		guard let match = try! db.get(with: filter).first else {
			XCTFail()
			return
		}
		
		XCTAssertEqual(match.first, unicodeCharacters)
	}
	
	func test_keyValueStorage() {
		let key = "myKey"
		let value = 173813.5345
		
		let storage = db.keyValueStorage()
		
		storage.store(value, for: key)
		XCTAssertEqual(storage.value(for: key), value)
		
		
		storage.removeValue(for: key)
		
		// it doesn't matter what we cast to if the value doesn't exist,
		// so just always use Bool (arbitrary choice) even if you
		// change the actual value stored in 'value'
		XCTAssertEqual(storage.value(for: key) as Bool?, nil)
	}
}
