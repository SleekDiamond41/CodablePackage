//
//  ReaderTests.swift
//  
//
//  Created by Michael Arrington on 4/20/20.
//

import XCTest
import SQLite3
@testable import CodableData


extension KeyedDecodingContainer {
	
	@inlinable
	func decode<T: Decodable>(_ value: inout T, forKey key: Key) throws {
		value = try decode(T.self, forKey: key)
	}
	
	@inlinable
	func decode<T: Decodable>(_ value: inout Optional<T>, forKey key: Key) throws {
		value = try decodeIfPresent(T.self, forKey: key)
	}
}


struct User: UUIDModel, Codable {
	
	static var idKey: KeyPath<User, UUID> = \User.id
	
	
	private(set) var id = UUID()
	
	var firstName = ""
	var age = 0
	var noColumn: Int?
	var birthday: Date?
	
	init(id: UUID, firstName: String, age: Int = 0) {
		self.id = id
		self.firstName = firstName
		self.age = age
	}
	
	enum CodingKeys: String, CodingKey {
		case id
		case firstName = "first_name"
		case age
		case noColumn = "no_column"
		case birthday
	}
}

extension User: Filterable {
	
	typealias FilterKey = CodingKeys
	
	static func key(for path: PartialKeyPath<User>) -> FilterKey {
		switch path {
		case \User.id: return .id
		case \User.firstName: return .firstName
		case \User.age: return .age
		case \User.noColumn: return .noColumn
		case \User.birthday: return .birthday
		default:
			preconditionFailure("unrecognized KeyPath")
		}
	}
	
	static func path(for key: FilterKey) -> PartialKeyPath<User> {
		switch key {
		case .id: return \.id
		case .firstName: return \.firstName
		case .age: return \.age
		case .noColumn: return \.noColumn
		case .birthday: return \.birthday
		}
	}
}

class ReaderTests: XCTestCase {
	
	var db: Database!
	
	override func setUpWithError() throws {
		try super.setUpWithError()
		
		db = try Database(filename: "ReaderTests")
	}
	
	override func tearDown() {
		try? db?.deleteWithoutReconnecting()
		db = nil
		
		super.tearDown()
	}
	
	func testJournalMode() throws {
		var statement = Statement("PRAGMA journal_mode;")
		try statement.prepare(in: db.connection.db)
		let status = statement.step()
		
		XCTAssertEqual(status, .row)
		
		let proxy = Proxy(statement, isNull: { _ in false })
		
		XCTAssertEqual(proxy.get(), "wal")
	}
	
	func testMultithreadMode() throws {
		var statement = Statement("pragma COMPILE_OPTIONS;")
		try statement.prepare(in: db.connection.db)
		var status = statement.step()
		let proxy = Proxy(statement, isNull: { _ in false })
		
		var mode: Int32?
		while status == .row {
			let text = proxy.get() as String
			
			if let range = text.range(of: "THREADSAFE=") {
				mode = Int32(text[range.upperBound...])
				break
			}
			
			status = statement.step()
		}
		
		XCTAssertEqual(mode, SQLITE_CONFIG_MULTITHREAD)
	}
	
	func testReadUncommitted() throws {
		var statement = Statement("pragma read_uncommitted;")
		try statement.prepare(in: db.connection.db)
		let status = statement.step()
		
		guard status == .row else {
			XCTFail("\(status)")
			return
		}
		
		let proxy = Proxy(statement, isNull: { _ in false })
		
		XCTAssertEqual(proxy.get() as Int64, 1)
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
	
	func test_readNilDate() {
		var user = User(id: UUID(uuidString: "E621E9F8-C36C-495A-93FC-0C247C3E6E5B")!, firstName: "Johnny")
		
		// create the 'birthday' column
		user.birthday = Date()
		try! db.save(user)
		
		// save the nil value to the 'birthday' column
		user.birthday = nil
		try! db.save(user)
		
		let filter = Filter<User>()
		guard let result = try! db.get(with: filter).first else {
			XCTFail("expected to have at least one result")
			return
		}
		
		// sanity check that we found the correct User instance
		assert(result.id == user.id)
		
		XCTAssertNil(result.birthday)
	}
}
