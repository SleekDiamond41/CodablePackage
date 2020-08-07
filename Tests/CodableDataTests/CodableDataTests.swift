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
        XCTAssertEqual(filter.query, """
		WHERE "age" IS ?
		""")
        XCTAssertEqual(filter.bindings.count, 1)

        filter = Filter<Name>()
        filter = filter.and(\.first, is: .exactly("Michael"))
			.limit(10)
        XCTAssertEqual(filter.query, """
		WHERE "first" LIKE ? LIMIT ?
		""")
		XCTAssertEqual(filter.bindings, [
			.string("Michael"),
			.integer(Int64(UInt32(10)))
		])

        filter = filter.and(\.last, is: .exactly("Arrington")).limit(50, page: 3)
        XCTAssertEqual(filter.query, """
		WHERE "first" LIKE ? AND "last" LIKE ? LIMIT ? OFFSET ?
		""")
        XCTAssertEqual(filter.bindings, [
			.string("Michael"),
			.string("Arrington"),
			.integer(Int64(UInt32(50))),
			.integer(Int64(UInt32(3))),
		])

        let otherFilter = Filter<Name>(\.age, is: .between(18, and: 30))
        filter = filter.or(otherFilter)
        // FIXME: look into logical ways to make complex AND/ORs split up in an appropriate way
        XCTAssertEqual(filter.description, """
		Filter<Name>: WHERE (first IS EXACTLY 'Michael' AND last IS EXACTLY 'Arrington') OR (age IS BETWEEN 18 AND 30)
		""")
    }
	
	func testSorting() {
		let filter = Filter<Name>()
			.sort(by: \.age)
			.sort(by: \.first, .ascending)
			.sort(by: \.last, .descending)
		
		XCTAssertEqual(filter.query, """
		ORDER BY "age" ASC, "first" ASC, "last" DESC
		""")
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
	
	func test_getModels() {
		let models = [
			Name(id: UUID(), first: "Michael", last: "Arrington", age: 10),
			Name(id: UUID(), first: "Johnny", last: "Appleseed", age: 20),
		]
		
		for model in models {
			// do this to manually generate the appropriate table
			try! db.save(model)
		}
		
		var filter = Filter<Name>()
			.sort(by: \.age, .ascending)
		
		XCTAssertEqual(try! db.count(with: filter), 2)
		XCTAssertEqual(try! db.get(with: filter), models)
		
		filter = filter.and(\.first, is: .in(["Michael", "Johnny"]))
		XCTAssertEqual(try! db.count(with: filter), 2)
		XCTAssertEqual(try! db.get(with: filter), models)
		
		filter = Filter(\.first, is: .in(["Michael", "Johnny"]))
		XCTAssertEqual(try! db.count(with: filter), 2)
		XCTAssertEqual(try! db.get(with: filter), models)
		
		filter = Filter(\.age, is: .in([10, 20]))
		XCTAssertEqual(try! db.count(with: filter), 2)
		XCTAssertEqual(try! db.get(with: filter), models)
		
		filter = Filter(\.age, is: .in([10]))
		XCTAssertEqual(try! db.count(with: filter), 1)
		XCTAssertEqual(try! db.get(with: filter).first, models.first)
		
		filter = Filter(\.age, is: .notIn([10]))
		XCTAssertEqual(try! db.count(with: filter), 1)
		XCTAssertEqual(try! db.get(with: filter)[0], models[1])
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
	
	func test_savingEnums() {
		struct Temp: UUIDModel, Codable, Filterable {
			
			let id: UUID
			let name: String
			let key: Key
			
			static let idKey = \Temp.id
			
			enum Key: String, Codable {
				case one
				case two
			}
			
			enum CodingKeys: String, CodingKey {
				case id
				case name
				case key
			}
			
			static func key(for path: PartialKeyPath<Temp>) -> CodingKeys {
				switch path {
				case idKey:
					return .id
				case \Temp.name:
					return .name
				case \Temp.key:
					return .key
				default:
					preconditionFailure()
				}
			}
			
			static func path(for filterKey: CodingKeys) -> PartialKeyPath<Temp> {
				switch filterKey {
				case .id: return \.id
				case .name: return \.name
				case .key: return \Temp.key as KeyPath<Temp, Key>
				}
			}
		}
		
		let model = Temp(id: UUID(), name: "bob", key: .one)
		
		try! db.save(model)
		
		let filter = Filter<Temp>(\.id, is: .equal(to: model.id))
			.limit(1)
		
		let result = try! db.get(with: filter).first!
		
		XCTAssertEqual(result.id, model.id)
		XCTAssertEqual(result.name, model.name)
		XCTAssertEqual(result.key, model.key)
	}
}
