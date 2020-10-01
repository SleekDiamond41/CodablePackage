//
//  TableTests.swift
//  
//
//  Created by Michael Arrington on 9/29/20.
//

import XCTest
@testable import CodableData

/*
connect financial software solutions
- credit union apps/software
- online and mobile (I would be iOS)

- Objc-C, new stuff in Swift
	- plans to update legacy stuff to Swift?

phone interview
tech interview
*/

struct Simple: UUIDModel {
	let id = UUID()
	
	static var idKey = \Simple.id
}

class TableTests: XCTestCase {
	
	struct Fancy: UUIDModel {
		let id = UUID()
		
		static var idKey = \Fancy.id
	}
	
	func testDefaultName() {
		// TODO: find a way to handle
		
		XCTAssertEqual(Simple.tableName, "CodableDataTests.Simple")
		XCTAssertEqual(Fancy.tableName, "CodableDataTests.TableTests.Fancy")
	}
}
