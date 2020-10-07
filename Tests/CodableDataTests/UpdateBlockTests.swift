//
//  UpdateBlockTests.swift
//  
//
//  Created by Michael Arrington on 9/14/20.
//

import XCTest
@testable import CodableData

class UpdateBlockTests: XCTestCase {
	
	var db: Database!
	var model = Name(id: UUID(), first: "Johnny", last: "Appleseed")
	
	override func setUpWithError() throws {
		super.setUp()
		
		db = try Database(filename: "UpdateBlockTests")
		try db.save(model)
	}
	
	override func tearDownWithError() throws {
		try db?.deleteTheWholeDangDatabase()
		db = nil
		
		super.tearDown()
	}
	
	func testNoModelsToUpdate() throws {
		let filter = Filter<Name>()
		
		// remove existing stuff from the database
		try db.delete(with: filter)
		XCTAssertEqual(try db.count(with: filter), 0)
		
		let update = Update<Name>(UUID())
			.set(\.first, to: "Jimmy")
		
		try db.update(update)
		
		// make sure we didn't accidentally add a row to the database
		XCTAssertEqual(try db.count(with: filter), 0)
	}
	
	func testMultipleRows() throws {
		let firstName = "George"
		let otherName = Name(id: UUID(), first: "Jimmy", last: "Orangeseed")
		// setup for the test
		try db.save(otherName)
		
		// filter that should apply to all rows in the table
		let filter = Filter<Name>()
			.sort(by: \.last)
			.limit(5)
		let update = Update<Name>(filter)
			.set(\.first, to: firstName)
		
		try db.update(update)
		
		let results = try db.get(with: filter)
		
		XCTAssertEqual(results.count, 2)
		
		for result in results {
			XCTAssertEqual(result.first, firstName)
		}
	}
	
	func testNoValues() throws {
		let update = Update<Name>(model.id)
		
		try db.update(update)
		
		let filter = Filter<Name>()
		
		let results = try db.get(with: filter)
		
		XCTAssertEqual(results.count, 1)
		XCTAssertEqual(results.first?.id, model.id)
		XCTAssertEqual(results.first?.first, model.first)
		XCTAssertEqual(results.first?.last, model.last)
		XCTAssertEqual(results.first?.age, model.age)
	}
	
	func testOneValue() throws {
		let firstName = "Jimmy"
		
		let update = Update<Name>(model.id)
			.set(\.first, to: firstName)
		
		try db.update(update)
		
		let filter = Filter<Name>()
		
		let results = try db.get(with: filter)
		
		XCTAssertEqual(results.count, 1)
		XCTAssertEqual(results.first?.id, model.id)
		XCTAssertEqual(results.first?.first, firstName)
		XCTAssertEqual(results.first?.last, model.last)
		XCTAssertEqual(results.first?.age, model.age)
	}
	
	func testManyValues() throws {
		let firstName = "Jimmy"
		let lastName = "Orangeseed"
		
		let update = Update<Name>(model.id)
			.set(\.first, to: firstName)
			.set(\.last, to: lastName)
		
		try db.update(update)
		
		let filter = Filter<Name>()
		
		let results = try db.get(with: filter)
		
		XCTAssertEqual(results.count, 1)
		XCTAssertEqual(results.first?.id, model.id)
		XCTAssertEqual(results.first?.first, firstName)
		XCTAssertEqual(results.first?.last, lastName)
		XCTAssertEqual(results.first?.age, model.age)
	}
	
	func testDuplicateValues() throws {
		let tempFirstName = "J"
		let firstName = "Jimmy"
		
		let update = Update<Name>(model.id)
			.set(\.first, to: tempFirstName)
			.set(\.first, to: firstName)
		
		try db.update(update)
		
		let filter = Filter<Name>()
		
		let results = try db.get(with: filter)
		
		XCTAssertEqual(results.count, 1)
		XCTAssertEqual(results.first?.id, model.id)
		XCTAssertEqual(results.first?.first, firstName)
		XCTAssertEqual(results.first?.last, model.last)
		XCTAssertEqual(results.first?.age, model.age)
	}
	
	func testNewColumn() throws {
		let age = 482
		
		let update = Update<Name>(model.id)
			.set(\.age, to: age)
		
		try db.update(update)
		
		let filter = Filter<Name>()
		
		let results = try db.get(with: filter)
		
		XCTAssertEqual(results.count, 1)
		XCTAssertEqual(results.first?.id, model.id)
		XCTAssertEqual(results.first?.first, model.first)
		XCTAssertEqual(results.first?.last, model.last)
		XCTAssertEqual(results.first?.age, age)
	}
}
