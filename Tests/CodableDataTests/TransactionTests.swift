//
//  TransactionTests.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import XCTest
@testable import CodableData


class TransactionTests: XCTestCase {
	
	private struct Movie: UUIDModel, Codable, Filterable, Equatable {
		let id: UUID
		var title: String
		var releaseDate: Date
		
		static let idKey = \Movie.id
		static let tableName = "movies"
		
		static func ==(left: Movie, right: Movie) -> Bool {
			let diff = left.releaseDate.timeIntervalSinceNow - right.releaseDate.timeIntervalSinceNow
			
			let dateMatch = abs(diff) < 0.0001
			
			return left.id == right.id
				&& left.title == right.title
				&& dateMatch
		}
		
		enum CodingKeys: String, CodingKey {
			case id
			case title
			case releaseDate = "release_date"
		}
		
		static func key(for path: PartialKeyPath<Movie>) -> CodingKeys {
			switch path {
			case \Movie.id:
				return .id
			case \Movie.title:
				return .title
			case \Movie.releaseDate:
				return .releaseDate
			default:
				preconditionFailure("unknown KeyPath!")
			}
		}
		
		static func path(for key: CodingKeys) -> PartialKeyPath<TransactionTests.Movie> {
			switch key {
			case .id: return \.id
			case .title: return \.title
			case .releaseDate: return \.releaseDate
			}
		}
	}
	
	
	
	var db: Database!
	
	override func setUp() {
		super.setUp()
		
		db = try! Database(filename: "TransactionTests")
	}
	
	override func tearDown() {
		try? db?.deleteTheWholeDangDatabase()
		db = nil
		
		super.tearDown()
	}
	
	
	func testSave() throws {
		
		let id = UUID()
		
		let names = [
			Name(id: id, first: "Johnny", last: "Appleseed"),
			Name(id: UUID(), first: "Robert", last: "Bobson", age: 47),
		]
		
		let movies = [
			Movie(id: UUID(), title: "The Dark Knight", releaseDate: Date().addingTimeInterval(-(60 * 60 * 24 * 120))),
		]
		
		try db.transact { (t) in
			
			t.save(names)
			t.save(movies)
		}
		
		let nameResults = try db.get(with: Filter<Name>().sort(by: \.first))
		let movieResults = try db.get(with: Filter<Movie>())
		
		XCTAssertEqual(nameResults, names)
		XCTAssertEqual(movieResults, movies)
	}
	
	func testDelete() throws {
		let id = UUID()
		
		let names = [
			Name(id: id, first: "Johnny", last: "Appleseed"),
			Name(id: UUID(), first: "Robert", last: "Bobson", age: 47),
		]
		
		let movies = [
			Movie(id: UUID(), title: "The Dark Knight", releaseDate: Date().addingTimeInterval(-(60 * 60 * 24 * 120))),
		]
		
		try db.transact { (t) in
			
			t.save(names)
			t.save(movies)
			
			t.delete(names.first!)
			t.delete(movies.first!)
			
			t.save(movies.first!)
		}
		
		let nameResults = try db.get(with: Filter<Name>().sort(by: \.first))
		let movieResults = try db.get(with: Filter<Movie>())
		
		XCTAssertEqual(nameResults.count, 1)
		XCTAssertEqual(nameResults.first, names[1])
		XCTAssertEqual(movieResults, movies)
	}
	
	func testDeleteWithFilter() throws {
		let id = UUID()
		
		let name = Name(id: id, first: "Johnny", last: "Appleseed")
		
		// gotta save things to the database first
		// so their tables can be generated
		
		try db.save(name)
		
		let filter = Filter<Name>(\.id, is: .in([id]))
		
		try db.transact { (t) in
			t.delete(filter)
		}
	}
	
	func testUpdateBeforeAddingModels() throws {
		let firstName = "Jimmy"
		let batch = Update<Name>(UUID())
			.set(\.first, to: firstName)
		
		try db.transact {
			$0.update(batch)
		}
		
		let results = try db.get(with: Filter<Name>())
		
		// we should get back 0 results, because we can't update
		// elements that don't exist in the database
		XCTAssertEqual(results.count, 0)
	}
}
