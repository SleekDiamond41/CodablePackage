//
//  Database+Replace.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	internal func _save(tableName: String, values: [(String, SQLValue)]) throws {
		let writer = Writer()
		
		var table: Table
		
		do {
			table = try self.table(tableName)
		} catch PreparationError.noSuchTable {
			let temp = Table(name: tableName, columns: values.map {
				Table.Column(name: $0, type: $1)
			})
            create(temp)

            table = try self.table(tableName)
		}
		
		try writer.replace(values, into: &table, connection: connection, newColumnsHandler: { t, columns in
            for c in columns {
                try add(column: c, to: &t)
            }
        })
	}

	public func save<T>(_ value: T) throws where T: Model & Codable {
		let values = try Writer.values(for: value)
		
		try _save(tableName: T.tableName, values: values)
	}
}
