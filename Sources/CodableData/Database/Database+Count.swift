//
//  Database+Count.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


extension Database {
	
	public func count<T>(with filter: Filter<T>) throws -> Int where T: Decodable & Model {
        guard let table = try table(T.tableName) else {
            return 0
        }

        assert(!filter.query.hasSuffix(";"))
        var q = ""
        if filter.query.count > 0 {
            q += " " + filter.query
        }

		var s = Statement("SELECT COUNT(*) FROM \(table.name.sqlFormatted())" + q + ";")

        try s.prepare(in: connection.db)
        defer {
            s.finalize()
        }

        var i: Int32 = 1
        for b in filter.bindings {
            try b.bindingValue.bind(into: s, at: i)
            i += 1
        }

        let status = s.step()

        guard status == .row else {
            print(String(reflecting: status))
            return 0
        }

        // returned table should have exactly one row, one column, value is count of items that matched the query
        return try Int.unbind(from: s, at: 0)
	}
}
