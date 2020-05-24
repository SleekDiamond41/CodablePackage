//
//  Database+Column.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {

    enum TableError: Error {
        case failedToAdd(column: Table.Column, table: Table)
    }
	
	func add(column: Table.Column, to table: inout Table) throws {
        execute(table.query(for: .addColumn(column)))

        do {
            table = try self.table(table.name)!
        } catch {
            throw TableError.failedToAdd(column: column, table: table)
        }
	}
}
