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
		
		var s = Statement(.count(filter))
		
		guard try table(T.tableName) != nil else {
			return 0
		}
		
        try s.prepare(in: connection.db)
		
        defer {
            s.finalize()
        }
		
        var i: Int32 = 1
        for b in filter.bindings {
			try s.bind(b, at: i)
            i += 1
        }
		
        let status = s.step()
		
        guard status == .row else {
            print(String(reflecting: status))
            return 0
        }
		
		let proxy = Proxy(s, isNull: { _ in false })
		
        // returned table should have exactly one row, one column, value is count of items that matched the query
		return Int.unbind(proxy)
	}
}
