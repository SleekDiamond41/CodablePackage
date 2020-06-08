//
//  ReaderTests.swift
//  
//
//  Created by Michael Arrington on 4/20/20.
//

import XCTest
@testable import CodableData


extension KeyedDecodingContainer {
	
	@inlinable
	func decode<T: Decodable>(_ value: inout T, forKey key: Key) throws {
		value = try decode(T.self, forKey: key)
	}
}


struct User: UUIDModel, Codable {
	
	static var idKey: KeyPath<User, UUID> = \User.id
	
	
	private(set) var id = UUID()
	
	var firstName = ""
	var age = 0
	var noColumn: Int?
	
	init(id: UUID, firstName: String, age: Int = 0) {
		self.id = id
		self.firstName = firstName
		self.age = age
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// required fields
		try container.decode(&id, forKey: .id)
		
		// optional fields
		try container.decode(&firstName, forKey: .firstName)
		try container.decode(&age, forKey: .age)
		try? container.decode(&noColumn, forKey: .noColumn)
	}
	
	enum CodingKeys: String, CodingKey {
		case id
		case firstName = "first_name"
		case age
		case noColumn = "no_column"
	}
}

extension User: Filterable {
	
	static func key<T>(for path: KeyPath<User, T>) -> CodingKeys where T : Bindable {
		switch path {
		case \User.id:
			return .id
		case \User.firstName:
			return .firstName
		case \User.age:
			return .age
		case \User.noColumn:
			return .noColumn
		default:
			preconditionFailure("unrecognized KeyPath")
		}
	}
}

class ReaderTests: XCTestCase {
	
	var db: Database!
	
	override func setUp() {
		super.setUp()
		
		db = try! Database(filename: "ReaderTests")
	}
	
	override func tearDown() {
		try? db?.deleteWithoutReconnecting()
		db = nil
		
		super.tearDown()
	}
	
	func test_readTypeThatDoesntExist() {
		let filter = Filter<User>()
		
		XCTAssertNoThrow(try db.get(with: filter))
		XCTAssertNoThrow(try db.count(with: filter))
		
		XCTAssertEqual((try? db.get(with: filter))?.count, 0)
		XCTAssertEqual((try? db.count(with: filter)), 0)
	}
	
	func test_readColumnThatDoesntExist() {
		
		print(db.dir)
		
		let user = User(id: UUID(uuidString: "E621E9F8-C36C-495A-93FC-0C247C3E6E5A")!, firstName: "Johnny")
		
		try! db.save(user)
		
		let filter = Filter<User>()
		
		// FIXME: update this test to reflect desired behavior:
		// if a query includes references to a column that doesn't exist
		// it should not throw an error.
		// If the database tries to read a value from a column that doesn't exist,
		// an error should be thrown (ReaderError.noSuchColumn(String))
		XCTAssertNoThrow(try db.get(with: Filter<User>()))
		
		do {
			let models = try db.get(with: filter)
			
			XCTAssertEqual(models.count, 1)
			XCTAssertEqual(models.first?.id, user.id)
			XCTAssertEqual(models.first?.firstName, user.firstName)
			XCTAssertEqual(models.first?.age, user.age)
			XCTAssertEqual(models.first?.noColumn, user.noColumn)
			
		} catch let error as PreparationError {
			print(error)
		} catch {
			XCTFail("inconsistent error throwing '\(String(describing: error))'")
		}
	}
}
