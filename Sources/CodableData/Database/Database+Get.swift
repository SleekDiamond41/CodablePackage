//
//  Database+Read.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	/// Gets data models that match the given `filter`.
	/// - Parameter filter: a Filter that describes the elements to get
	/// - Throws: A whole host of stuff. 
	/// - Returns: <#description#>
	private func _get<Element>(filter: Filter<Element>) throws -> [Element] where Element: Decodable & Model {
        guard let table = try self.table(Element.tableName) else {
			return []
		}
		
		var s = Statement(.get(filter))
		
		try s.prepare(in: connection.db)
		
		defer {
			s.finalize()
		}
		
		var i: Int32 = 1
		for b in filter.bindings {
			try s.bind(b, at: i)
			i += 1
		}
		
		var results = [Element]()
		var status = s.step()
		
		let reader = Reader()
		
		while status == .row {
			results.append(try reader.read(Element.self, s: s, table))
			status = s.step()
		}
		
		return results
	}
	
	
	/// Get models from the database. If `filter` references a column that does not exist then the
	/// database will perform a query that removes references to that column.
	/// - Parameter filter: a Filter that describes the desired elements
	/// - Throws: <#description#>
	/// - Returns: an array of elements from the database that match the given query.
	private func get<Element>(filter: Filter<Element>) throws -> [Element] where Element: Model & Decodable {
		var copy = filter
		
		guard let t = try table(Element.tableName) else {
			return []
		}
		
		for _ in 0..<t.columns.count {
			//
			// better than a while true loop... right?
			
			do {
				return try _get(filter: copy)
			} catch PreparationError.noSuchColumn(let column) {
				guard copy.usesColumns else {
					break
				}
				copy.remove(column: column)
			}
		}
		return []
	}
}

	
//MARK: - Sync
extension Database {

    public func get<T>(with filter: Filter<T>) throws -> [T] where T: Decodable & Model {
        return try get(filter: filter)
    }
}
