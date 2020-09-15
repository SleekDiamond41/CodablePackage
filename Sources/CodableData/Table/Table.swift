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
		let name = self.name.sqlFormatted()
		
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
		self.name = name
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
			return name.sqlFormatted() + " " + type.rawValue + (isPrimaryKey ? " PRIMARY KEY NOT NULL" : "")
		}
	}
}


extension String {
	
	func sqlFormatted() -> String {
		var result = self
		
		#if targetEnvironment(simulator)
		// Playgrounds use this prefix followed by some numbers then "."
		// THEN the object name. I.e. "__lldb_expr_29.MyObject".
		//
		// Remove prefix so tables will be named consistently
		// across multiple executions of the Playground
		result = result.replacingOccurrences(of: #"__lldb_expr_\d*\."#, with: "", options: [.regularExpression])
		#endif
		
		// remove double quotes (") from the beginning and end of the table name
		// this step means that this method can be called on a string that is already
		// correctly formatted and still produce the same result
		result = result.trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
		
		// replace double quotes (") from the middle of the table name
		// this protects against SQL injection attacks
		result = result.replacingOccurrences(of: "\"", with: "'")
		
		// surround the whole thing with double quotes so SQLite will treat
		// this as just a String, even if it contains special characters
		return "\"" + result + "\""
	}
}
