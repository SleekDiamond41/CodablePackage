//
//  Database+Delete.swift
//  CodableData
//
//  Created by Michael Arrington on 4/6/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	private static func delete<T>(db: OpaquePointer, _ value: T) where T: Model & Encodable {
		var s = Statement("DELETE FROM \(Table.name(T.tableName)) WHERE id = ?")
		
		do {
			try s.prepare(in: db)
			defer {
				s.finalize()
			}
			try value.id.bindingValue.bind(into: s, at: 1)
			try s.step()
			
		} catch {
			fatalError(String(reflecting: error))
		}
	}
}

extension Database {
	public func delete<T>(_ value: T) where T: Model & Encodable {
		sync { (db) in
			Database.delete(db: db, value)
		}
	}
}

extension Database {
	public func delete<T>(_ value: T, _ handler: @escaping () -> Void) where T: Model & Encodable {
		async { (db) in
			Database.delete(db: db, value)
			handler()
		}
	}
}
