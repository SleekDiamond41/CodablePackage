//
//  Database+Count.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


extension Database {
	
	static func count<Element>(_ db: OpaquePointer, _ : Element.Type, query: String, bindings: [Bindable]) -> Int where Element: Model {
		guard let table = Database.table(_ : db, named: Element.tableName) else {
			return 0
		}
		
		assert(!query.hasSuffix(";"))
		var q = ""
		if query.count > 0 {
			q += " " + query
		}
		
		var s = Statement("SELECT COUNT(*) FROM \(table.name)" + q + ";")
		do {
			try s.prepare(in: db)
			defer {
				s.finalize()
			}
			
			var i: Int32 = 1
			for b in bindings {
				try b.bindingValue.bind(into: s, at: i)
				i += 1
			}
			
			let status = try s.step()
			
			guard status == .row else {
				print(String(reflecting: status))
				return 0
			}
			
			// returned table should have exactly one row, one column, value is count of items that matched the query
			return try Int.unbind(from: s, at: 0)
			
		} catch {
			print(String(reflecting: error))
			return 0
		}
	}
	
	fileprivate static func count<Element>(_ db: OpaquePointer, _: Element.Type) -> Int where Element: Model & Decodable {
		return count(db, Element.self, query: "", bindings: [])
	}
	
	fileprivate static func count<Element>(_ db: OpaquePointer, filter: Filter<Element>) -> Int where Element: Model & Decodable {
		return count(db, Element.self, query: filter.query, bindings: filter.bindings)
	}
	
}


//MARK: - Sync
extension Database {
	
	public func count<T>(_ : T.Type) -> Int where T: Decodable & Model {
		return sync { db in
			return Database.count(db, T.self)
		}
	}
	
	public func count<T>(with filter: Filter<T>) -> Int where T: Decodable & Model {
		return sync { db in
			return Database.count(db, filter: filter)
		}
	}
	
}


//MARK: - Async
extension Database {
	
	public func count<T>(_ : T.Type, _ handler: @escaping (Int) -> Void) where T: Decodable & Model {
		async { db in
			handler(Database.count(db, T.self))
		}
	}
	
	public func count<T>(where filter: Filter<T>, _ handler: @escaping (Int) -> Void) where T: Decodable & Model {
		async { db in
			handler(Database.count(db, filter: filter))
		}
	}
	
}
