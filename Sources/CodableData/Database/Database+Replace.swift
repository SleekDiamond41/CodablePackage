//
//  Database+Replace.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	static func replace<T>(db: OpaquePointer, _ value: T) where T: Model & Encodable {
		let writer = Writer<T>()
		
		do {
			try writer.prepare(value)
			
			var table: Table! = Database.table(_ : db, named: T.tableName)
			
			if table == nil {
				let t = writer.tableDefinition()
				create(db: db, t)
				
				table = Database.table(db, named: T.tableName)
			}
			
			var a = table!
			
			try writer.replace(value, into: &table, db: db, newColumnsHandler: { columns in
				for c in columns {
					a = add(db, column: c, to: a)
				}
			})
			
		} catch {
			fatalError(String(reflecting: error))
		}
	}
	
	private static func replaceAndRead<T>(db: OpaquePointer, _ value: T) -> T where T: Model & Codable {
		let id = value.id
		replace(db: db, value)
		
		return Database.get(db, T.self, id: id)!
	}
	
}


//MARK: - Sync
extension Database {
	
	@discardableResult
	public func save<T>(_ value: T) -> T where T: Model & Codable {
		return sync { db in
			return Database.replaceAndRead(db: db, value)
		}
	}
	
}


//MARK: - Async
extension Database {
	
	public func save<T>(_ value: T, _ handler: @escaping () -> Void) where T: Model & Encodable {
		async { db in
			Database.replace(db: db, value)
			handler()
		}
	}
	
	public func save<T>(_ value: T, _ handler: @escaping (T) -> Void) where T: Model & Codable {
		async { db in
			handler(Database.replaceAndRead(db: db, value))
		}
	}
	
}
