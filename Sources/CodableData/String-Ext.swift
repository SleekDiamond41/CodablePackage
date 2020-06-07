//
//  File.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import Foundation

extension String {
	
	static func get<T>(_ filter: Filter<T>) -> String where T: Model & Filterable {
		
		return "SELECT * FROM \(Table.name(T.tableName)) \(filter.query);"
	}
	
	static func save<T>(_ : T.Type, _ pairs: [(key: String, value: Bindable)]) -> String where T: Model {
		
		let keys = pairs
			.map { $0.key.sqlFormatted() }
			.joined(separator: ", ")
		
		let values = [String](repeating: "?", count: pairs.count)
			.joined(separator: ", ")
		
		return "REPLACE INTO \(Table.name(T.tableName)) (\(keys)) VALUES (\(values));"
	}
	
	static func delete<T>(_ filter: Filter<T>) -> String where T: Model & Filterable {
		
		return "DELETE FROM \(Table.name(T.tableName)) \(filter.query);"
	}
	
	static func count<T>(_ filter: Filter<T>) -> String where T: Model & Filterable {
		
		return "SELECT COUNT(*) FROM \(Table.name(T.tableName)) \(filter.query);"
	}
	
	static func distinct<T>(_ : T.Type, column: String, direction: SortRule<T>.Direction?) -> String where T: Model {
		let table = Table.name(T.tableName)
		let selection = "SELECT DISTINCT \(column) FROM \(table)"
		
		if let direction = direction {
			let sort = (direction == .ascending ? "ASC" : "DESC")
			
			return selection + " ORDER BY \(column) \(sort);"
		}
		
		return selection + ";"
	}
	
	static func distinctCount<T>(_ : T.Type, columns: [String]) -> String where T: Model {
		let paths = columns.joined(separator: ", ")
		let table = Table.name(T.tableName)
		
		return "SELECT COUNT(DISTINCT \(paths)) FROM \(table);"
	}
}
