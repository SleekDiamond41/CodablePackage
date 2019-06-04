//
//  Database+Read.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension CDDatabase {
	
	static func get<Model>(_ db: OpaquePointer, _ : Model.Type, query: String, bindings: [CDBindable]) -> [Model] where Model: Decodable & CDModel {
		guard let table = CDDatabase.table(_ : db, named: Model.tableName) else {
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
			
			var results = [Model]()
			var status = try s.step()
			
			let reader = Reader()
			
			while status == .row {
				results.append(try reader.read(Model.self, s: s, table))
				status = try s.step()
			}
			return results
			
		} catch {
			print(String(reflecting: error))
			return []
		}
	}
	
	
	static func get<Model, Key>(_ db: OpaquePointer, _ : Model.Type, id: Key) -> Model? where Model: CDModel & Decodable, Model.PrimaryKey == Key {
		return get(db, Model.self, query: "WHERE id = ? LIMIT 1 OFFSET 0", bindings: [id]).first
	}
	
	
	fileprivate static func get<Model>(_ db: OpaquePointer, _: Model.Type, limit: Int? = nil, page: Int = 1) -> [Model] where Model: Decodable & CDModel {
		var query = ""
		if let limit = limit {
			// make sure limit and page are positive so SQLite doesn't freak out
			let l = limit > 0 ? limit : 1
			let p = page > 0 ? page : 1
			
			query += "LIMIT \(l) OFFSET \((p-1) * l)"
		}
		return get(db, Model.self, query: query, bindings: [])
	}
	
	static func get<Model>(_ db: OpaquePointer, filter: CDFilter<Model>) -> [Model] where Model: CDModel & Decodable {
		return get(db, Model.self, query: filter.query, bindings: filter.bindings)
	}
	
}

	
//MARK: - Sync
extension CDDatabase {
	
	public func get<T, U>(_ : T.Type, id: U) -> T? where T: Decodable & CDModel, T.PrimaryKey == U {
		return sync { (db) in
			return CDDatabase.get(db, T.self, id: id)
		}
	}
	
	public func get<T>(_ : T.Type) -> [T] where T: Decodable & CDModel {
		return sync { db in
			return CDDatabase.get(db, T.self)
		}
	}
	
	public func get<T>(_ : T.Type, limit: Int, page: Int = 1) -> [T] where T: Decodable & CDModel {
		return sync { db in
			return CDDatabase.get(db, T.self, limit: limit, page: page)
		}
	}
	
	public func get<T>(with filter: CDFilter<T>) -> [T] where T: Decodable & CDModel {
		return sync { db in
			return CDDatabase.get(db, filter: filter)
		}
	}
	
	public func get<T>(sorting: CDSortRule<T>) -> [T] where T: Decodable & CDModel {
		return sync { db in
			return CDDatabase.get(db, filter: CDFilter(sorting))
		}
	}
	
}

	
//MARK: - Async
extension CDDatabase {
	
	public func get<T, U>(_ : T.Type, id: U, _ handler: @escaping (T?) -> Void) where T: Decodable & CDModel & CDFilterable, T.PrimaryKey == U {
		async { (db) in
			handler(CDDatabase.get(db, T.self, id: id))
		}
	}
	
	public func get<T>(_ : T.Type, _ handler: @escaping ([T]) -> Void) where T: Decodable & CDModel {
		async { (db) in
			handler(CDDatabase.get(db, T.self))
		}
	}
	
	public func get<T>(_ : T.Type, limit: Int, page: Int = 1, _ handler: @escaping ([T]) -> Void) where T: Decodable & CDModel {
		async { (db) in
			handler(CDDatabase.get(db, T.self, limit: limit, page: page))
		}
	}
	
	public func get<T>(with filter: CDFilter<T>, _ handler: @escaping ([T]) -> Void) where T: Decodable & CDModel {
		async { (db) in
			handler(CDDatabase.get(db, filter: filter))
		}
	}
	
	public func get<T>(sorting: CDSortRule<T>, _ handler: @escaping ([T]) -> Void) where T: Decodable & CDModel {
		async { (db) in
			handler(CDDatabase.get(db, filter: CDFilter(sorting)))
		}
	}
	
}
