//
//  Proxy.swift
//  
//
//  Created by Michael Arrington on 8/6/20.
//

import Foundation
import SQLite3

struct Proxy: UnbindingProxy {
	
	private let statement: Statement
	private let _isNull: (Int32) -> Bool
	var index: Int32 = 0
	
	
	init(_ statement: Statement, isNull: @escaping (Int32) -> Bool) {
		self.statement = statement
		self._isNull = isNull
	}
	
	func get() throws -> Int64 {
		return sqlite3_column_int64(statement.p, index)
	}
	
	func get() throws -> Double {
		return sqlite3_column_double(statement.p, index)
	}
	
	func get() throws -> String {
		guard let p = sqlite3_column_text(statement.p, index) else {
			fatalError()
		}
		return String(cString: p)
	}
	
	func get() throws -> Data {
		let length = sqlite3_column_bytes(statement.p, index)
		
		guard length > 0 else {
			return Data()
		}
		
		guard let raw = sqlite3_column_blob(statement.p, index) else {
			fatalError()
		}
		
		return Data(bytes: raw, count: Int(length))
	}
	
	func isNull() -> Bool {
		_isNull(index)
	}
}
