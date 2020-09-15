//
//  Database+Table.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


//MARK: - Get Table
extension Database {

	func table(_ name: String) throws -> Table {
		var s = Statement("PRAGMA TABLE_INFO(\(Table.name(name)))")

        try s.prepare(in: connection.db)
        defer {
            s.finalize()
        }

		var proxy = Proxy(s, isNull: { _ in false })
        var columns = [Table.Column]()
        var status = s.step()

        while status == .row {
			
			proxy.index = 1
			let name: String = proxy.get()
			
			proxy.index = 2
			let type = ColumnType.unbind(proxy)
			
			proxy.index = 5
			let isPrimaryKey = Bool.unbind(proxy)

            columns.append(
                Table.Column(
                    name: name,
                    type: type,
                    isPrimaryKey: isPrimaryKey)
            )
            status = s.step()
        }
		
		guard !columns.isEmpty else {
			throw PreparationError.noSuchTable(name)
		}
		
		return Table(name: name, columns: columns)
	}
}


//MARK: - Create
extension Database {
	
	func create(_ table: Table) {
		let query = table.query(for: .create)
        let status = execute(query)
		
		guard status == .done else {
			preconditionFailure()
		}
	}
}


//MARK: - Drop
extension Database {
	
	public func dropTable<T>(for _: T.Type) where T: Model {
        // don't need to assign the columns since we're just dropping the table
        let t = Table(name: T.tableName, columns: [])
        execute(t.query(for: .drop))
	}
}
