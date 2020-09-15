//
//  Database+Delete.swift
//  CodableData
//
//  Created by Michael Arrington on 4/6/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	func _delete(_ table: String, query: String, bindings: [SQLValue]) throws {
		var s = Statement(.delete(table: table, query))
		
		do {
			try s.prepare(in: connection.db)
		} catch PreparationError.noSuchTable {
			// items are effectively deleted
			return
		}
		
        defer {
            s.finalize()
        }
		
		for (offset, value) in bindings.enumerated() {
			try s.bind(value, at: Int32(offset) + 1)
		}
        
		let status = s.step()
		
		assert(status == .done)
	}
	
	public func delete<T>(_ value: T) throws where T: Model & Encodable & Filterable {
		let id = value[keyPath: T.idKey]
		let filter = Filter(T.idKey, is: .equal(to: id))
		
		try delete(with: filter)
	}
	
	public func delete<T>(with filter: Filter<T>) throws where T: Model {
		
		try _delete(T.tableName, query: filter.query, bindings: filter.bindings)
	}
}
