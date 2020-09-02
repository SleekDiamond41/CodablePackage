//
//  ErrorTests.swift
//  
//
//  Created by Michael Arrington on 9/1/20.
//

import XCTest
@testable import CodableData


class ErrorTests: XCTestCase {
	
	var db: Database!
	
	override func setUpWithError() throws {
		db = try Database(filename: "ErrorTests")
	}
	
	override func tearDownWithError() throws {
		try db?.deleteWithoutReconnecting()
		db = nil
	}
	
	func testDiskIOError() {
		// this error happens when there's something wrong with the
		// .sqlite file, like it not existing
		
		let otherConnection = try! Database(filename: "ErrorTests")
		try! db.deleteWithoutReconnecting()
		
		XCTAssertThrowsError(_ = try otherConnection.get(with: Filter<Name>())) { (error) in
			switch error {
			case let e as SqliteError:
				XCTAssertEqual(e, SqliteError.diskIO)
			default:
				XCTFail("we threw the wrong kind of error")
			}
		}
	}
}
