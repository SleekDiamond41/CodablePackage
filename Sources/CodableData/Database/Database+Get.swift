//
//  Database+Read.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	func get<Element>(_ : Element.Type, query: String, bindings: [Bindable]) throws -> [Element] where Element: Decodable & Model {
        guard let table = try self.table(Element.tableName) else {
			return []
		}
		
		let q: String
		if query.count > 0 {
			q = " " + query
		} else {
			q = ""
		}
		
		var s = Statement("SELECT * FROM \(table.name)" + q + ";")

		try s.prepare(in: connection.db)
		defer {
			s.finalize()
		}
		
		var i: Int32 = 1
		for b in bindings {
			try b.bindingValue.bind(into: s, at: i)
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
	
	func get<Element>(filter: Filter<Element>) throws -> [Element] where Element: Model & Decodable {
		var copy = filter
		
		guard let t = try table(Element.tableName) else {
			return []
		}
		
		for _ in t.columns.indices {
			// better than a while true loop... right?
			
			do {
				return try get(Element.self, query: copy.query, bindings: copy.bindings)
				
			} catch let error as PreparationError {
				if !copy.usesColumns {
					// if we've queried until there was nothing left,
					// move on with your day
					break
				}
				
				switch error {
				case let .noSuchColumn(col):
					copy.remove(column: col)
				case let .syntax(message, query: query):
					preconditionFailure("\(message): \(query)")
				}
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

	public func get<T>(sorting: SortRule<T>) throws -> [T] where T: Decodable & Model {
        return try get(with: Filter(sorting))
	}
}
