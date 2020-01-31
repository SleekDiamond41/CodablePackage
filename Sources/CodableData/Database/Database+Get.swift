//
//  Database+Read.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	static func get<Element>(_ db: OpaquePointer, _ : Element.Type, query: String, bindings: [Bindable]) -> [Element] where Element: Decodable & Model {
		guard let table = Database.table(_ : db, named: Element.tableName) else {
			return []
		}
		
		let q: String
		if query.count > 0 {
			q = " " + query
		} else {
			q = ""
		}
		
		var s = Statement("SELECT * FROM \(table.name)" + q + ";")
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
			
			var results = [Element]()
			var status = try s.step()
			
			let reader = Reader()
			
			while status == .row {
				results.append(try reader.read(Element.self, s: s, table))
				status = try s.step()
			}
			return results
			
		} catch {
			print(String(reflecting: error))
			return []
		}
	}
	
	
	static func get<Element, Key>(_ db: OpaquePointer, _ : Element.Type, id: Key) -> Element? where Element: Model & Decodable, Element.PrimaryKey == Key {
		return get(db, Element.self, query: "WHERE id = ? LIMIT 1 OFFSET 0", bindings: [id]).first
	}
	
	
	fileprivate static func get<Element>(_ db: OpaquePointer, _: Element.Type, limit: Int? = nil, page: Int = 1) -> [Element] where Element: Decodable & Model {
		var query = ""
		if let limit = limit {
			// make sure limit and page are positive so SQLite doesn't freak out
			let l = limit > 0 ? limit : 1
			let p = page > 0 ? page : 1
			
			query += "LIMIT \(l) OFFSET \((p-1) * l)"
		}
		return get(db, Element.self, query: query, bindings: [])
	}
	
	static func get<Element>(_ db: OpaquePointer, filter: Filter<Element>) -> [Element] where Element: Model & Decodable {
		return get(db, Element.self, query: filter.query, bindings: filter.bindings)
	}
	
}

	
//MARK: - Sync
extension Database {
	
	public func get<T, U>(_ : T.Type, id: U) -> T? where T: Decodable & Model, T.PrimaryKey == U {
		return sync { (db) in
			return Database.get(db, T.self, id: id)
		}
	}
	
	public func get<T>(_ : T.Type) -> [T] where T: Decodable & Model {
		return sync { db in
			return Database.get(db, T.self)
		}
	}
	
	public func get<T>(_ : T.Type, limit: Int, page: Int = 1) -> [T] where T: Decodable & Model {
		return sync { db in
			return Database.get(db, T.self, limit: limit, page: page)
		}
	}
	
	public func get<T>(with filter: Filter<T>) -> [T] where T: Decodable & Model {
		return sync { db in
			return Database.get(db, filter: filter)
		}
	}
	
	public func get<T>(sorting: SortRule<T>) -> [T] where T: Decodable & Model {
		return sync { db in
			return Database.get(db, filter: Filter(sorting))
		}
	}
	
}

	
//MARK: - Async
extension Database {
	
	public func get<T, U>(_ : T.Type, id: U, _ handler: @escaping (T?) -> Void) where T: Decodable & Model & Filterable, T.PrimaryKey == U {
		async { (db) in
			handler(Database.get(db, T.self, id: id))
		}
	}
	
	public func get<T>(_ : T.Type, _ handler: @escaping ([T]) -> Void) where T: Decodable & Model {
		async { (db) in
			handler(Database.get(db, T.self))
		}
	}
	
	public func get<T>(_ : T.Type, limit: Int, page: Int = 1, _ handler: @escaping ([T]) -> Void) where T: Decodable & Model {
		async { (db) in
			handler(Database.get(db, T.self, limit: limit, page: page))
		}
	}
	
	public func get<T>(with filter: Filter<T>, _ handler: @escaping ([T]) -> Void) where T: Decodable & Model {
		async { (db) in
			handler(Database.get(db, filter: filter))
		}
	}
	
	public func get<T>(sorting: SortRule<T>, _ handler: @escaping ([T]) -> Void) where T: Decodable & Model {
		async { (db) in
			handler(Database.get(db, filter: Filter(sorting)))
		}
	}
	
}
