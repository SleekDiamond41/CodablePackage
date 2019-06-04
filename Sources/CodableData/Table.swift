//
//  Table.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


struct Table {
	let name: String
	let columns: [Column]
	
	static func name(_ str: String) -> String {
		return str.sqlFormatted()
	}
	
	func query(for action: Action) -> String {
		switch action {
		case .create:
			let c = columns.map { $0.query }.joined(separator: ", ")
			return "CREATE TABLE IF NOT EXISTS \(name) (\(c));"
		case .addColumn(let col):
			assert(!col.isPrimaryKey, "Shouldn't be adding a new column as the Primary Key")
			return "ALTER TABLE \(name) ADD COLUMN \(col.query);"
		case .drop:
			return "DROP TABLE IF EXISTS \(name);"
		}
	}
	
	init(name: String, columns: [Column]) {
		self.name = Table.name(name)
		self.columns = columns
	}
	
	enum Action {
		case create
		case addColumn(Column)
		case drop
	}
	
	struct Column {
		let name: String
		let type: ColumnType
		let isPrimaryKey: Bool
		
		init(name: String, type: ColumnType) {
			self.name = name
			self.type = type
			self.isPrimaryKey = name == "id"
		}
		
		init(name: String, type: ColumnType, isPrimaryKey: Bool) {
			self.name = name
			self.type = type
			self.isPrimaryKey = isPrimaryKey
		}
		
		fileprivate var query: String {
			return name + " " + type.rawValue + (isPrimaryKey ? " PRIMARY KEY NOT NULL" : "")
		}
	}
}


extension String {
	
	fileprivate func sqlFormatted() -> String {
		var result = self
		
		// Playgrounds use this prefix followed by some numbers then "." THEN the object name. Remove prefix so tables will be named consistently across multiple executions
		if result.hasPrefix("__lldb_expr_") {
			let range = result.range(of: ".")!
			result.removeSubrange(result.startIndex...range.lowerBound)
		}
		
		// using String(reflecting: Model.self) returns "Model.type", so remove the ".type" if it's there
//		if result.hasSuffix(".type") {
//			var i = result.endIndex
//			result.formIndex(&i, offsetBy: -5)
//			result.removeSubrange(i...)
//		}
		
		// remove leading spaces
		while result.hasPrefix(" ") {
			result.removeFirst()
		}
		
		// remove trailing spaces
		while result.hasSuffix(" ") {
			result.removeLast()
		}
		
		// convert existing double quotes to single quotes, surround the whole thing with double quotes so SQLite will
		return "\"" + result.replacingOccurrences(of: "\"", with: "'") + "\""
		
	}
	
}
