//
//  Database+Delete.swift
//  CodableData
//
//  Created by Michael Arrington on 4/6/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	public func delete<T>(_ value: T) throws where T: Model & Encodable {
        var s = Statement("DELETE FROM \(Table.name(T.tableName)) WHERE id = ?")

        try s.prepare(in: connection.db)
        defer {
            s.finalize()
        }

        try value.id.bindingValue.bind(into: s, at: 1)
        s.step()
	}
}
