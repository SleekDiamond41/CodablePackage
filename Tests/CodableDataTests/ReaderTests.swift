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


//@inlinable func decode<T, C>(_ container: C, _ value: inout T, forKey key: C.Key) throws where
//	T: Decodable,
//	C: KeyedDecodingContainerProtocol {
//		value = try container.decode(T.self, forKey: key)
//}


fileprivate struct Person: UUIDModel, Codable {
	private(set) var id = UUID()
	
	var firstName = ""
	var age = 0
	var noColumn = 0
	
	init(id: UUID, firstName: String, age: Int? = nil) {
		self.id = id
		self.firstName = firstName
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.id = try container.decode(UUID.self, forKey: .id)
		self.firstName = try container.decode(String.self, forKey: .firstName)
		
		try? container.decode(&age, forKey: .age)
		try? container.decode(&noColumn, forKey: .noColumn)
	}
	
	enum CodingKeys: String, CodingKey {
		case id
		case firstName = "first_name"
		case age
		case noColumn = "no_column"
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
		case \Person.noColumn:
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
		
		// FIXME: update this test to reflect desired behavior:
		// if a query includes references to a column that doesn't exist
		// it should not throw an error.
		// If the database tries to read a value from a column that doesn't exist,
		// an error should be thrown (ReaderError.noSuchColumn(String))
		XCTAssertNoThrow(try db.get(with: Filter<Person>()))
		
		XCTAssertThrowsError(try db.get(with: Filter<Person>(\.noColumn, is: .equal(to: 0))), "expected an error to be thrown") { (error) in
			guard let readerError = error as? ReaderError else {
				XCTFail("unexpected error: \(error)")
				return
			}
			
			switch readerError {
			case .noSuchColumn(let column):
				XCTAssertEqual(column, Person.CodingKeys.noColumn.stringValue)
			}
		}
		
		do {
			let models = try db.get(with: filter)
			
			XCTAssertEqual(models.count, 1)
			XCTAssertEqual(models.first?.id, person.id)
			XCTAssertEqual(models.first?.firstName, person.firstName)
			XCTAssertEqual(models.first?.age, person.age)
			XCTAssertEqual(models.first?.noColumn, person.noColumn)
			
		} catch let error as PreparationError {
			print(error)
		} catch {
			XCTFail("inconsistent error throwing '\(String(describing: error))'")
		}
	}
}
