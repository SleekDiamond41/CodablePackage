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
		try db?.deleteWithoutReconnecting()
		db = nil
		
		super.tearDown()
	}
	
	func testNoValues() {
		
	}
	
	func testOneValue() {
		let firstName = "Jimmy"
		
		let update = Database.Update<Name>(model.id)
			.set(\.first, to: firstName)
		
		do {
			try db.update(update)
		} catch {
			print(String(describing: error))
			XCTFail(error.localizedDescription)
			return
		}
		
		let filter = Filter<Name>()
		
		do {
			let results = try db.get(with: filter)
			
			XCTAssertEqual(results.count, 1)
			XCTAssertEqual(results.first?.id, model.id)
			XCTAssertEqual(results.first?.first, firstName)
			XCTAssertEqual(results.first?.last, model.last)
			XCTAssertEqual(results.first?.age, model.age)
		} catch {
			XCTFail(error.localizedDescription)
			return
		}
	}
	
	func testManyValues() {
		let firstName = "Jimmy"
		let lastName = "Orangeseed"
		
		let update = Database.Update<Name>(model.id)
			.set(\.first, to: firstName)
			.set(\.last, to: lastName)
		
		do {
			try db.update(update)
		} catch {
			print(String(describing: error))
			XCTFail(error.localizedDescription)
			return
		}
		
		let filter = Filter<Name>()
		
		do {
			let results = try db.get(with: filter)
			
			XCTAssertEqual(results.count, 1)
			XCTAssertEqual(results.first?.id, model.id)
			XCTAssertEqual(results.first?.first, firstName)
			XCTAssertEqual(results.first?.last, lastName)
			XCTAssertEqual(results.first?.age, model.age)
		} catch {
			XCTFail(error.localizedDescription)
			return
		}
	}
	
	func testDuplicateValues() {
		let tempFirstName = "J"
		let firstName = "Jimmy"
		
		let update = Database.Update<Name>(model.id)
			.set(\.first, to: tempFirstName)
			.set(\.first, to: firstName)
		
		do {
			try db.update(update)
		} catch {
			print(String(describing: error))
			XCTFail(error.localizedDescription)
			return
		}
		
		let filter = Filter<Name>()
		
		do {
			let results = try db.get(with: filter)
			
			XCTAssertEqual(results.count, 1)
			XCTAssertEqual(results.first?.id, model.id)
			XCTAssertEqual(results.first?.first, firstName)
			XCTAssertEqual(results.first?.last, model.last)
			XCTAssertEqual(results.first?.age, model.age)
		} catch {
			XCTFail(error.localizedDescription)
			return
		}
	}
	
	func testNewColumn() {
		let age = 482
		
		let update = Database.Update<Name>(model.id)
			.set(\.age, to: age)
		
		do {
			try db.update(update)
		} catch {
			print(String(describing: error))
			XCTFail(error.localizedDescription)
			return
		}
		
		let filter = Filter<Name>()
		
		do {
			let results = try db.get(with: filter)
			
			XCTAssertEqual(results.count, 1)
			XCTAssertEqual(results.first?.id, model.id)
			XCTAssertEqual(results.first?.first, model.first)
			XCTAssertEqual(results.first?.last, model.last)
			XCTAssertEqual(results.first?.age, age)
		} catch {
			XCTFail(error.localizedDescription)
			return
		}
	}
}
