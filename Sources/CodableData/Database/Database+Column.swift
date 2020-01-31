//
//  Database+Column.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	static func add(_ db: OpaquePointer, column: Table.Column, to table: Table) -> Table {
		let query = table.query(for: .addColumn(column))
		Database._execute(db: db, query)
		return Database.table(db, named: table.name.replacingOccurrences(of: "\"", with: ""))!
	}
	
}


//MARK: - Sync
extension Database {
	
	func add(column: Table.Column, to table: inout Table) {
		sync { (db) in
			table = Database.add(db, column: column, to: table)
		}
	}
	
}


//MARK: - Async
extension Database {
	
	func add(column: Table.Column, to table: Table, _ handler: @escaping (Table) -> Void) {
		async { (db) in
			handler(Database.add(db, column: column, to: table))
		}
	}
	
}
