//
//  Database+Delete.swift
//  CodableData
//
//  Created by Michael Arrington on 4/6/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension CDDatabase {
	private static func delete<T>(db: OpaquePointer, _ value: T) where T: CDModel & Encodable {
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

extension CDDatabase {
	public func delete<T>(_ value: T) where T: CDModel & Encodable {
		sync { (db) in
			CDDatabase.delete(db: db, value)
		}
	}
}

extension CDDatabase {
	public func delete<T>(_ value: T, _ handler: @escaping () -> Void) where T: CDModel & Encodable {
		async { (db) in
			CDDatabase.delete(db: db, value)
			handler()
		}
	}
}
