//
//  Database+Table.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


//MARK: - Get Existing
extension Database {
	
	static func table(_ db: OpaquePointer, named name: String) -> Table? {
		var s = Statement("PRAGMA TABLE_INFO(\(Table.name(name)))")
		
		do {
			
			try s.prepare(in: db)
			defer {
				s.finalize()
			}
			
			var columns = [Table.Column]()
			var status = try s.step()
			
			while status == .row {
				
				columns.append(
					Table.Column(
						name: try String.unbind(from: s, at: 1),
						type: try ColumnType.unbind(from: s, at: 2),
						isPrimaryKey: try Bool.unbind(from: s, at: 5))
				)
				status = try s.step()
			}
			
			if columns.count > 0 {
				return Table(name: name, columns: columns)
			} else {
				return nil
			}
			
		} catch {
			fatalError(String(reflecting: error))
		}
	}
	
	func table(_ name: String) -> Table? {
		return sync {
			return Database.table($0, named: name)
		}
	}
	
	func table(_ name: String, _ handler: @escaping (Table?) -> Void) {
		async {
			handler(Database.table($0, named: name))
		}
	}
	
}


//MARK: - Create
extension Database {
	
	static func create(db: OpaquePointer, _ table: Table) {
		Database._execute(db: db, table.query(for: .create))
	}
	
	func create(_ table: Table) {
		sync { (db) in
			Database.create(db: db, table)
		}
	}
	
	func create(_ table: Table, _ handler: @escaping () -> Void) {
		async { (db) in
			Database.create(db: db, table)
			handler()
		}
	}
	
}


//MARK: - Drop
extension Database {
	
	static func dropTable(named name: String, db: OpaquePointer) {
		let t = Table(name: name, columns: [])
		_execute(db: db, t.query(for: .drop))
	}
	
	public func dropTable<T>(for _: T.Type) where T: Model {
		sync { (db) in
			Database.dropTable(named: T.tableName, db: db)
		}
	}
	
	public func dropTable<T>(for _: T.Type, _ handler: @escaping () -> Void) where T: Model {
		async { (db) in
			Database.dropTable(named: T.tableName, db: db)
			handler()
		}
	}
	
}
