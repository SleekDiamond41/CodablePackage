//
//  ReaderTests.swift
//  
//
//  Created by Michael Arrington on 4/20/20.
//

import XCTest
@testable import CodableData

fileprivate struct Person: UUIDModel, Codable {
	private(set) var id = UUID()
	
	var firstName = ""
	var age: Int?
	
	init(id: UUID, firstName: String, age: Int? = nil) {
		self.id = id
		self.firstName = firstName
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.id = try container.decode(UUID.self, forKey: .id)
		self.firstName = try container.decode(String.self, forKey: .firstName)
		self.age = try container.decode(Int.self, forKey: .age)
	}
	
	enum CodingKeys: String, CodingKey {
		case id
		case firstName = "first_name"
		case age
	}
}

extension Person: Filterable {
	
	static func key<T>(for path: KeyPath<Person, T>) -> CodingKeys where T : Bindable {
		switch path {
		case \Person.id:
			return .id
		case \Person.firstName:
			return .firstName
		case \Person.age:
			return .age
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
		let filter = Filter<Person>()
		
		XCTAssertNoThrow(try db.get(with: filter))
		XCTAssertNoThrow(try db.count(with: filter))
		
		XCTAssertEqual((try? db.get(with: filter))?.count, 0)
		XCTAssertEqual((try? db.count(with: filter)), 0)
	}
	
	func test_readColumnThatDoesntExist() {
		
		print(db.dir)
		
		let person = Person(id: UUID(uuidString: "E621E9F8-C36C-495A-93FC-0C247C3E6E5A")!, firstName: "Johnny")
		
		try! db.save(person)
		
		let filter = Filter<Person>()
		
		XCTAssertThrowsError(try db.get(with: filter), "expected an error to be thrown") { (error) in
			guard let readerError = error as? ReaderError else {
				XCTFail("unexpected error: '\(error)'")
				return
			}
			
			switch readerError {
			case .noSuchColumn(let column):
				XCTAssertEqual(column, Person.CodingKeys.age.stringValue)
			}
		}
	}
}
