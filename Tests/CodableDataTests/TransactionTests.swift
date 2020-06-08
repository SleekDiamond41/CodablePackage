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
		
		static func key<T>(for path: KeyPath<Movie, T>) -> CodingKeys where T : Bindable {
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
	}
	
	
	
	var db: Database!
	
	override func setUp() {
		super.setUp()
		
		db = try! Database(filename: "TransactionTests")
	}
	
	override func tearDown() {
		try? db?.deleteWithoutReconnecting()
		db = nil
		
		super.tearDown()
	}
	
	
	func testSave() {
		
		let id = UUID()
		
		let names = [
			Name(id: id, first: "Johnny", last: "Appleseed"),
			Name(id: UUID(), first: "Robert", last: "Bobson", age: 47),
		]
		
		let movies = [
			Movie(id: UUID(), title: "The Dark Knight", releaseDate: Date().addingTimeInterval(-(60 * 60 * 24 * 120))),
		]
		
		// gotta save things to the database first
		// so their tables can be generated
		// (will have to fix that in the future)
		
		try! db.save(names.first!)
		try! db.delete(names.first!)
		
		try! db.save(movies.first!)
		try! db.delete(movies.first!)
		
		do {
			
			try db.transact { (t) in
				
				t.save(names)
				t.save(movies)
			}
			
			let nameResults = try db.get(sorting: SortRule(\Name.first))
			let movieResults = try db.get(with: Filter<Movie>())
			
			XCTAssertEqual(nameResults, names)
			XCTAssertEqual(movieResults, movies)
			
		} catch {
			XCTFail(String(describing: error))
		}
	}
	
	func testDelete() {
		let id = UUID()
		
		let names = [
			Name(id: id, first: "Johnny", last: "Appleseed"),
			Name(id: UUID(), first: "Robert", last: "Bobson", age: 47),
		]
		
		let movies = [
			Movie(id: UUID(), title: "The Dark Knight", releaseDate: Date().addingTimeInterval(-(60 * 60 * 24 * 120))),
		]
		
		// gotta save things to the database first
		// so their tables can be generated
		
		try! db.save(names.first!)
		try! db.delete(names.first!)
		
		try! db.save(movies.first!)
		try! db.delete(movies.first!)
		
		do {
			
			try db.transact { (t) in
				
				t.save(names)
				t.save(movies)
				
				t.delete(names.first!)
				t.delete(movies.first!)
				
				t.save(movies.first!)
			}
			
			let nameResults = try db.get(sorting: SortRule(\Name.first))
			let movieResults = try db.get(with: Filter<Movie>())
			
			XCTAssertEqual(nameResults.count, 1)
			XCTAssertEqual(nameResults.first, names[1])
			XCTAssertEqual(movieResults, movies)
			
		} catch {
			XCTFail(String(describing: error))
		}
	}
}
