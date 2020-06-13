//
//  Database+Delete.swift
//  CodableData
//
//  Created by Michael Arrington on 4/6/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	public func delete<T>(_ value: T) throws where T: Model & Encodable & Filterable {
		let id = value[keyPath: T.idKey]
		let filter = Filter(T.idKey, is: .equal(to: id))
		
		try delete(with: filter)
	}
	
	public func delete<T>(with filter: Filter<T>) throws where T: Model {
		
		var s = Statement(.delete(filter))
		
        try s.prepare(in: connection.db)
		
        defer {
            s.finalize()
        }
		
		for (offset, value) in filter.bindings.enumerated() {
			try s.bind(value, at: Int32(offset) + 1)
		}
        
		let status = s.step()
		
		assert(status == .ok || status == .done)
	}
}
