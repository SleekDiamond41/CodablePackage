//
//  Statement.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import  SQLite3

struct Statement {
	let query: String
	private(set) var p: OpaquePointer?
	
	init(_ query: String) {
		self.query = query
	}
}

extension Statement {
	
	mutating func prepare(in db: OpaquePointer) throws {
		let status = Status(sqlite3_prepare(db, query, -1, &p, nil))
		guard status == .ok else {
			let mess = String(cString: sqlite3_errmsg(db))
			fatalError(String(reflecting: mess))
		}
	}
	mutating func reset() {
		finalize()
	}
	func finalize() {
		guard let p = p else { return }
		sqlite3_finalize(p)
	}
	
	@discardableResult
	func step() throws -> Status {
		assert(p != nil)
		return Status(sqlite3_step(p))
	}
	
}


extension Statement {
	
	func unbind<T: Unbindable>(_ : T.Type, for key: String, in table: Table) throws -> T {
		guard let index = table.columns.firstIndex(where: { $0.name == key }) else {
			fatalError()
		}
		return try T.unbind(from: self, at: Int32(index))
	}
	
}
