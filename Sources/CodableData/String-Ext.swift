//
//  File.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import Foundation

extension String {
	
	static func get<T>(_ filter: Filter<T>) -> String where T: Model & Filterable {
		let query = filter.query
		var text = "SELECT * FROM \(Table.name(T.tableName))"
		
		if !query.isEmpty {
			text += " " + query
		}
		
		return text + ";"
	}
	
	static func save(_ tableName: String, _ pairs: [(key: String, value: SQLValue)]) -> String {
		
		let keys = pairs
			.map { $0.key.sqlFormatted() }
			.joined(separator: ", ")
		
		let values = [String](repeating: "?", count: pairs.count)
			.joined(separator: ", ")
		
		return "REPLACE INTO \(Table.name(tableName)) (\(keys)) VALUES (\(values));"
	}
	
	static func update(table: String, query: String, keys: [String]) -> String {
		let valuesText = keys
			.map { "\($0) = ?" }
			.joined(separator: ", ")
		
		var text = "UPDATE \(Table.name(table)) SET \(valuesText)"
		
		if !query.isEmpty {
			text += " " + query
		}
		
		return text + ";"
	}
	
	static func delete(table: String, _ filterQuery: String) -> String {
		var text = "DELETE FROM \(Table.name(table))"
		
		if !filterQuery.isEmpty {
			text += " " + filterQuery
		}
		
		return text + ";"
	}
	
	static func delete<T>(_ filter: Filter<T>) -> String where T: Model & Filterable {
		
		delete(table: T.tableName, filter.query)
	}
	
	static func count<T>(_ filter: Filter<T>) -> String where T: Model & Filterable {
		
		let clause = filter.query
		var text = "SELECT COUNT(*) FROM \(Table.name(T.tableName))"
		
		if !clause.isEmpty {
			text += " " + clause
		}
		
		return text + ";"
	}
	
	static func distinct<T>(_ filter: Filter<T>, column: String) -> String where T: Model {
		let table = Table.name(T.tableName)
		var selection = "SELECT DISTINCT \(column) FROM \(table)"
		let clause = filter.query
		
		if !clause.isEmpty {
			selection += " " + clause
		}
		
		return selection + ";"
	}
	
	static func distinctCount<T>(_ filter: Filter<T>, columns: [String]) -> String where T: Model {
		let paths = columns.joined(separator: ", ")
		let table = Table.name(T.tableName)
		let clause = filter.query
		
		var text = "SELECT COUNT(DISTINCT \(paths)) FROM \(table)"
		
		if !clause.isEmpty {
			text += " " + clause
		}
		
		return text + ";"
	}
}
