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

	func table(_ name: String) throws -> Table? {
		var s = Statement("PRAGMA TABLE_INFO(\(Table.name(name)))")

        try s.prepare(in: connection.db)
        defer {
            s.finalize()
        }

        var columns = [Table.Column]()
        var status = s.step()

        while status == .row {

            columns.append(
                Table.Column(
                    name: try String.unbind(from: s, at: 1),
                    type: try ColumnType.unbind(from: s, at: 2),
                    isPrimaryKey: try Bool.unbind(from: s, at: 5))
            )
            status = s.step()
        }

        if columns.count > 0 {
            return Table(name: name, columns: columns)
        } else {
            return nil
        }
	}
}


//MARK: - Create
extension Database {
	
	func create(_ table: Table) {
        execute(table.query(for: .create))
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
