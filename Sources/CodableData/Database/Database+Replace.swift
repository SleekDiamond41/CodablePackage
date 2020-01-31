//
//  Database+Replace.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {

	public func save<T>(_ value: T) throws where T: Model & Codable {
        let writer = Writer<T>()

        try writer.prepare(value)

        var table: Table! = try self.table(T.tableName)

        if table == nil {
            let t = writer.tableDefinition()
            create(t)

            table = try self.table(T.tableName)
        }

        var a = table!

        try writer.replace(value, into: &table, connection: connection, newColumnsHandler: { columns in
            for c in columns {
                try add(column: c, to: &a)
            }
        })
	}
}
