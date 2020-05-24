//
//  Statement.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3

struct Statement {
	let query: String
	private(set) var p: OpaquePointer?

	init(_ query: String) {
		self.query = query
	}
}

public enum SqliteError: Error {
	case unknown(String)
}

enum PreparationError: Error {
	case noSuchTable(String)
	case noSuchColumn(String)
	case syntax(String, query: String)
}

fileprivate func nativeError(from sqliteError: String, query: String) -> Error {
	if let range = sqliteError.range(of: "no such table: ") {
		return PreparationError.noSuchTable(String(sqliteError[range.upperBound...]))
	}
	if let range = sqliteError.range(of: "no such column: ") {
		return PreparationError.noSuchColumn(String(sqliteError[range.upperBound...]))
	}
	if let range = sqliteError.range(of: ": syntax error") {
		return PreparationError.syntax(String(sqliteError[..<range.lowerBound]), query: query)
	}
	return SqliteError.unknown(sqliteError)
}

extension Statement {

	mutating func prepare(in db: OpaquePointer) throws {
		let status = Status(sqlite3_prepare(db, query, -1, &p, nil))
		guard status == .ok else {
			print(status)
			let mess = String(cString: sqlite3_errmsg(db))
			throw nativeError(from: mess, query: query)
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
	func step() -> Status {
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
